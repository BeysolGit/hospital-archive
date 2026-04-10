"""
SQLite database for photo indexing and time-window matching
"""
import sqlite3
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Optional, Dict, Any
import json

DB_PATH = Path("/app/data/hospital_archive.db")
DB_PATH.parent.mkdir(parents=True, exist_ok=True)


class PhotoDatabase:
    def __init__(self, db_path: str = str(DB_PATH)):
        self.db_path = db_path
        self.init_db()

    def init_db(self):
        """Initialize database schema"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            # Photos table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS photos (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    immich_id TEXT UNIQUE NOT NULL,
                    file_path TEXT,
                    photo_type TEXT NOT NULL,  -- 'barcode' or 'patient'
                    taken_at DATETIME NOT NULL,
                    patient_name TEXT,
                    doctor_name TEXT,
                    department TEXT,
                    hospital_name TEXT,
                    barcode_text TEXT,
                    archived INTEGER DEFAULT 0,
                    archive_path TEXT,
                    immich_album_id TEXT,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """)

            # Indexes for faster queries
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_taken_at ON photos(taken_at)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_patient_name ON photos(patient_name)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_photo_type ON photos(photo_type)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_immich_id ON photos(immich_id)")

            conn.commit()

    def add_photo(
        self,
        immich_id: str,
        photo_type: str,
        taken_at: datetime,
        file_path: Optional[str] = None,
        patient_name: Optional[str] = None,
        doctor_name: Optional[str] = None,
        department: Optional[str] = None,
        hospital_name: Optional[str] = None,
        barcode_text: Optional[str] = None,
    ) -> int:
        """Add or update a photo record"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT OR REPLACE INTO photos
                (immich_id, file_path, photo_type, taken_at, patient_name, doctor_name,
                 department, hospital_name, barcode_text, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            """, (
                immich_id,
                file_path,
                photo_type,
                taken_at.isoformat() if isinstance(taken_at, datetime) else taken_at,
                patient_name,
                doctor_name,
                department,
                hospital_name,
                barcode_text,
            ))
            conn.commit()
            return cursor.lastrowid

    def find_matching_photos(
        self,
        barcode_timestamp: datetime,
        patient_name: str,
        window_minutes: int = 30,
    ) -> List[Dict[str, Any]]:
        """
        Find photos matching a barcode within time window and patient name
        """
        start_time = barcode_timestamp - timedelta(minutes=window_minutes)
        end_time = barcode_timestamp + timedelta(minutes=window_minutes)

        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()

            # Normalize patient name for fuzzy matching
            cursor.execute("""
                SELECT
                    id, immich_id, file_path, taken_at, patient_name
                FROM photos
                WHERE photo_type = 'patient'
                  AND archived = 0
                  AND taken_at BETWEEN ? AND ?
                  AND patient_name LIKE ?
                ORDER BY ABS(strftime('%s', taken_at) - strftime('%s', ?))
            """, (
                start_time.isoformat(),
                end_time.isoformat(),
                f"%{patient_name}%",
                barcode_timestamp.isoformat(),
            ))

            results = [dict(row) for row in cursor.fetchall()]

        return results

    def mark_archived(self, immich_id: str, archive_path: str, album_id: Optional[str] = None):
        """Mark a photo as archived"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE photos
                SET archived = 1, archive_path = ?, immich_album_id = ?, updated_at = CURRENT_TIMESTAMP
                WHERE immich_id = ?
            """, (archive_path, album_id, immich_id))
            conn.commit()

    def find_unmatched_barcodes(self, older_than_minutes: int = 60) -> List[Dict[str, Any]]:
        """Find barcodes older than specified time with no matched photos"""
        cutoff_time = datetime.utcnow() - timedelta(minutes=older_than_minutes)

        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()

            # Barcodes that are not archived (no matches found)
            cursor.execute("""
                SELECT
                    id, immich_id, file_path, taken_at, patient_name, barcode_text
                FROM photos
                WHERE photo_type = 'barcode'
                  AND archived = 0
                  AND taken_at < ?
                ORDER BY taken_at DESC
            """, (cutoff_time.isoformat(),))

            results = [dict(row) for row in cursor.fetchall()]

        return results

    def get_photo(self, immich_id: str) -> Optional[Dict[str, Any]]:
        """Get a specific photo by Immich ID"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM photos WHERE immich_id = ?", (immich_id,))
            row = cursor.fetchone()
            return dict(row) if row else None

    def cleanup_unmatched(self, older_than_minutes: int = 60):
        """Move unmatched barcodes to archive/unmatched folder"""
        unmatched = self.find_unmatched_barcodes(older_than_minutes)
        return unmatched

    def get_stats(self) -> Dict[str, Any]:
        """Get database statistics"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            cursor.execute("SELECT COUNT(*) as total FROM photos")
            total = cursor.fetchone()[0]

            cursor.execute("SELECT COUNT(*) as barcodes FROM photos WHERE photo_type = 'barcode'")
            barcodes = cursor.fetchone()[0]

            cursor.execute("SELECT COUNT(*) as patients FROM photos WHERE photo_type = 'patient'")
            patients = cursor.fetchone()[0]

            cursor.execute("SELECT COUNT(*) as archived FROM photos WHERE archived = 1")
            archived = cursor.fetchone()[0]

        return {
            "total_photos": total,
            "barcodes": barcodes,
            "patient_photos": patients,
            "archived": archived,
            "unmatched": barcodes - archived,
        }


# Singleton instance
_db = None


def get_db() -> PhotoDatabase:
    global _db
    if _db is None:
        _db = PhotoDatabase()
    return _db
