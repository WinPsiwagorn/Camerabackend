import asyncio
import json
import logging
import os
import datetime

from aiokafka import AIOKafkaConsumer
import firebase_admin
from firebase_admin import credentials, storage

from config import settings
from detect import detect_accident
from firebase_service import FirestoreRepository

logger = logging.getLogger(__name__)

OUTPUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'output'))
RETRY_INTERVAL_SECONDS = 5

# Initialize Firebase Admin SDK with Storage bucket
SERVICE_ACCOUNT_PATH = "/secrets/serviceAccount.json"
if not firebase_admin._apps:
    cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
    firebase_admin.initialize_app(cred, {
        'storageBucket': settings.FIREBASE_STORAGE_BUCKET
    })
    logger.info("Firebase Admin SDK initialized with Storage bucket")

def parse_timestamp(raw) -> str:
    if isinstance(raw, int):
        # Unix milliseconds from Kafka
        return datetime.datetime.fromtimestamp(raw / 1000).strftime("%Y%m%d_%H%M%S")
    elif isinstance(raw, str) and raw:
        return raw
    else:
        return datetime.datetime.now().strftime("%Y%m%d_%H%M%S")


async def consume():
    repo = FirestoreRepository()
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    while True:
        consumer = AIOKafkaConsumer(
            settings.KAFKA_TOPIC,
            bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
            group_id=settings.KAFKA_GROUP_ID,
            auto_offset_reset=settings.KAFKA_AUTO_OFFSET_RESET,
            enable_auto_commit=True,
            value_deserializer=lambda v: json.loads(v.decode("utf-8")),
        )

        try:
            await consumer.start()
            logger.info("Kafka consumer started successfully.")
        except Exception as e:
            logger.error(f"Failed to connect to Kafka: {e}")
            logger.info(f"Retrying in {RETRY_INTERVAL_SECONDS} seconds... (Ctrl+C to stop)")
            await asyncio.sleep(RETRY_INTERVAL_SECONDS)
            continue

        try:
            async for msg in consumer:
                payload = msg.value
                image_url = payload.get("imageUrl")
                camera_id = payload.get("cameraId")
                timestamp = parse_timestamp(payload.get("timestamp"))

                if not image_url:
                    logger.warning(f"Skipping message without imageUrl: {payload}")
                    continue

                logger.info(f"Processing image from camera [{camera_id}]: {image_url}")
                temp_image_path = None

                try:
                    temp_image_path = os.path.join(OUTPUT_DIR, f"temp_{timestamp}.jpg")
                    # Extract blob path from Firebase Storage URL
                    # URL format: https://storage.googleapis.com/bucket-name/motion/cameraId/timestamp.jpg
                    if "storage.googleapis.com" in image_url:
                        # Extract path after bucket name
                        parts = image_url.split("/")
                        # Find index after bucket name (skip https://storage.googleapis.com/bucket-name/)
                        blob_path = "/".join(parts[4:])  # motion/cameraId/timestamp.jpg
                        
                        # Download from Firebase Storage with authentication (non-blocking)
                        bucket = storage.bucket()
                        blob = bucket.blob(blob_path)
                        await asyncio.to_thread(blob.download_to_filename, temp_image_path)
                        logger.debug(f"Downloaded from Firebase Storage: {blob_path}")
                    else:
                        logger.warning(f"Unknown storage URL format: {image_url}")
                        continue

                    # Run detection (also CPU-intensive, run in thread pool)
                    accident_found = await asyncio.to_thread(detect_accident, temp_image_path)

                    if accident_found:
                        repo.save_accident(timestamp, image_url, camera_id)
                        logger.info(f"Accident saved — timestamp: {timestamp}, camera: {camera_id}")
                    else:
                        logger.info(f"No accident detected — camera: {camera_id}")

                except Exception as e:
                    logger.error(f"Error processing message from camera [{camera_id}]: {e}")

                finally:
                    if os.path.exists(temp_image_path):
                        try:
                            os.remove(temp_image_path)
                            logger.debug(f"Deleted temp file: {temp_image_path}")
                        except Exception as e:
                            logger.warning(f"Could not delete temp file: {e}")

        except Exception as e:
            logger.error(f"Kafka connection lost: {e}")
            logger.info(f"Retrying in {RETRY_INTERVAL_SECONDS} seconds...")

        finally:
            await consumer.stop()
            logger.info("Kafka consumer stopped.")

        await asyncio.sleep(RETRY_INTERVAL_SECONDS)


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
    )
    asyncio.run(consume())