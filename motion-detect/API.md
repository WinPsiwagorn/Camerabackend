# Motion Detection Microservice - API Documentation

## Overview
Standalone microservice for real-time motion detection from RTSP camera streams. Directly connects to RTSP URLs, performs optimized motion detection, uploads frames to Firebase Storage, and publishes events to Kafka.

## Architecture
- **Direct RTSP Connection**: Uses FFmpegFrameGrabber to read camera streams
- **Optimized Detection**: Frame skipping (1/4 frames), downscaling (640px), pre-allocated Mats
- **Async Upload**: Non-blocking Firebase uploads via ExecutorService
- **Event Streaming**: Kafka events to `motion-event` topic after successful upload

## Prerequisites
- Java 17+
- Kafka running on localhost:9092
- Firebase service account file at `secrets/serviceAccount.json`
- Camera RTSP URLs stored in Firestore `cameras` collection

## API Endpoints

### 1. Start Motion Detection
**POST** `/api/detection/start`

Start motion detection for a specific camera.

**Request Body:**
```json
{
  "cameraId": "camera123",
  "checkIntervalSeconds": 5
}
```

**Response:**
```json
{
  "success": true,
  "message": "Motion detection started for camera camera123",
  "cameraId": "camera123"
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Camera not found: camera123",
  "cameraId": "camera123"
}
```

---

### 2. Stop Motion Detection
**POST** `/api/detection/stop/{cameraId}`

Stop motion detection for a specific camera.

**Path Parameter:**
- `cameraId` - ID of the camera

**Response:**
```json
{
  "success": true,
  "message": "Motion detection stopped for camera camera123",
  "cameraId": "camera123"
}
```

---

### 3. Get Detection Status
**GET** `/api/detection/status/{cameraId}`

Check if motion detection is currently active for a camera.

**Path Parameter:**
- `cameraId` - ID of the camera

**Response:**
```json
{
  "cameraId": "camera123",
  "active": true,
  "status": "running"
}
```

---

### 4. Health Check
**GET** `/api/detection/health`

Service health check endpoint.

**Response:**
```json
{
  "status": "UP",
  "service": "motion-detect"
}
```

---

## Kafka Event Schema

When motion is detected, an event is published to the `motion-event` topic:

```json
{
  "cameraId": "camera123",
  "timestamp": 1704067200000,
  "imageUrl": "https://storage.googleapis.com/centralcamera-7de28.firebasestorage.app/motion_frames/camera123/uuid.jpg",
  "metadata": {
    "source": "motion-detect-microservice",
    "imageSize": 245678
  }
}
```

**Topic**: `motion-event`  
**Partition Key**: `cameraId` (ensures events from same camera go to same partition)

---

## Configuration

Edit `src/main/resources/application.properties`:

```properties
# Server port
server.port=8081

# Firebase credentials and storage
firebase.credentials.path=secrets/serviceAccount.json
firebase.storage.bucket=centralcamera-7de28.firebasestorage.app

# Kafka broker
spring.kafka.bootstrap-servers=localhost:9092

# Logging levels
logging.level.com.motion_detect=DEBUG
```

---

## Running the Service

### Via Maven
```bash
mvn spring-boot:run
```

### Via JAR
```bash
mvn clean package
java -jar target/motion-detect-0.0.1-SNAPSHOT.jar
```

### Via Docker
```bash
docker build -t motion-detect .
docker run -p 8081:8081 -v $(pwd)/secrets:/app/secrets motion-detect
```

---

## Motion Detection Parameters

Configured in the service classes:

- **Frame Skip**: 3 (processes 1 out of every 4 frames)
- **Detection Resolution**: Max 640px width (maintains aspect ratio)
- **Motion Threshold**: 2% of pixels changed
- **Sharpness Threshold**: 50.0 (Laplacian variance)
- **Background Subtractor**: MOG2 with 500-frame history

---

## Performance Notes

- **CPU Usage**: ~15-25% per stream @ 640px detection resolution
- **Memory**: ~200MB base + ~50MB per active stream
- **Latency**: <50ms from motion detection to Kafka publish
- **Upload Time**: 100-500ms (async, non-blocking)

---

## Troubleshooting

### RTSP Connection Fails
- Verify camera RTSP URL is correct
- Check network connectivity to camera
- Ensure RTSP transport is TCP (configured automatically)

### High CPU Usage
- Increase `FRAME_SKIP` value in MotionOrchestratorService
- Reduce `DETECTION_MAX_WIDTH` in MotionDetector

### Missing Motion Events
- Check sharpness threshold (default 50.0)
- Verify motion threshold (default 2%)
- Review logs at DEBUG level

### Firebase Upload Errors
- Confirm `secrets/serviceAccount.json` exists
- Verify Firebase Storage rules allow writes
- Check bucket name matches configuration

---

## Development

### Project Structure
```
motion-detect/
├── src/main/java/com/motion_detect/motion_detect/
│   ├── config/
│   │   ├── FirebaseAdminBootstrap.java
│   │   └── KafkaProducerConfig.java
│   ├── controller/
│   │   └── MotionDetectionController.java
│   ├── dto/
│   │   ├── MotionEvent.java
│   │   └── StartDetectionRequest.java
│   ├── kafka/
│   │   └── MotionEventProducer.java
│   ├── model/entity/
│   │   └── Camera.java
│   ├── repository/
│   │   └── CameraRepository.java
│   ├── service/
│   │   ├── MotionDetectionService.java
│   │   └── motion/
│   │       ├── MotionDetector.java
│   │       ├── MotionOrchestratorService.java
│   │       └── SaveMotionFrameService.java
│   └── MotionDetectApplication.java
└── src/main/resources/
    └── application.properties
```

### Key Classes

- **MotionDetectionService**: Session manager, RTSP connections, detection lifecycle
- **MotionOrchestratorService**: Frame processing orchestration, async uploads
- **MotionDetector**: OpenCV motion detection (MOG2), sharpness calculation
- **SaveMotionFrameService**: Firebase upload, Kafka event publishing

---

## License

MIT License
