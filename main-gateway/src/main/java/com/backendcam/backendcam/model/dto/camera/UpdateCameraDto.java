package com.backendcam.backendcam.model.dto.camera;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@JsonInclude(JsonInclude.Include.NON_NULL)
public class UpdateCameraDto {
    private String name;
    private String latLong;
    private String address;
    private String rtspUrl;
}
