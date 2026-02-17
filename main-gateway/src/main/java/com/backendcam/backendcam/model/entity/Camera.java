package com.backendcam.backendcam.model.entity;


import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class Camera {
    private String id;
    private String name;
    private String latlong;
    private String address;
    private String status;
    private String rtspUrl;
}
