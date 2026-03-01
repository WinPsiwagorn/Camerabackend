package com.camerastatus.firestore;

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

    /**
     * Write only on status transitions:
     * - onlineIds       : cameras that just came back online → write status=online only, no timestamp
     * - offlineIds      : cameras that just went offline     → write status=offline + lastSeen.timestamp=now
     */
    public void batchUpdateStatuses(List<String> onlineIds, List<String> offlineIds) {
        if (!bootstrap.isInitialized()) return;
        if (onlineIds.isEmpty() && offlineIds.isEmpty()) return;
        try {
            Firestore db = FirestoreClient.getFirestore();
            String nowStr = OffsetDateTime.now(BANGKOK).format(ISO_OFFSET);
            WriteBatch batch = db.batch();
            int ops = 0;

            // came back online — just flip status, frontend shows "online" with no timestamp needed
            for (String docId : onlineIds) {
                batch.set(db.collection(COLLECTION).document(docId),
                        Map.of("status", "online"),
                        SetOptions.merge());
                if (++ops == 499) { batch.commit(); batch = db.batch(); ops = 0; }
            }

            // just went offline — record exact moment it died, frontend calculates "X ago"
            for (String docId : offlineIds) {
                batch.set(db.collection(COLLECTION).document(docId),
                        Map.of(
                                "status", "offline",
                                "lastSeen", Map.of("timestamp", nowStr)
                        ),
                        SetOptions.merge());
                if (++ops == 499) { batch.commit(); batch = db.batch(); ops = 0; }
            }

            if (ops > 0) batch.commit();
        } catch (Exception e) {
            throw new RuntimeException("Failed to batch update statuses", e);
        }
    }

    public static Optional<String> pickRtspUrl(Map<String, Object> data) {
        for (String key : List.of("rtspUrl", "url", "URL", "rtsp_url")) {
            Object val = data.get(key);
            if (val instanceof String s && !s.isBlank()) {
                return Optional.of(s.trim());
            }
        }
        return Optional.empty();
    }
}

