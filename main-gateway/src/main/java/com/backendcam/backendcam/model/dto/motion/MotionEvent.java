package com.backendcam.backendcam.model.dto.motion;

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
