
package com.motion_detect.motion_detect.service.motion;

import com.motion_detect.motion_detect.model.entity.Camera;
import com.motion_detect.motion_detect.repository.CameraRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Set;
import java.util.concurrent.ExecutionException;

/**
 * Auto-starts motion detection for the first 3 active cameras from Firebase.
 * Runs after the application is fully initialized to prevent startup issues.
 * 
 * Resource Management:
 * - Limits camera count to 3 to prevent CPU/memory overflow
 * - Uses ApplicationReadyEvent to ensure Firebase is initialized
 * - Gracefully handles failures without crashing the application
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AutoStartMotionDetectionService {

    private final CameraRepository cameraRepository;
    private final MotionDetectionService motionDetectionService;

    // Limit to 2 cameras to prevent resource exhaustion
    private static final int MAX_CAMERAS = 2;
    
    // Camera IDs to skip (blacklist)
    private static final Set<String> BLOCKED_CAMERA_IDS = Set.of(
        "s2nHfc8xtvrXPmIaLoYN3",
        "6zPF3zqxrpIYnV2Xgxph",
        "kYXGuURA9fnOpggMugyY",
        "u6NVd7Nt5bdUalWPoZpI",
        "CGBuqkY8DoeVXzRKlEZV"
    );

    /**
     * Automatically start motion detection when the application is ready.
     * This runs AFTER all beans are initialized and Firebase is connected.
     */
    @EventListener(ApplicationReadyEvent.class)
    public void autoStartMotionDetection() {
        log.info("=== Auto-starting motion detection for up to {} cameras ===", MAX_CAMERAS);
        
        try {
            // Fetch all cameras from Firebase
            List<Camera> allCameras = cameraRepository.getAllCameras();
            
            if (allCameras == null || allCameras.isEmpty()) {
                log.warn("No cameras found in Firebase. Motion detection will not start.");
                return;
            }

            log.info("Found {} camera(s) in Firebase", allCameras.size());

            // Start detection for the first MAX_CAMERAS cameras only
            int startedCount = 0;
            for (Camera camera : allCameras) {
                if (startedCount >= MAX_CAMERAS) {
                    log.info("Reached maximum camera limit ({}). Skipping remaining cameras.", MAX_CAMERAS);
                    break;
                }

                if (camera.getId() == null || camera.getId().isEmpty()) {
                    log.warn("Skipping camera with null/empty ID");
                    continue;
                }
                
                // Skip blocked cameras
                if (BLOCKED_CAMERA_IDS.contains(camera.getId())) {
                    log.info("Skipping blocked camera: {} ({})", camera.getId(), 
                            camera.getName() != null ? camera.getName() : "unnamed");
                    continue;
                }

                if (camera.getRtspUrl() == null || camera.getRtspUrl().isEmpty()) {
                    log.warn("Skipping camera {} - no RTSP URL configured", camera.getId());
                    continue;
                }

                // Check if camera is already running (restart safety)
                if (motionDetectionService.isDetectionActive(camera.getId())) {
                    log.warn("Camera {} already has active detection, skipping", camera.getId());
                    continue;
                }

                try {
                    log.info("Starting motion detection for camera: {} ({})", camera.getId(), 
                            camera.getName() != null ? camera.getName() : "unnamed");
                    motionDetectionService.startDetection(camera.getId());
                    startedCount++;
                    log.info("✓ Successfully started motion detection for camera {}", camera.getId());
                    
                    // Small delay to prevent thundering herd on RTSP sources
                    Thread.sleep(2000);
                    
                } catch (Exception e) {
                    log.error("Failed to start motion detection for camera {}: {}", 
                            camera.getId(), e.getMessage(), e);
                    // Continue with next camera instead of failing entirely
                }
            }

            log.info("=== Auto-start complete: {} / {} camera(s) running ===", 
                    startedCount, Math.min(allCameras.size(), MAX_CAMERAS));

        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            log.error("Failed to fetch cameras from Firebase: {}", e.getMessage(), e);
        } catch (Exception e) {
            log.error("Unexpected error during auto-start: {}", e.getMessage(), e);
        }
    }

    /**
     * Optional: Manual trigger endpoint for restarting detection
     * Can be called from a REST controller if needed
     */
    public void restartAllDetection() {
        log.info("Manual restart requested - stopping all active detections first");
        
        // Note: You might want to track active cameras separately
        // For now, this method is a placeholder for future enhancement
        
        autoStartMotionDetection();
    }
}
