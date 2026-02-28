package com.backendcam.backendcam.controller;

import java.util.Map;
import java.util.Optional;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.backendcam.backendcam.model.entity.CameraStreamState;
import com.backendcam.backendcam.model.dto.camera.StreamRequest;
import com.backendcam.backendcam.model.entity.Camera;
import com.backendcam.backendcam.repository.CameraRepository;
import com.backendcam.backendcam.service.StreamManager;
import com.backendcam.backendcam.service.hls.HLSStreamService;

import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/stream")
public class StreamController {

    private final HLSStreamService hlsService;
    private final StreamManager streamManager;
    private final CameraRepository cameraRepository;

    @PostMapping("/hls/start")
    public ResponseEntity<Map<String, String>> startStream(@RequestBody StreamRequest request) {
        // Input validation
        if (request.getCameraId() == null || request.getCameraId().trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Camera ID cannot be null or empty"));
        }

        try {
            // Look up camera from Firebase
            Optional<Camera> cameraOpt = cameraRepository.getCameraById(request.getCameraId());
            if (cameraOpt.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Camera not found: " + request.getCameraId()));
            }

            Camera camera = cameraOpt.get();
            if (camera.getRtspUrl() == null || camera.getRtspUrl().isBlank()) {
                return ResponseEntity.badRequest().body(Map.of("error", "No RTSP URL configured for camera: " + request.getCameraId()));
            }

            // Sanitize camera ID to use as stream name
            String streamName = request.getCameraId().replaceAll("[^a-zA-Z0-9_-]", "_");

            String hlsUrl = hlsService.startHLSStream(camera.getRtspUrl(), streamName);
            return ResponseEntity.ok(Map.of("hlsUrl", hlsUrl));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", "Failed to start stream: " + e.getMessage()));
        }
    }

    @PostMapping("/hls/stop/{streamName}")
    public ResponseEntity<Map<String, String>> stopStream(@PathVariable String streamName) {
        if (streamName == null || streamName.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Stream name cannot be null or empty"));
        }

        // Sanitize stream name consistently
        String sanitizedStreamName = streamName.replaceAll("[^a-zA-Z0-9_-]", "_");

        hlsService.stopHLSStream(sanitizedStreamName);
        return ResponseEntity.ok(Map.of("message", "Stream stopped: " + sanitizedStreamName));
    }

    @PostMapping("/subscribe")
    public ResponseEntity<String> subscribe(@RequestParam String cameraId, @RequestParam String rtspUrl) {
        streamManager.subscribe(cameraId, rtspUrl);
        return ResponseEntity.ok("Subscribed to stream for camera: " + cameraId);
    }

    @PostMapping("/unsubscribe")
    public ResponseEntity<String> unsubscribe(@RequestParam String cameraId) {
        streamManager.unsubscribe(cameraId);
        return ResponseEntity.ok("Unsubscribed from stream for camera: " + cameraId);
    }

    @GetMapping("/{cameraId}/playlist.m3u8")
    public ResponseEntity<CameraStreamState> getPlaylist(@PathVariable String cameraId) {
        CameraStreamState state = streamManager.getStreamState(cameraId);
        if (state != null && "RUNNING".equals(state.getStatus())) {
            return ResponseEntity.ok(state);
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}
