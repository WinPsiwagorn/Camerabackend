package com.camerastatus.scheduler;

import com.camerastatus.firestore.FirestoreService;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.concurrent.CompletableFuture;

@Component
public class CameraStatusScheduler {

    private static final Logger log = LoggerFactory.getLogger(CameraStatusScheduler.class);

    private final CameraStatusChecker cameraStatusChecker;
    private final FirestoreService firestoreService;

    public CameraStatusScheduler(CameraStatusChecker checker, FirestoreService fsService) {
        this.cameraStatusChecker = checker;
        this.firestoreService = fsService;
    }

    // fixedDelay: next run starts 60s AFTER the previous one finishes
    // prevents pile-up when checking hundreds of cameras
    @Scheduled(fixedDelay = 60_000)
    public void checkCameras() {
        long t0 = System.nanoTime();

        List<QueryDocumentSnapshot> docs = firestoreService.fetchAllCameras();
        if (docs.isEmpty()) {
            log.info("[Cameras] No documents found.");
            return;
        }

        // Kick off all probes concurrently
        Map<String, CompletableFuture<Boolean>> tasks = new LinkedHashMap<>();
        // Also keep existing lastSeen.timestamp for offline docs
        Map<String, String> docIdToLastTs = new LinkedHashMap<>();

        for (QueryDocumentSnapshot d : docs) {
            String url = FirestoreService.pickRtspUrl(d.getData()).orElse(null);
            tasks.put(d.getId(),
                    url == null || url.isBlank()
                            ? CompletableFuture.completedFuture(false)
                            : cameraStatusChecker.isCameraOnlineAsync(url));

            // Extract existing lastSeen.timestamp for offline update
            Object ls = d.getData().get("lastSeen");
            if (ls instanceof Map<?, ?> lsMap) {
                Object ts = lsMap.get("timestamp");
                if (ts instanceof String s) docIdToLastTs.put(d.getId(), s);
            }
        }

        CompletableFuture.allOf(tasks.values().toArray(new CompletableFuture[0])).join();

        List<String> onlineIds = new ArrayList<>();
        Map<String, String> offlineIdToLastTs = new LinkedHashMap<>();

        for (Map.Entry<String, CompletableFuture<Boolean>> e : tasks.entrySet()) {
            String docId = e.getKey();
            boolean ok = false;
            try { ok = e.getValue().get(); } catch (Exception ex) { /* treat as offline */ }

            if (ok) {
                onlineIds.add(docId);
            } else {
                offlineIdToLastTs.put(docId, docIdToLastTs.get(docId));
            }
        }

        // Single batched Firestore write instead of N individual writes
        firestoreService.batchUpdateStatuses(onlineIds, offlineIdToLastTs);

        long ms = (System.nanoTime() - t0) / 1_000_000L;
        log.info("[Cameras] Checked {} docs in {:.3f} s → online={}, offline={}",
                docs.size(), ms / 1000.0, onlineIds.size(), offlineIdToLastTs.size());
    }
}
