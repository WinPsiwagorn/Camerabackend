package com.backendcam.backendcam.model.dto.camera;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CameraMapResponseDto {
    private String id;
    private String name;
    private String latLong;
    private String status;
}
