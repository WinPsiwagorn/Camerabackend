package com.backendcam.backendcam.model.entity;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CameraStreamState {
    private String cameraId;
    private String status; // STOPPED | RUNNING
    private int refCount;
    private long lastAccessAt;
    private Object processHandle; // Can be Thread or Process
}
