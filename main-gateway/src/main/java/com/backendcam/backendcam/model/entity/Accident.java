package com.backendcam.backendcam.model.entity;

import com.google.cloud.Timestamp;
import com.google.cloud.firestore.annotation.DocumentId;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

@Getter
@Setter
public class Accident {

    @DocumentId
    private String id;
    private String cameraId;
    private String imageUrl;
    private String timestamp;

    public Map<String, Object> toMap() {
        Map<String, Object> map = new HashMap<>();
        map.put("cameraId", cameraId);
        map.put("imageUrl", imageUrl);
        map.put("timestamp", timestamp);
        return map;
    }

    public static Accident fromMap(String id, Map<String, Object> data) {
        Accident accident = new Accident();
        accident.setId(id);
        accident.setCameraId((String) data.get("cameraId"));
        accident.setImageUrl((String) data.get("imageUrl"));

        Object tsObj = data.get("timestamp");
        if (tsObj instanceof Timestamp ts) {
            // Convert Firestore Timestamp to ISO-8601 string
            Instant instant = ts.toDate().toInstant();
            accident.setTimestamp(DateTimeFormatter.ISO_INSTANT.format(instant));
        } else if (tsObj != null) {
            // Fallback: if it's already a String or something else, just use toString()
            accident.setTimestamp(tsObj.toString());
        } else {
            accident.setTimestamp(null);
        }

        return accident;
    }
}
