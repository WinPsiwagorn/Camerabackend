import firebase_admin
from firebase_admin import credentials, firestore
import os
import logging

logger = logging.getLogger(__name__)

# Resolves to accident-ai-main/secrets/serviceAccount.json
CRED_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'secrets', 'serviceAccount.json'))

class FirestoreRepository:
    def __init__(self):
        cred = credentials.Certificate(CRED_PATH)
        if not firebase_admin._apps:
            firebase_admin.initialize_app(cred)
        self.db = firestore.client()

    def save_accident(self, timestamp: str, image_url: str, camera_id: str):
        data = {
            "timestamp": timestamp,
            "imageUrl": image_url,
            "cameraId": camera_id,
        }
        self.db.collection("accident").document(timestamp).set(data)
        logger.info(f"Saved to Firebase: {data}")