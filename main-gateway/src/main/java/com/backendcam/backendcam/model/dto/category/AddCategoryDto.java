package com.backendcam.backendcam.model.dto.category;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AddCategoryDto {
    @NotBlank(message = "cameraId is required")
    private String cameraId;
}