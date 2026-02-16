package com.backendcam.backendcam.model.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;

@Getter
@Setter
@NoArgsConstructor
public class LicensePlate {

    private String timestamp;              // ISO 8601: "2026-02-15T22:39:15.426598+07:00"
    private String imageUrl;               // full image URL
    private String cameraId;               // "camera123"
    private LicensePlateInfo licensePlate;  // nested plate info

    /**
     * Parse the ISO 8601 timestamp string into a LocalDateTime.
     * Returns null if timestamp is null or unparseable.
     */
    public LocalDateTime getDateTime() {
        if (timestamp == null || timestamp.isBlank()) return null;
        try {
            return OffsetDateTime.parse(timestamp).toLocalDateTime();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Parse the ISO 8601 timestamp string into an OffsetDateTime (preserves timezone offset).
     */
    public OffsetDateTime getOffsetDateTime() {
        if (timestamp == null || timestamp.isBlank()) return null;
        try {
            return OffsetDateTime.parse(timestamp);
        } catch (Exception e) {
            return null;
        }
    }

    /** Convenience: get the full plate string (e.g. "8กผ 8167") */
    public String getFullPlate() {
        return licensePlate != null ? licensePlate.getFullPlate() : null;
    }
}
