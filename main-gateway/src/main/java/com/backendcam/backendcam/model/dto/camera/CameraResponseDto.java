package com.backendcam.backendcam.model.dto.camera;

import java.util.List;
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
    private List<String> categories;
    private LastSeen lastSeen;

    @Getter
    @Setter
    public static class LastSeen {
        private String message;
        private String timestamp;
    }
}