"""
Immich Poller - Background thread that polls Immich for new photos,
decodes barcodes, parses text, matches photos, and archives them.
Replaces n8n workflow functionality.
"""
import logging
import os
import threading
import time
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List

import requests

from db import get_db
from decoder import smart_decode
from llm_parser import parse_barcode_with_llm, format_patient_folder_name

logger = logging.getLogger(__name__)

IMMICH_URL = os.getenv("IMMICH_URL", "http://immich-server:2283")
IMMICH_API_KEY = os.getenv("IMMICH_API_KEY", "")
POLL_INTERVAL_SECONDS = int(os.getenv("POLL_INTERVAL_SECONDS", "120"))
MATCH_WINDOW_MINUTES = int(os.getenv("MATCH_WINDOW_MINUTES", "30"))
ARCHIVE_PATH = os.getenv("ARCHIVE_PATH", "/archive")
UNMATCHED_PATH = os.getenv("UNMATCHED_PATH", "/unmatched")


class ImmichPoller:
    """Background poller that watches Immich for new photos and processes them."""

    def __init__(self):
        self.db = get_db()
        self._thread: Optional[threading.Thread] = None
        self._running = False
        self.last_poll_time: Optional[datetime] = None
        self.photos_processed = 0
        self.photos_archived = 0
        self.last_error: Optional[str] = None

    @property
    def is_configured(self) -> bool:
        return bool(IMMICH_API_KEY)

    def _headers(self) -> Dict[str, str]:
        return {
            "x-api-key": IMMICH_API_KEY,
            "Accept": "application/json",
        }

    def start(self):
        """Start the background polling thread."""
        if not self.is_configured:
            logger.warning("Poller not started: IMMICH_API_KEY not set")
            return

        if self._running:
            logger.warning("Poller already running")
            return

        self._running = True
        self._thread = threading.Thread(target=self._poll_loop, daemon=True)
        self._thread.start()
        logger.info(f"Poller started (interval: {POLL_INTERVAL_SECONDS}s)")

    def stop(self):
        """Stop the background polling thread."""
        self._running = False
        if self._thread:
            self._thread.join(timeout=10)
            self._thread = None
        logger.info("Poller stopped")

    def get_status(self) -> Dict[str, Any]:
        """Get current poller status."""
        return {
            "running": self._running,
            "configured": self.is_configured,
            "poll_interval_seconds": POLL_INTERVAL_SECONDS,
            "last_poll_time": self.last_poll_time.isoformat() if self.last_poll_time else None,
            "photos_processed": self.photos_processed,
            "photos_archived": self.photos_archived,
            "last_error": self.last_error,
        }

    def _poll_loop(self):
        """Main polling loop — runs in background thread."""
        # Wait a bit for services to be ready
        time.sleep(10)
        logger.info("Poller loop starting...")

        while self._running:
            try:
                self.poll()
                self.last_error = None
            except Exception as e:
                self.last_error = str(e)
                logger.error(f"Poll error: {e}")

            # Sleep in small increments so we can stop quickly
            for _ in range(POLL_INTERVAL_SECONDS):
                if not self._running:
                    return
                time.sleep(1)

    def poll(self):
        """Single poll cycle: fetch new photos from Immich and process them."""
        last_checked = self.db.get_poll_timestamp()
        now = datetime.utcnow()

        logger.info(f"Polling Immich for photos since {last_checked or 'beginning'}...")

        # Search for photos taken after last check
        photos = self._fetch_new_photos(last_checked)

        if not photos:
            logger.info("No new photos found")
            self.db.set_poll_timestamp(now)
            self.last_poll_time = now
            return

        logger.info(f"Found {len(photos)} new photos to process")

        for photo in photos:
            try:
                self.process_photo(photo)
                self.photos_processed += 1
            except Exception as e:
                logger.error(f"Error processing photo {photo.get('id', '?')}: {e}")

        self.db.set_poll_timestamp(now)
        self.last_poll_time = now

    def _fetch_new_photos(self, since: Optional[datetime]) -> List[Dict]:
        """Fetch new photos from Immich API."""
        taken_after = since.isoformat() + "Z" if since else "2024-01-01T00:00:00Z"

        try:
            resp = requests.post(
                f"{IMMICH_URL}/api/search/metadata",
                headers=self._headers(),
                json={
                    "takenAfter": taken_after,
                    "page": 1,
                    "size": 100,
                },
                timeout=30,
            )
            resp.raise_for_status()
            data = resp.json()

            # Immich returns { assets: { items: [...] } }
            assets = data.get("assets", {}).get("items", [])
            return assets

        except requests.RequestException as e:
            logger.error(f"Immich API error: {e}")
            raise

    def _download_photo(self, asset_id: str) -> Optional[bytes]:
        """Download original photo bytes from Immich."""
        try:
            resp = requests.get(
                f"{IMMICH_URL}/api/assets/{asset_id}/original",
                headers=self._headers(),
                timeout=60,
            )
            resp.raise_for_status()
            return resp.content
        except requests.RequestException as e:
            logger.error(f"Failed to download photo {asset_id}: {e}")
            return None

    def process_photo(self, photo: Dict):
        """
        Process a single photo:
        1. Check if already in DB
        2. Download the image
        3. Try barcode decode
        4. If barcode found -> parse -> match -> archive
        5. If no barcode -> index as patient photo
        """
        asset_id = photo.get("id", "")
        taken_at_str = photo.get("fileCreatedAt") or photo.get("createdAt", "")

        # Skip if already processed
        existing = self.db.get_photo(asset_id)
        if existing:
            return

        logger.info(f"Processing photo {asset_id}...")

        # Download photo
        image_bytes = self._download_photo(asset_id)
        if not image_bytes:
            return

        # Try barcode/OCR decode
        decode_result = smart_decode(image_bytes)

        if decode_result.get("decoded_text"):
            # This is a barcode photo — parse and process
            self._handle_barcode_photo(asset_id, taken_at_str, decode_result)
        else:
            # This is a regular patient photo — index it
            self._handle_patient_photo(asset_id, taken_at_str)

    def _handle_barcode_photo(self, asset_id: str, taken_at_str: str, decode_result: Dict):
        """Handle a photo that contains a barcode."""
        logger.info(f"Barcode found in {asset_id}: {decode_result['decode_method']}")

        # Parse barcode text with LLM
        parsed = parse_barcode_with_llm(decode_result["decoded_text"])

        patient_name = parsed.get("patient_name")
        date_str = parsed.get("date")

        if not patient_name:
            logger.warning(f"Could not extract patient name from barcode in {asset_id}")
            return

        # Parse taken_at
        try:
            taken_at = datetime.fromisoformat(taken_at_str.replace("Z", "+00:00")).replace(tzinfo=None)
        except (ValueError, AttributeError):
            taken_at = datetime.utcnow()

        # Save barcode to DB
        self.db.add_photo(
            immich_id=asset_id,
            photo_type="barcode",
            taken_at=taken_at,
            patient_name=patient_name,
            doctor_name=parsed.get("doctor_name"),
            department=parsed.get("department"),
            organization_name=parsed.get("organization"),
            barcode_text=decode_result["decoded_text"],
        )

        # Find matching patient photos in time window
        matches = self.db.find_matching_photos(
            barcode_timestamp=taken_at,
            patient_name=patient_name,
            window_minutes=MATCH_WINDOW_MINUTES,
        )

        if matches:
            self._archive_matches(asset_id, patient_name, date_str or taken_at.strftime("%Y-%m-%d"), matches)
        else:
            logger.info(f"No matching photos found for {patient_name} yet")

    def _handle_patient_photo(self, asset_id: str, taken_at_str: str):
        """Handle a regular patient photo (no barcode)."""
        try:
            taken_at = datetime.fromisoformat(taken_at_str.replace("Z", "+00:00")).replace(tzinfo=None)
        except (ValueError, AttributeError):
            taken_at = datetime.utcnow()

        self.db.add_photo(
            immich_id=asset_id,
            photo_type="patient",
            taken_at=taken_at,
        )

        logger.info(f"Indexed patient photo {asset_id}")

        # Check if there are any unmatched barcodes that could match this photo
        self._try_retroactive_match(asset_id, taken_at)

    def _try_retroactive_match(self, photo_id: str, taken_at: datetime):
        """Check if any existing unmatched barcodes match this new photo."""
        unmatched_barcodes = self.db.find_unmatched_barcodes(older_than_minutes=0)

        for barcode in unmatched_barcodes:
            barcode_time_str = barcode.get("taken_at", "")
            try:
                barcode_time = datetime.fromisoformat(barcode_time_str)
            except (ValueError, TypeError):
                continue

            time_diff = abs((taken_at - barcode_time).total_seconds() / 60)
            if time_diff <= MATCH_WINDOW_MINUTES:
                patient_name = barcode.get("patient_name", "")
                if patient_name:
                    matches = self.db.find_matching_photos(
                        barcode_timestamp=barcode_time,
                        patient_name=patient_name,
                        window_minutes=MATCH_WINDOW_MINUTES,
                    )
                    if matches:
                        date_str = barcode_time.strftime("%Y-%m-%d")
                        self._archive_matches(barcode["immich_id"], patient_name, date_str, matches)

    def _archive_matches(self, barcode_id: str, patient_name: str, date_str: str, matches: List[Dict]):
        """Archive matched photos to the archive folder."""
        from pathlib import Path

        folder_name = format_patient_folder_name(patient_name)
        archive_folder = Path(ARCHIVE_PATH) / date_str / folder_name
        archive_folder.mkdir(parents=True, exist_ok=True)

        logger.info(f"Archiving {len(matches)} photos for {patient_name} to {archive_folder}")

        # Copy photos from Immich uploads to archive
        for match in matches:
            match_id = match["immich_id"]
            image_bytes = self._download_photo(match_id)
            if image_bytes:
                dest = archive_folder / f"{match_id}.jpg"
                dest.write_bytes(image_bytes)

                self.db.mark_archived(
                    immich_id=match_id,
                    archive_path=str(archive_folder),
                )

        # Mark barcode as archived too
        self.db.mark_archived(
            immich_id=barcode_id,
            archive_path=str(archive_folder),
        )

        self.photos_archived += len(matches)
        logger.info(f"Archived {len(matches)} photos + barcode for {patient_name}")


# Singleton
_poller: Optional[ImmichPoller] = None


def get_poller() -> ImmichPoller:
    global _poller
    if _poller is None:
        _poller = ImmichPoller()
    return _poller
