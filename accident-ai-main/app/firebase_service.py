import firebase_admin
from firebase_admin import credentials, firestore
import os
import logging
from datetime import datetime, timezone, timedelta

logger = logging.getLogger(__name__)

CRED_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'secrets', 'serviceAccount.json'))

def parse_timestamp(ts_str: str) -> datetime:
    dt = datetime.strptime(ts_str, "%Y%m%d_%H%M%S")
    tz = timezone(timedelta(hours=7))
    return dt.replace(tzinfo=tz)

class FirestoreRepository:
    def __init__(self):
        cred = credentials.Certificate(CRED_PATH)
        if not firebase_admin._apps:
            firebase_admin.initialize_app(cred)
        self.db = firestore.client()

    def save_accident(self, timestamp: str, image_url: str, camera_id: str):
        parsed_timestamp = parse_timestamp(timestamp)

        data = {
            "timestamp": parsed_timestamp,   # stored as Firestore Timestamp
            "imageUrl": image_url,
            "cameraId": camera_id,
        }
        self.db.collection("accidents").document(timestamp).set(data)
        logger.info(f"Saved to Firebase: {data}")