package com.backendcam.backendcam.model.dto.camera;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class CameraTotalResponseDto {
    private long total;
    private long online;
    private long offline;
}
