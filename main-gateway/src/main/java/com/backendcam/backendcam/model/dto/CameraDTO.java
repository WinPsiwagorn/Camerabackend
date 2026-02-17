package com.backendcam.backendcam.model.dto;

import java.util.List;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CameraDto {
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