package com.backendcam.backendcam.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.backendcam.backendcam.service.motion.MotionDetectionService;

import lombok.Data;
import lombok.RequiredArgsConstructor;

/**
 * Motion Detection Controller
 * 
 * Endpoints:
 * - POST /motion/start - Start motion detection for a camera
 * - POST /motion/stop - Stop motion detection for a camera
 * - GET /motion/status - Get status of all active cameras
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/motion")
public class MotionDetectionController {

    private final MotionDetectionService motionDetectionService;

    /**
     * Start motion detection for a camera
     * 
     * POST /motion/start
     * {
     *   "cameraId": "camera-1",
     *   "url": "rtsp://admin:pass@192.168.1.100/stream",
     *   "checkIntervalSeconds": 1
     * }
     */
    @PostMapping("/start")
    public Map<String, Object> startMotionDetection(@RequestBody StartRequest request) {
        Map<String, Object> response = new HashMap<>();
        
        try {
            boolean started = motionDetectionService.startDetection(
                request.getCameraId(),
                request.getUrl(),
                request.getCheckIntervalSeconds()
            );
            
            if (started) {
                response.put("success", true);
                response.put("message", "Motion detection started for camera: " + request.getCameraId());
                response.put("cameraId", request.getCameraId());
                response.put("url", request.getUrl());
                response.put("checkInterval", request.getCheckIntervalSeconds() + " seconds");
            } else {
                response.put("success", false);
                response.put("message", "Camera " + request.getCameraId() + " is already running");
            }
            
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", e.getMessage());
        }
        
        return response;
    }

    /**
     * Stop motion detection for a camera
     * 
     * POST /motion/stop
     * {
     *   "cameraId": "camera-1"
     * }
     */
    @PostMapping("/stop")
    public Map<String, Object> stopMotionDetection(@RequestBody StopRequest request) {
        Map<String, Object> response = new HashMap<>();
        
        try {
            Map<String, Object> stats = motionDetectionService.stopDetection(request.getCameraId());
            
            if (stats != null) {
                response.put("success", true);
                response.put("message", "Motion detection stopped for camera: " + request.getCameraId());
                response.put("cameraId", request.getCameraId());
                response.put("statistics", stats);
            } else {
                response.put("success", false);
                response.put("message", "No active detection for camera: " + request.getCameraId());
            }
            
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", e.getMessage());
        }
        
        return response;
    }

    /**
     * Get status of all active cameras
     * 
     * GET /motion/status
     */
    @GetMapping("/status")
    public Map<String, Object> getStatus() {
        Map<String, Object> response = new HashMap<>();
        Map<String, Object> cameras = motionDetectionService.getActiveDetections();
        
        response.put("activeCameras", cameras.size());
        response.put("cameras", cameras);
        
        return response;
    }

    /**
     * Request DTOs
     */
    @Data
    public static class StartRequest {
        private String cameraId;
        private String url;
        private int checkIntervalSeconds = 1; // default 1 second
    }

    @Data
    public static class StopRequest {
        private String cameraId;
    }
}