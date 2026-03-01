package com.camerastatus.scheduler;

import com.camerastatus.firestore.FirestoreService;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;

@Component
public class CameraStatusScheduler {

    private static final Logger log = LoggerFactory.getLogger(CameraStatusScheduler.class);

    private final CameraStatusChecker cameraStatusChecker;
    private final FirestoreService firestoreService;

    // In-memory cache: docId -> last known online status (true=online, false=offline)
    private final Map<String, Boolean> lastKnownStatus = new ConcurrentHashMap<>();

    // Flag: has the cache been seeded from Firestore yet?
    private final AtomicBoolean cacheSeeded = new AtomicBoolean(false);

    public CameraStatusScheduler(CameraStatusChecker checker, FirestoreService fsService) {
        this.cameraStatusChecker = checker;
        this.firestoreService = fsService;
    }

    @Scheduled(fixedDelay = 60_000)
    public void checkCameras() {
        long t0 = System.nanoTime();

        List<QueryDocumentSnapshot> docs = firestoreService.fetchAllCameras();
        if (docs.isEmpty()) {
            log.info("[Cameras] No documents found.");
            return;
        }

        // --- Pre-seed cache from Firestore on first run after startup ---
        // This prevents unnecessary writes after a service restart
        if (cacheSeeded.compareAndSet(false, true)) {
            for (QueryDocumentSnapshot d : docs) {
                Object statusField = d.getData().get("status");
                if (statusField instanceof String s) {
                    lastKnownStatus.put(d.getId(), "online".equalsIgnoreCase(s));
                }
            }
            log.info("[Cameras] Cache pre-seeded from Firestore with {} entries", lastKnownStatus.size());
        }

        // --- Probe all cameras concurrently ---
        Map<String, CompletableFuture<Boolean>> tasks = new LinkedHashMap<>();
        for (QueryDocumentSnapshot d : docs) {
            String url = FirestoreService.pickRtspUrl(d.getData()).orElse(null);
            log.debug("[Cameras] doc={} url={}", d.getId(), url == null ? "<none>" : url);
            tasks.put(d.getId(),
                    url == null || url.isBlank()
                            ? CompletableFuture.completedFuture(false)
                            : cameraStatusChecker.isCameraOnlineAsync(url));
        }

        CompletableFuture.allOf(tasks.values().toArray(new CompletableFuture[0])).join();

        // --- Only write on status transitions ---
        List<String> nowOnline  = new ArrayList<>(); // offline -> online
        List<String> nowOffline = new ArrayList<>(); // online  -> offline
        int skipped = 0;

        for (Map.Entry<String, CompletableFuture<Boolean>> e : tasks.entrySet()) {
            String docId = e.getKey();
            boolean ok = false;
            try { ok = e.getValue().get(); } catch (Exception ex) { /* treat as offline */ }

            Boolean prev = lastKnownStatus.get(docId);

            if (prev == null || prev != ok) {
                // Status changed (or unknown) — write to Firestore
                if (ok) nowOnline.add(docId);
                else    nowOffline.add(docId);
                lastKnownStatus.put(docId, ok);
            } else {
                skipped++; // no change — skip write
            }
        }

        firestoreService.batchUpdateStatuses(nowOnline, nowOffline);

        long ms = (System.nanoTime() - t0) / 1_000_000L;
        log.info("[Cameras] Checked {} docs in {} ms ({} s) | wentOnline={}, wentOffline={}, skipped={} writes",
                docs.size(), ms, String.format("%.3f", ms / 1000.0),
                nowOnline.size(), nowOffline.size(), skipped);
    }
}

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
        log.info("[Cameras] Checked {} docs in {} ms ({} s) | online={}, offline={}",
                docs.size(), ms, String.format("%.3f", ms / 1000.0), onlineIds.size(), offlineIdToLastTs.size());
    }
}
