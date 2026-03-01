package com.camerastatus.firestore;

import com.camerastatus.util.TimeAgoFormatter;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
public class FirestoreService {

    private static final String COLLECTION = "cameras";
    private static final ZoneId BANGKOK = ZoneId.of("Asia/Bangkok");
    private static final DateTimeFormatter ISO_OFFSET = DateTimeFormatter.ISO_OFFSET_DATE_TIME;

    private final FirebaseAdminBootstrap bootstrap;

    public FirestoreService(FirebaseAdminBootstrap bootstrap) {
        this.bootstrap = bootstrap;
    }

    public List<QueryDocumentSnapshot> fetchAllCameras() {
        if (!bootstrap.isInitialized()) return Collections.emptyList();
        try {
            Firestore db = FirestoreClient.getFirestore();
            return db.collection(COLLECTION).get().get().getDocuments();
        } catch (Exception e) {
            throw new RuntimeException("Failed to fetch cameras", e);
        }
    }

    public void batchUpdateStatuses(List<String> onlineIds, Map<String, String> offlineIdToLastTs) {
        if (!bootstrap.isInitialized()) return;
        try {
            Firestore db = FirestoreClient.getFirestore();
            String nowStr = OffsetDateTime.now(BANGKOK).format(ISO_OFFSET);
            WriteBatch batch = db.batch();
            int ops = 0;

            for (String docId : onlineIds) {
                Map<String, Object> payload = Map.of(
                        "status", "online",
                        "lastSeen", Map.of(
                                "timestamp", nowStr,
                                "message", TimeAgoFormatter.humanizeSinceSeconds(0)
                        )
                );
                batch.set(db.collection(COLLECTION).document(docId), payload, SetOptions.merge());
                if (++ops == 499) { batch.commit(); batch = db.batch(); ops = 0; }
            }

            for (Map.Entry<String, String> e : offlineIdToLastTs.entrySet()) {
                String docId = e.getKey();
                String tsStr = e.getValue();
                Map<String, Object> payload = new HashMap<>();
                payload.put("status", "offline");

                if (tsStr != null && !tsStr.isBlank()) {
                    OffsetDateTime ts = OffsetDateTime.parse(tsStr, ISO_OFFSET);
                    long secs = Math.max(0, Duration.between(ts, OffsetDateTime.now(BANGKOK)).getSeconds());
                    payload.put("lastSeen", Map.of(
                            "timestamp", tsStr,
                            "message", TimeAgoFormatter.humanizeSinceSeconds(secs)
                    ));
                }

                batch.set(db.collection(COLLECTION).document(docId), payload, SetOptions.merge());
                if (++ops == 499) { batch.commit(); batch = db.batch(); ops = 0; }
            }

            if (ops > 0) batch.commit();
        } catch (Exception e) {
            throw new RuntimeException("Failed to batch update statuses", e);
        }
    }

    public static Optional<String> pickRtspUrl(Map<String, Object> data) {
        Object u1 = data.get("url");
        Object u2 = data.get("URL");
        String url = u1 instanceof String s1 ? s1 : (u2 instanceof String s2 ? s2 : null);
        return Optional.ofNullable(url).map(String::trim).filter(s -> !s.isEmpty());
    }
}
