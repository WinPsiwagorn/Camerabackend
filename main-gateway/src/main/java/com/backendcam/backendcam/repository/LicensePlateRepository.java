package com.backendcam.backendcam.repository;

import com.backendcam.backendcam.model.entity.LicensePlate;
import com.backendcam.backendcam.model.dto.LicensePlateInfo;
import com.backendcam.backendcam.service.firestore.FirebaseAdminBootstrap;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;

import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Repository
@RequiredArgsConstructor
public class LicensePlateRepository {

    private static final String COLLECTION = "licensePlates";

    private final FirebaseAdminBootstrap bootstrap;

    private Firestore getFirestore() {
        if (!bootstrap.isInitialized()) {
            throw new IllegalStateException("Firebase is not initialized");
        }
        return FirestoreClient.getFirestore();
    }

    // Save a license plate record (matches Firebase format)
    public LicensePlate save(LicensePlate plate) {
        try {
            Firestore db = getFirestore();

            // Nested licensePlate map
            Map<String, Object> plateInfo = new HashMap<>();
            if (plate.getLicensePlate() != null) {
                plateInfo.put("fullPlate", plate.getLicensePlate().getFullPlate());
                plateInfo.put("text", plate.getLicensePlate().getText());
                plateInfo.put("number", plate.getLicensePlate().getNumber());
                plateInfo.put("province", plate.getLicensePlate().getProvince());
            }

            Map<String, Object> data = new HashMap<>();
            data.put("timestamp", plate.getTimestamp());
            data.put("imageUrl", plate.getImageUrl());
            data.put("cameraId", plate.getCameraId());
            data.put("licensePlate", plateInfo);

            DocumentReference docRef = db.collection(COLLECTION).document();
            docRef.set(data).get();

            return plate;
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to save license plate", e);
        }
    }

    // Get all license plate records
    public List<LicensePlate> getAll() throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        List<LicensePlate> plates = new ArrayList<>();

        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION).get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        for (QueryDocumentSnapshot document : documents) {
            plates.add(documentToLicensePlate(document));
        }

        return plates;
    }

    // Search by full plate text (licensePlate.fullPlate)
    public List<LicensePlate> findByLicensePlate(String plateText) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        List<LicensePlate> plates = new ArrayList<>();

        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION)
                .whereEqualTo("licensePlate.fullPlate", plateText)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        for (QueryDocumentSnapshot document : documents) {
            plates.add(documentToLicensePlate(document));
        }

        return plates;
    }

    // Search by camera ID
    public List<LicensePlate> findByCameraId(String cameraId) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        List<LicensePlate> plates = new ArrayList<>();

        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION)
                .whereEqualTo("cameraId", cameraId)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        for (QueryDocumentSnapshot document : documents) {
            plates.add(documentToLicensePlate(document));
        }

        return plates;
    }

    // Search by text on plate (licensePlate.text)
    public List<LicensePlate> findByText(String text) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        List<LicensePlate> plates = new ArrayList<>();

        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION)
                .whereEqualTo("licensePlate.text", text)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        for (QueryDocumentSnapshot document : documents) {
            plates.add(documentToLicensePlate(document));
        }

        return plates;
    }

    // Search by number on plate (licensePlate.number)
    public List<LicensePlate> findByNumber(String number) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        List<LicensePlate> plates = new ArrayList<>();

        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION)
                .whereEqualTo("licensePlate.number", number)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        for (QueryDocumentSnapshot document : documents) {
            plates.add(documentToLicensePlate(document));
        }

        return plates;
    }

    // Search by province
    public List<LicensePlate> findByProvince(String province) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        List<LicensePlate> plates = new ArrayList<>();

        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION)
                .whereEqualTo("licensePlate.province", province)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        for (QueryDocumentSnapshot document : documents) {
            plates.add(documentToLicensePlate(document));
        }

        return plates;
    }

    // Search by date range (ISO 8601 string comparison — works because ISO 8601 sorts lexicographically)
    public List<LicensePlate> findByDateRange(OffsetDateTime startDate, OffsetDateTime endDate)
            throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();

        String startTs = startDate.format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
        String endTs = endDate.format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);

        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION)
                .whereGreaterThanOrEqualTo("timestamp", startTs)
                .whereLessThanOrEqualTo("timestamp", endTs)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        return documents.stream()
                .map(this::documentToLicensePlate)
                .collect(Collectors.toList());
    }

    /** Overload: accept LocalDateTime and assume system default offset */
    public List<LicensePlate> findByDateRange(LocalDateTime startDate, LocalDateTime endDate)
            throws ExecutionException, InterruptedException {
        ZoneOffset offset = OffsetDateTime.now().getOffset();
        return findByDateRange(startDate.atOffset(offset), endDate.atOffset(offset));
    }

    // Search by camera ID and date range
    public List<LicensePlate> findByCameraIdAndDateRange(String cameraId, OffsetDateTime startDate, OffsetDateTime endDate)
            throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();

        String startTs = startDate.format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
        String endTs = endDate.format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);

        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION)
                .whereEqualTo("cameraId", cameraId)
                .whereGreaterThanOrEqualTo("timestamp", startTs)
                .whereLessThanOrEqualTo("timestamp", endTs)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        return documents.stream()
                .map(this::documentToLicensePlate)
                .collect(Collectors.toList());
    }

    /** Overload: accept LocalDateTime and assume system default offset */
    public List<LicensePlate> findByCameraIdAndDateRange(String cameraId, LocalDateTime startDate, LocalDateTime endDate)
            throws ExecutionException, InterruptedException {
        ZoneOffset offset = OffsetDateTime.now().getOffset();
        return findByCameraIdAndDateRange(cameraId, startDate.atOffset(offset), endDate.atOffset(offset));
    }

    // Helper: convert Firestore document to LicensePlate (matching nested format)
    @SuppressWarnings("unchecked")
    private LicensePlate documentToLicensePlate(QueryDocumentSnapshot document) {
        LicensePlate plate = new LicensePlate();
        plate.setTimestamp(document.getString("timestamp"));
        plate.setImageUrl(document.getString("imageUrl"));
        plate.setCameraId(document.getString("cameraId"));

        // Read nested licensePlate map
        Object lpObj = document.get("licensePlate");
        if (lpObj instanceof Map) {
            Map<String, Object> lpMap = (Map<String, Object>) lpObj;
            LicensePlateInfo info = new LicensePlateInfo();
            info.setFullPlate((String) lpMap.get("fullPlate"));
            info.setText((String) lpMap.get("text"));
            info.setNumber((String) lpMap.get("number"));
            info.setProvince((String) lpMap.get("province"));
            plate.setLicensePlate(info);
        }

        return plate;
    }
}
