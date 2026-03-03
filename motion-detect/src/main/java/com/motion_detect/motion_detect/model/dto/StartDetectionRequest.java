package com.motion_detect.motion_detect.model.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class StartDetectionRequest {
    private String cameraId;
    private Integer checkIntervalSeconds; // optional, default 3
}
