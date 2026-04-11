"""
FastAPI service for fotograf archiving
- Barcode detection and decoding
- Photo indexing and matching
- Archive management
"""
import logging
import os
import io
from datetime import datetime
from pathlib import Path
from typing import Optional, List

from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
import requests
from PIL import Image
import piexif
import exifread

from db import get_db, PhotoDatabase
from decoder import smart_decode
from llm_parser import parse_barcode_with_llm, format_patient_folder_name, fuzzy_match_patient

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
ARCHIVE_PATH = Path(os.getenv("ARCHIVE_PATH", "/archive"))
UNMATCHED_PATH = Path(os.getenv("UNMATCHED_PATH", "/unmatched"))
MATCH_WINDOW_MINUTES = int(os.getenv("MATCH_WINDOW_MINUTES", "30"))

ARCHIVE_PATH.mkdir(parents=True, exist_ok=True)
UNMATCHED_PATH.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="Fotograf Arsivleme Servisi", version="1.0.0")
db: PhotoDatabase = get_db()


# ============================================================================
# Pydantic Models
# ============================================================================

class DecodeResponse(BaseModel):
    decoded_text: Optional[str] = None
    decode_method: Optional[str] = None  # "barcode" or "ocr"
    confidence: float = 0.0
    raw_text: Optional[str] = None
    error: Optional[str] = None


class ParsedBarcodeResponse(BaseModel):
    patient_name: Optional[str] = None
    doctor_name: Optional[str] = None
    date: Optional[str] = None
    time: Optional[str] = None
    department: Optional[str] = None
    organization: Optional[str] = None
    confidence: float = 0.0
    error: Optional[str] = None


class PhotoIndexRequest(BaseModel):
    immich_id: str
    taken_at: str  # ISO format datetime
    file_path: Optional[str] = None


class MatchRequest(BaseModel):
    timestamp: str  # ISO format
    patient_name: str
    window_minutes: Optional[int] = MATCH_WINDOW_MINUTES


class ArchiveRequest(BaseModel):
    barcode_immich_id: str
    patient_photos: List[str]  # List of immich IDs
    patient_name: str
    date: str  # YYYY-MM-DD


# ============================================================================
# Endpoints
# ============================================================================

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    stats = db.get_stats()
    return {
        "status": "healthy",
        "stats": stats,
    }


@app.post("/decode", response_model=DecodeResponse)
async def decode_image(file: UploadFile = File(...)):
    """
    Decode barcode or OCR from image
    - Tries machine-readable barcode first (zxing)
    - Falls back to OCR (EasyOCR)
    """
    try:
        contents = await file.read()

        # Run smart decode pipeline
        result = smart_decode(contents)

        return DecodeResponse(**result)

    except Exception as e:
        logger.error(f"Decode error: {e}")
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/parse", response_model=ParsedBarcodeResponse)
async def parse_barcode_text(file: UploadFile = File(...)):
    """
    Complete pipeline: decode → parse with LLM
    """
    try:
        contents = await file.read()

        # Stage 1: Decode (barcode or OCR)
        decode_result = smart_decode(contents)

        if not decode_result["decoded_text"]:
            return ParsedBarcodeResponse(error="Could not decode barcode or extract OCR text")

        # Stage 2: Parse with LLM
        parse_result = parse_barcode_with_llm(decode_result["decoded_text"])

        return ParsedBarcodeResponse(**parse_result)

    except Exception as e:
        logger.error(f"Parse error: {e}")
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/photo/index")
async def index_photo(request: PhotoIndexRequest):
    """
    Index a patient photo in the database
    Extract EXIF timestamp if available
    """
    try:
        taken_at = datetime.fromisoformat(request.taken_at)

        photo_id = db.add_photo(
            immich_id=request.immich_id,
            photo_type="patient",
            taken_at=taken_at,
            file_path=request.file_path,
        )

        logger.info(f"Indexed photo {request.immich_id} (ID: {photo_id})")

        return {
            "success": True,
            "photo_id": photo_id,
            "immich_id": request.immich_id,
        }

    except Exception as e:
        logger.error(f"Index error: {e}")
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/match")
async def find_matches(request: MatchRequest):
    """
    Find photos matching a barcode within time window
    """
    try:
        barcode_time = datetime.fromisoformat(request.timestamp)
        window = request.window_minutes or MATCH_WINDOW_MINUTES

        matches = db.find_matching_photos(
            barcode_timestamp=barcode_time,
            patient_name=request.patient_name,
            window_minutes=window,
        )

        # Convert datetime objects to ISO format strings for JSON
        for match in matches:
            if isinstance(match['taken_at'], str):
                match['taken_at'] = match['taken_at']
            else:
                match['taken_at'] = match['taken_at'].isoformat()

        logger.info(f"Found {len(matches)} matches for {request.patient_name}")

        return {
            "patient_name": request.patient_name,
            "barcode_timestamp": barcode_time.isoformat(),
            "window_minutes": window,
            "matches": matches,
            "count": len(matches),
        }

    except Exception as e:
        logger.error(f"Match error: {e}")
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/archive")
async def archive_photos(request: ArchiveRequest):
    """
    Archive matched photos:
    - Move files to Archive/YYYY-MM-DD/Patient_Name/
    - Mark as archived in database
    - Return Immich album ID for frontend
    """
    try:
        # Create archive folder structure
        archive_folder = ARCHIVE_PATH / request.date / format_patient_folder_name(request.patient_name)
        archive_folder.mkdir(parents=True, exist_ok=True)

        logger.info(f"Archiving to {archive_folder}")

        archived_files = []

        # Mark all photos as archived
        for immich_id in request.patient_photos:
            db.mark_archived(
                immich_id=immich_id,
                archive_path=str(archive_folder),
                album_id=None,  # Set by n8n after creating Immich album
            )
            archived_files.append(immich_id)

        # Mark barcode itself as archived
        db.mark_archived(
            immich_id=request.barcode_immich_id,
            archive_path=str(archive_folder),
        )

        logger.info(f"Archived {len(archived_files)} photos + barcode for {request.patient_name}")

        return {
            "success": True,
            "patient_name": request.patient_name,
            "date": request.date,
            "archive_path": str(archive_folder),
            "archived_photos": archived_files,
            "total_archived": len(archived_files) + 1,  # +1 for barcode
        }

    except Exception as e:
        logger.error(f"Archive error: {e}")
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/stats")
async def get_stats():
    """Get database statistics"""
    stats = db.get_stats()
    return {
        "database": "fotograf_arsivleme",
        "stats": stats,
    }


@app.get("/cleanup")
async def get_unmatched():
    """
    Get list of unmatched barcodes (older than 1 hour)
    Used by cleanup workflow
    """
    unmatched = db.find_unmatched_barcodes(older_than_minutes=60)

    return {
        "count": len(unmatched),
        "unmatched": unmatched,
    }


# ============================================================================
# Startup
# ============================================================================

@app.on_event("startup")
async def startup():
    logger.info("Fotograf Arsivleme Servisi starting...")
    logger.info(f"Archive path: {ARCHIVE_PATH}")
    logger.info(f"Unmatched path: {UNMATCHED_PATH}")
    logger.info(f"Match window: {MATCH_WINDOW_MINUTES} minutes")
    stats = db.get_stats()
    logger.info(f"Database stats: {stats}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)
