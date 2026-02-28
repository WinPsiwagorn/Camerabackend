import os
import torch
from PIL import Image
from transformers import pipeline

MODEL_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'models'))
CONFIDENCE_THRESHOLD = 0.80

print("Loading detection model...")
device = 0 if torch.cuda.is_available() else -1
detector = pipeline(
    task="object-detection",
    model=MODEL_DIR,
    device=device
)
print("Model loaded successfully.")


def detect_accident(image_path: str) -> bool:
    try:
        image = Image.open(image_path).convert("RGB")
        results = detector(image, threshold=CONFIDENCE_THRESHOLD)
        for result in results:
            if result["label"] == "accident":
                return True
        return False
    except Exception as e:
        raise RuntimeError(f"Detection failed for {image_path}: {e}")