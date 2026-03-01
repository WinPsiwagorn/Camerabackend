package com.backendcam.backendcam.model.dto.camera;

import java.util.List;
import com.backendcam.backendcam.model.dto.category.CategoryResponseDTO;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CameraResponseDto {
    private String id;
    private String name;
    private String latLong;
    private String address;
    private String status;
    private List<CategoryResponseDTO> categories;
    private LastSeen lastSeen;

    @Getter
    @Setter
    public static class LastSeen {
        private String timestamp;
    }
}