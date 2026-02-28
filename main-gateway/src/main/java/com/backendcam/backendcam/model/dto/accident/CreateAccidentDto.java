package com.backendcam.backendcam.model.dto.accident;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateAccidentDto {
    private String cameraId;
    private String imageUrl;
    private String timestamp;
}
