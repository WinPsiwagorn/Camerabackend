package com.backendcam.backendcam.controller;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.backendcam.backendcam.model.dto.CameraDto;
import com.backendcam.backendcam.service.camera.CameraService;

import lombok.RequiredArgsConstructor;


@RestController
@RequiredArgsConstructor
@RequestMapping("/cameras")
public class CameraController {

    private final CameraService listCameraService;

    @GetMapping("")
    public ResponseEntity<List<CameraDto>> getCameras(@RequestParam(defaultValue = "1") int page) {
        try {
            List<CameraDto> cameras = listCameraService.getCameraByPage(page, 10);
            return ResponseEntity.ok(cameras);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(null);
        }
    }

}
