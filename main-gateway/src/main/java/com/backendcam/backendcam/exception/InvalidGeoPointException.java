package com.backendcam.backendcam.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class InvalidGeoPointException extends RuntimeException {
    public InvalidGeoPointException(String latLong) {
        super("Invalid latLong format: '" + latLong + "'. Expected format: 'latitude,longitude' (e.g. '13.756,100.501')");
    }
}
