package com.backendcam.backendcam.model.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class LicensePlateInfo {
    private String fullPlate;   // e.g. "8กผ 8167"
    private String text;        // e.g. "8กผ"
    private String number;      // e.g. "8167"
    private String province;    // e.g. "กรุงเทพมหานคร"
}
