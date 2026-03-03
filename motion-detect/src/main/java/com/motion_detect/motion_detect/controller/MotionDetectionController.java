package com.motion_detect.motion_detect.controller;

import com.motion_detect.motion_detect.model.dto.StartDetectionRequest;
import com.motion_detect.motion_detect.service.motion.MotionDetectionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/detection")
@RequiredArgsConstructor
public class MotionDetectionController {

    private final MotionDetectionService motionDetectionService;

    /**
     * Start motion detection for a camera
     */
    @PostMapping("/start")
    public ResponseEntity<?> startDetection(@RequestBody StartDetectionRequest request) {
        try {
            log.info("Starting detection for camera: {}", request.getCameraId());
            motionDetectionService.startDetection(request.getCameraId());
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Motion detection started for camera " + request.getCameraId());
            response.put("cameraId", request.getCameraId());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Failed to start detection for camera {}: {}", request.getCameraId(), e.getMessage(), e);
            
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            error.put("cameraId", request.getCameraId());
            
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Stop motion detection for a camera
     */
    @PostMapping("/stop/{cameraId}")
    public ResponseEntity<?> stopDetection(@PathVariable String cameraId) {
        try {
            log.info("Stopping detection for camera: {}", cameraId);
            motionDetectionService.stopDetection(cameraId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Motion detection stopped for camera " + cameraId);
            response.put("cameraId", cameraId);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Failed to stop detection for camera {}: {}", cameraId, e.getMessage(), e);
            
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            error.put("cameraId", cameraId);
            
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Get detection status for a camera
     */
    @GetMapping("/status/{cameraId}")
    public ResponseEntity<?> getDetectionStatus(@PathVariable String cameraId) {
        boolean isActive = motionDetectionService.isDetectionActive(cameraId);
        
        Map<String, Object> response = new HashMap<>();
        response.put("cameraId", cameraId);
        response.put("active", isActive);
        response.put("status", isActive ? "running" : "stopped");
        
        return ResponseEntity.ok(response);
    }

    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<?> health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "motion-detect");
        return ResponseEntity.ok(response);
    }
}
