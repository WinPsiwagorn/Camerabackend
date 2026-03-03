package com.motion_detect.motion_detect.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class MotionEvent {
    private String cameraId;
    private long timestamp;
    private String imageUrl;
    private String metadata;
}
