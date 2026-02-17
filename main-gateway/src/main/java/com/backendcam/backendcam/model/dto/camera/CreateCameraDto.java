package com.backendcam.backendcam.model.dto.camera;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateCameraDto {
  private String name;
  private String latLong;
  private String address;
  private String rtspUrl;
}