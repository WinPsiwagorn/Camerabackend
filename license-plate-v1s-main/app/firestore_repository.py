import firebase_admin
from firebase_admin import credentials, firestore
from typing import Dict
import os
import logging
from datetime import datetime
from config import settings

logger = logging.getLogger(__name__)

# Firebase credentials path
CRED_PATH = "/secrets/serviceAccount.json"


def parse_timestamp(timestamp_str: str) -> datetime:
    """
    Parse ISO format timestamp string to datetime object
    Handles formats like: "2026-03-14T12:34:56+07:00"
    """
    try:
        # Handle ISO format with timezone
        if "+" in timestamp_str or timestamp_str.endswith("Z"):
            return datetime.fromisoformat(timestamp_str.replace("Z", "+00:00"))
        return datetime.fromisoformat(timestamp_str)
    except Exception as e:
        logger.warning(f"Failed to parse timestamp '{timestamp_str}': {e}, using current time")
        return datetime.now()


class FirestoreRepository:
    def __init__(self):
        # Use service account from Docker volume mount
        if not firebase_admin._apps:
            cred = credentials.Certificate(CRED_PATH)
            firebase_admin.initialize_app(cred, {
                'storageBucket': settings.FIREBASE_STORAGE_BUCKET if hasattr(settings, 'FIREBASE_STORAGE_BUCKET') else 'centralcamera-7de28.firebasestorage.app'
            })
            logger.info("🔥 Firebase Admin SDK initialized in FirestoreRepository")
        self.db = firestore.client()

    def save_license_plate(self, data: Dict):
        """
        Save detection result to 'licensePlates' collection.
        Document structure:
        {
            "timestamp": Firestore.Timestamp,
            "imageUrl": str,
            "cameraName": str,
            "kafka_timestamp": Firestore.Timestamp (optional),
            "licensePlate": {
                "fullPlate": str,
                "text": str,
                "number": str,
                "province": str
            }
        }
        """
        try:
            # Extract fields
            timestamp_str = data.get("timestamp", "")
            image_url = data.get("imageUrl", "")
            camera_name = data.get("cameraName", "")
            kafka_timestamp_str = data.get("kafka_timestamp", "")
            license_plate = data.get("licensePlate", {})
            
            # Parse timestamps to Firestore Timestamp
            parsed_timestamp = parse_timestamp(timestamp_str)
            
            # Build Firestore document
            firestore_doc = {
                "timestamp": parsed_timestamp,
                "imageUrl": image_url,
                "cameraName": camera_name,
                "licensePlate": license_plate
            }
            
            # Add kafka_timestamp if available
            if kafka_timestamp_str:
                parsed_kafka_timestamp = parse_timestamp(kafka_timestamp_str)
                firestore_doc["kafka_timestamp"] = parsed_kafka_timestamp
            
            # Use document ID in format YYYYMMDD_HHMMSS (same as accident)
            # Extract from ISO timestamp: "2026-03-05T00:37:40+07:00" -> "20260305_003740"
            dt = parsed_timestamp
            doc_id = dt.strftime("%Y%m%d_%H%M%S")
            
            # Save to Firestore
            self.db.collection("licensePlates").document(doc_id).set(firestore_doc)
            
            logger.info(f"✅ Saved to Firebase licensePlates/{doc_id}: {license_plate.get('fullPlate', 'N/A')} | {license_plate.get('province', 'N/A')}")
            
        except Exception as e:
            logger.error(f"❌ Failed to save license plate to Firestore: {e}", exc_info=True)
