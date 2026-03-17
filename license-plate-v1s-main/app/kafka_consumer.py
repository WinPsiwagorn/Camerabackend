import asyncio
import json
import logging
import os
from aiokafka import AIOKafkaConsumer
import firebase_admin
from firebase_admin import credentials, storage
from config import settings

logger = logging.getLogger(__name__)

# Initialize Firebase Admin SDK
SERVICE_ACCOUNT_PATH = "/secrets/serviceAccount.json"
if not firebase_admin._apps:
    cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
    firebase_admin.initialize_app(cred, {
        'storageBucket': 'centralcamera-7de28.firebasestorage.app'
    })
    logger.info("Firebase Admin SDK initialized with Storage bucket")


async def consume(detector):
    """
    Simplified Kafka consumer to process image detection tasks.
    Expected message format (JSON):
    {"imageUrl": "http://example.com/image.jpg", "use_ocr": true}
    """
    consumer = AIOKafkaConsumer(
        settings.KAFKA_TOPIC,
        bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
        group_id=settings.KAFKA_GROUP_ID,
        auto_offset_reset=settings.KAFKA_AUTO_OFFSET_RESET,
        enable_auto_commit=True,
        value_deserializer=lambda v: json.loads(v.decode('utf-8'))
    )

    try:
        await consumer.start()
    except Exception as e:
        logger.error(f"Unable to connect to Kafka: {e}")
        return

    try:
        async for msg in consumer:
            payload = msg.value
            image_url = payload.get("imageUrl")
            use_ocr = payload.get("use_ocr", True)
            kafka_timestamp = payload.get("timestamp")  # รับ timestamp จาก Kafka
            camera_name = payload.get("cameraName")  # รับ cameraName จาก Kafka
            camera_id = payload.get("cameraId")  # รับ cameraId จาก Kafka

            if image_url:
                temp_image_path = None
                try:
                    temp_image_path = f"{settings.OUTPUT_IMAGE_DIR}/temp_image.jpg"
                    
                    # Extract blob path from Firebase Storage URL
                    if "storage.googleapis.com" in image_url:
                        parts = image_url.split("/")
                        blob_path = "/".join(parts[4:])  # motion/cameraId/timestamp.jpg
                        
                        # Download from Firebase Storage with authentication
                        bucket = storage.bucket()
                        blob = bucket.blob(blob_path)
                        await asyncio.to_thread(blob.download_to_filename, temp_image_path)
                        logger.debug(f"Downloaded from Firebase Storage: {blob_path}")
                    else:
                        logger.warning(f"Unknown storage URL format: {image_url}")
                        continue

                    # Perform detection on the downloaded image
                    result = await asyncio.to_thread(
                        detector.detect,
                        image_path=temp_image_path,
                        save_image=True,
                        save_json=True,
                        use_ocr=use_ocr,
                        kafka_timestamp=kafka_timestamp,
                        image_url=image_url,
                        camera_name=camera_name,
                        camera_id=camera_id
                    )
                    logger.info(f"Detection finished for {image_url}: {result.get('total_plates')} plates detected.")
                    logger.info(f"      Saved: {result.get('output_image_path')}")
                    logger.info(f"      JSON: {result.get('output_json_path')}")
                    
                except Exception as e:
                    logger.error(f"Error during detection for {image_url}: {e}")
                finally:
                    # 🗑️ Always clean up the temp file after detection
                    if temp_image_path and os.path.exists(temp_image_path):
                        try:
                            os.remove(temp_image_path)
                            logger.debug(f"Deleted temp file: {temp_image_path}")
                        except Exception as e:
                            logger.warning(f"Could not delete temp file: {e}")
            else:
                logger.warning(f"Skipping message without imageUrl: {payload}")
            
    finally:
        await consumer.stop()
