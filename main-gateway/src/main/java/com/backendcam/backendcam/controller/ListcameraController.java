package com.backendcam.backendcam.controller;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.backendcam.backendcam.model.dto.ListCamera;
import com.backendcam.backendcam.service.listcamera.ListCameraService;

import lombok.RequiredArgsConstructor;


@RestController
@RequiredArgsConstructor
@RequestMapping("/stream")
public class ListcameraController {

    private final ListCameraService listCameraService;

    @GetMapping("/list")
    public ResponseEntity<List<ListCamera>> GetCameraList(@RequestParam(defaultValue = "1") int page){
        try {
            List<ListCamera> cameras = listCameraService.getCameraByPage(page, 10);
            return ResponseEntity.ok(cameras);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(null);
        }
    }

}
