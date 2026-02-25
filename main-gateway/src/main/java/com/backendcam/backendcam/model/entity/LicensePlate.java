package com.backendcam.backendcam.model.entity;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class LicensePlate {
    private String timestamp;
    private String imageUrl;
    private String cameraId;
    private LicensePlateBody licensePlate;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LicensePlateBody {
        private String fullPlate;   // e.g. "8กผ 8167"
        private String text;        // e.g. "8กผ"
        private String number;      // e.g. "8167"
        private String province;    // e.g. "กรุงเทพมหานคร"
    }
}
