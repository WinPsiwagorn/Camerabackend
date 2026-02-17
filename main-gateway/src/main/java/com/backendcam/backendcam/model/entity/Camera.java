package com.backendcam.backendcam.model.entity;

import com.google.cloud.firestore.GeoPoint;

import java.util.List;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class Camera {
    private String id;
    private String name;
    private GeoPoint latLong;
    private String address;
    private String status;
    private String rtspUrl;
    private List<String> categories;
    private LastSeen lastSeen;

    @Getter
    @Setter
    public static class LastSeen {
        private String message;
        private String timestamp;
    }
}