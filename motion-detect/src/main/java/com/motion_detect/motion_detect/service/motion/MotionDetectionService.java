package com.motion_detect.motion_detect.service.motion;

import com.motion_detect.motion_detect.config.FFmpegGrabberConfig;
import org.bytedeco.javacv.FFmpegFrameGrabber;
import com.motion_detect.motion_detect.model.entity.Camera;
import com.motion_detect.motion_detect.repository.CameraRepository;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.bytedeco.javacv.Frame;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class MotionDetectionService {

    private final CameraRepository cameraRepository;
    private final SaveMotionFrameService saveMotionFrameService;
    private final FFmpegGrabberConfig grabberConfig;

    // Track active detection sessions
    private final Map<String, DetectionSession> activeSessions = new ConcurrentHashMap<>();
    // Use FixedThreadPool (max 3 cameras) to prevent unbounded thread growth
    private final ExecutorService detectionExecutor = Executors.newFixedThreadPool(3, r -> {
        Thread t = new Thread(r);
        t.setName("motion-detect-" + t.getId());
        t.setDaemon(false); // Non-daemon so JVM waits for cleanup
        return t;
    });

    /**
     * Start motion detection for a camera
     */
    public void startDetection(String cameraId) {
        if (activeSessions.containsKey(cameraId)) {
            log.warn("Detection already running for camera {}", cameraId);
            return;
        }

        Camera camera;
        try {
            camera = cameraRepository.findById(cameraId)
                    .orElseThrow(() -> new IllegalArgumentException("Camera not found: " + cameraId));
        } catch (java.util.concurrent.ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Failed to fetch camera: " + cameraId, e);
        }

        String rtspUrl = camera.getRtspUrl();
        if (rtspUrl == null || rtspUrl.isEmpty()) {
            throw new IllegalArgumentException("Camera " + cameraId + " has no RTSP URL");
        }

        log.info("Starting motion detection for camera {}", cameraId);

        DetectionSession session = new DetectionSession(cameraId, rtspUrl);
        activeSessions.put(cameraId, session);

        detectionExecutor.submit(() -> runDetectionLoop(session));
    }

    /**
     * Stop motion detection for a camera
     */
    public void stopDetection(String cameraId) {
        DetectionSession session = activeSessions.remove(cameraId);
        if (session == null) {
            log.warn("No active detection session for camera {}", cameraId);
            return;
        }

        log.info("Stopping motion detection for camera {}", cameraId);
        session.stop();
    }

    /**
     * Check if detection is running for a camera
     */
    public boolean isDetectionActive(String cameraId) {
        return activeSessions.containsKey(cameraId);
    }

    /**
     * Gracefully shutdown all detection sessions (called on application shutdown)
     */
    @PreDestroy
    public void shutdownAll() {
        log.info("Shutting down motion detection service - stopping {} active sessions", activeSessions.size());
        
        // Stop all active sessions
        for (String cameraId : activeSessions.keySet()) {
            try {
                stopDetection(cameraId);
            } catch (Exception e) {
                log.error("Error stopping camera {}: {}", cameraId, e.getMessage());
            }
        }
        
        // Shutdown executor gracefully
        detectionExecutor.shutdown();
        try {
            if (!detectionExecutor.awaitTermination(30, TimeUnit.SECONDS)) {
                log.warn("Detection executor did not terminate gracefully, forcing shutdown");
                detectionExecutor.shutdownNow();
            }
        } catch (InterruptedException e) {
            log.error("Interrupted during shutdown");
            detectionExecutor.shutdownNow();
            Thread.currentThread().interrupt();
        }
        
        log.info("Motion detection service shutdown complete");
    }

    /**
     * Main detection loop - runs in background thread
     */
    private void runDetectionLoop(DetectionSession session) {
        FFmpegFrameGrabber grabber = null;
        MotionOrchestratorService orchestrator = null;

        try {
            // Phase 1: Initialize grabber with retry logic (same as HLS service)
            log.info("Initializing grabber for camera {}", session.getCameraId());
            grabber = grabberConfig.startGrabberWithRetry(session.getRtspUrl(), session.getCameraId());
            
            int width = grabber.getImageWidth();
            int height = grabber.getImageHeight();
            String format = grabber.getFormat();
            log.info("Connected to RTSP stream for camera {}: {}x{}, format: {}", 
                    session.getCameraId(), width, height, format);
            
            // Validate grabber is actually connected
            if (width <= 0 || height <= 0 || format == null) {
                throw new IllegalStateException("Grabber failed to connect properly - invalid dimensions or format");
            }

            // Phase 2: Initialize motion orchestrator
            orchestrator = new MotionOrchestratorService(saveMotionFrameService, session.getCameraId());
            orchestrator.initialize(width, height);
            log.info("Camera {} - Motion orchestrator initialized", session.getCameraId());

            // Phase 3: Flush stale buffer (same as HLS service)
            log.info("Camera {} - Flushing stale grabber buffer...", session.getCameraId());
            int flushed = 0;
            for (int i = 0; i < 50; i++) {
                if (!session.isRunning() || Thread.currentThread().isInterrupted())
                    break;
                Frame stale = grabber.grabImage();
                if (stale == null)
                    break;
                stale.close();
                flushed++;
            }
            log.info("Camera {} - Flushed {} stale frames", session.getCameraId(), flushed);

            // Phase 4: Process frames
            log.info("Camera {} - Starting frame processing loop", session.getCameraId());
            long frameCount = 0;
            long lastLogTime = System.currentTimeMillis();
            int consecutiveNullFrames = 0;
            final int MAX_CONSECUTIVE_NULLS = 50; // If 50 consecutive nulls, camera is offline
            
            while (session.isRunning() && !Thread.currentThread().isInterrupted()) {
                Frame frame = null;
                try {
                    frame = grabber.grabImage();
                    
                    // Check if frame is null or invalid
                    if (frame == null) {
                        consecutiveNullFrames++;
                        if (consecutiveNullFrames == 10) {
                            log.warn("Camera {} - Received 10 consecutive null frames, stream may be disconnected", 
                                    session.getCameraId());
                        } else if (consecutiveNullFrames >= MAX_CONSECUTIVE_NULLS) {
                            log.error("Camera {} - Received {} consecutive null frames, camera appears offline", 
                                    session.getCameraId(), consecutiveNullFrames);
                            break; // Exit loop, camera is offline
                        }
                        continue;
                    }
                    
                    if (frame.image == null) {
                        log.debug("Camera {} - Frame.image is NULL (buffer not ready)", session.getCameraId());
                        consecutiveNullFrames++;
                        continue;
                    }
                    
                    // Valid frame received - reset counter
                    consecutiveNullFrames = 0;

                    orchestrator.processFrame(frame, session.getCameraId());
                    frameCount++;
                } finally {
                    // CRITICAL: Close frame to prevent memory leak
                    if (frame != null) {
                        frame.close();
                    }
                }

                // Log progress every 30 seconds
                long now = System.currentTimeMillis();
                if (now - lastLogTime >= 30_000) {
                    log.info("Camera {} - Processed {} frames", session.getCameraId(), frameCount);
                    lastLogTime = now;
                }
            }

        } catch (InterruptedException e) {
            log.info("Detection loop interrupted for camera {}", session.getCameraId());
            Thread.currentThread().interrupt();
        } catch (Throwable e) {
            log.error("Error in detection loop for camera {}: {} - {}", session.getCameraId(), e.getClass().getName(), e.getMessage(), e);
        } finally {
            // Cleanup
            log.info("Camera {} - Starting cleanup", session.getCameraId());
            if (orchestrator != null) {
                try {
                    orchestrator.cleanup();
                    log.info("Camera {} - Orchestrator cleaned up", session.getCameraId());
                } catch (Exception e) {
                    log.error("Camera {} - Error cleaning up orchestrator: {}", session.getCameraId(), e.getMessage());
                }
            }
            if (grabber != null) {
                grabberConfig.safeClose(grabber);
                log.info("Camera {} - Grabber closed", session.getCameraId());
            }
            activeSessions.remove(session.getCameraId());
            log.info("Detection loop ended for camera {}", session.getCameraId());
        }
    }
}
