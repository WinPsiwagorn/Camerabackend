package com.backendcam.backendcam.model.dto.accident;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AccidentResponseDto {
    private String id;
    private String cameraId;
    private String imageUrl;
    private String timestamp;
}
