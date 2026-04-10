"""
Two-stage barcode/QR decode + OCR fallback pipeline
"""
import logging
from typing import Optional, Dict, Any
import io

import cv2
import numpy as np
from PIL import Image
import zxing
import easyocr

logger = logging.getLogger(__name__)

# Initialize EasyOCR reader (cached after first use)
_ocr_reader = None


def get_ocr_reader():
    """Get or initialize the EasyOCR reader"""
    global _ocr_reader
    if _ocr_reader is None:
        logger.info("Initializing EasyOCR reader with Turkish language...")
        _ocr_reader = easyocr.Reader(['tr', 'en'], gpu=False)
    return _ocr_reader


def preprocess_for_barcode(image_bytes: bytes) -> np.ndarray:
    """
    Preprocess image for barcode decode:
    - Convert to grayscale
    - Apply adaptive threshold
    - Deskew if needed
    """
    # Load image
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if img is None:
        raise ValueError("Failed to decode image")

    # Convert to grayscale
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # Apply adaptive threshold to enhance barcode
    binary = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY, 11, 2
    )

    return binary


def decode_barcode(image_bytes: bytes) -> Optional[str]:
    """
    Try to decode barcode from image using zxing-cpp
    Returns decoded barcode text or None if not found
    """
    try:
        # Preprocess
        preprocessed = preprocess_for_barcode(image_bytes)

        # Try with zxing-cpp
        reader = zxing.BarcodeCppReader()
        result = reader.decode(preprocessed)

        if result and result.valid:
            logger.info(f"Barcode decoded: {result.text} ({result.format})")
            return result.text

        return None

    except Exception as e:
        logger.warning(f"Barcode decode failed: {e}")
        return None


def ocr_text_from_image(image_bytes: bytes) -> Optional[str]:
    """
    Use EasyOCR to extract text from image
    Useful when barcode is not machine-readable (printed label instead)
    """
    try:
        # Load image
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if img is None:
            raise ValueError("Failed to decode image")

        # Run OCR
        reader = get_ocr_reader()
        results = reader.readtext(img, detail=0)  # detail=0 returns just text

        if results:
            extracted_text = "\n".join(results)
            logger.info(f"OCR extracted {len(results)} text regions")
            return extracted_text

        return None

    except Exception as e:
        logger.error(f"OCR failed: {e}")
        return None


def smart_decode(image_bytes: bytes) -> Dict[str, Any]:
    """
    Two-stage pipeline:
    1. Try machine-readable barcode (zxing-cpp)
    2. Fall back to OCR if barcode fails

    Returns:
    {
        "decoded_text": str or None,
        "decode_method": "barcode" | "ocr" | None,
        "confidence": float (0-1),
        "raw_text": str (OCR output if used),
    }
    """
    result = {
        "decoded_text": None,
        "decode_method": None,
        "confidence": 0.0,
        "raw_text": None,
    }

    # Stage 1: Try barcode decode
    barcode_text = decode_barcode(image_bytes)
    if barcode_text:
        result["decoded_text"] = barcode_text
        result["decode_method"] = "barcode"
        result["confidence"] = 0.95  # High confidence for machine-readable barcodes
        return result

    logger.info("Barcode decode failed, falling back to OCR...")

    # Stage 2: Fall back to OCR
    ocr_text = ocr_text_from_image(image_bytes)
    if ocr_text:
        result["decoded_text"] = ocr_text
        result["decode_method"] = "ocr"
        result["confidence"] = 0.75  # Lower confidence for OCR
        result["raw_text"] = ocr_text
        return result

    logger.warning("Both barcode decode and OCR failed")
    return result
