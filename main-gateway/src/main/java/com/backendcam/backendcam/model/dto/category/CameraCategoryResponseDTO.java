package com.backendcam.backendcam.model.dto.category;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CameraCategoryResponseDTO {
    private String message;
    private String categoryId;
    private String cameraId;
}
