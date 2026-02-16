package com.backendcam.backendcam.model.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CategoryStreamResponse {
    private String categoryName;
    private int categoryId;
    private List<CameraHlsInfo> cameras;
}
