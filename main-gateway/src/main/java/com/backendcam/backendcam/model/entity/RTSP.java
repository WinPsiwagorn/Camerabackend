package com.backendcam.backendcam.model.entity;


import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class RTSP {
    private String id;
    private String name;
    private String latlong;
    private String address;
    private String status;
    private String rtspUrl;
    private List<String> categories;

}
