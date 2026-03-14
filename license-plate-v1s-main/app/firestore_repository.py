import firebase_admin
from firebase_admin import credentials, firestore
from typing import Dict
import os

class FirestoreRepository:
    def __init__(self):
        # Use service account from Docker volume mount
        cred_path = "/secrets/serviceAccount.json"
        cred = credentials.Certificate(cred_path)
        if not firebase_admin._apps:
            firebase_admin.initialize_app(cred)
        self.db = firestore.client()

    def save_license_plate(self, data: Dict):
        """
        Save detection result to 'licensePlates' collection.
        """
        self.db.collection('licensePlates').add(data)
