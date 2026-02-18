package com.backendcam.backendcam.controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.backendcam.backendcam.model.dto.MessageResponseDTO;
import com.backendcam.backendcam.model.dto.PageResponse;
import com.backendcam.backendcam.model.dto.camera.CameraMapResponseDto;
import com.backendcam.backendcam.model.dto.camera.CameraResponseDto;
import com.backendcam.backendcam.model.dto.camera.CreateCameraDto;
import com.backendcam.backendcam.service.camera.CameraService;

import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/cameras")
public class CameraController {

    private final CameraService cameraService;

    @PostMapping
    public ResponseEntity<CameraResponseDto> createCamera(@RequestBody CreateCameraDto createDto) {
        CameraResponseDto camera = cameraService.createCamera(createDto);
        return ResponseEntity.ok(camera);
    }

    @GetMapping
    public ResponseEntity<PageResponse<List<CameraResponseDto>>> getCameras(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int limit) {
        PageResponse<List<CameraResponseDto>> cameras = cameraService.getCamerasByPage(page, limit);
        return ResponseEntity.ok(cameras);
    }

    @GetMapping("/{id}")
    public ResponseEntity<CameraResponseDto> getCameraById(@PathVariable String id) {
        return cameraService.getCameraById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/{id}")
    public ResponseEntity<CameraResponseDto> updateCamera(
        @PathVariable String id, 
        @RequestBody Map<String, Object> updates
    ) {
        return cameraService.updateCamera(id, updates)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<MessageResponseDTO> deleteCamera(@PathVariable String id) {
        cameraService.deleteCamera(id);
        return ResponseEntity.ok(new MessageResponseDTO("Camera ID: " + id + " deleted successfully"));
    }

    @GetMapping("/map")
    public ResponseEntity<List<CameraMapResponseDto>> getCamerasForMap() {
        List<CameraMapResponseDto> cameras = cameraService.getCamerasForMap();
        return ResponseEntity.ok(cameras);
    }
}
