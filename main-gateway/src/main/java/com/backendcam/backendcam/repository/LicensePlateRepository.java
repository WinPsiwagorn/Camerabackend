package com.backendcam.backendcam.repository;

import com.backendcam.backendcam.model.entity.LicensePlate;
import com.backendcam.backendcam.service.firestore.FirebaseAdminBootstrap;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;

import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Repository;

import java.util.List;
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

    public String save(LicensePlate plate) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        ApiFuture<DocumentReference> future = db.collection(COLLECTION).add(plate);
        return future.get().getId();
    }

    public List<LicensePlate> getAll() throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        return db.collection(COLLECTION).get().get().getDocuments()
                .stream()
                .map(doc -> doc.toObject(LicensePlate.class))
                .collect(Collectors.toList());
    }

    public List<LicensePlate> findByFullPlate(String plateText) throws ExecutionException, InterruptedException {
        return queryList(db -> db.collection(COLLECTION)
                .whereEqualTo("licensePlate.fullPlate", plateText));
    }

    public List<LicensePlate> findByCameraId(String cameraId) throws ExecutionException, InterruptedException {
        return queryList(db -> db.collection(COLLECTION)
                .whereEqualTo("cameraId", cameraId));
    }

    public List<LicensePlate> findByText(String text) throws ExecutionException, InterruptedException {
        return queryList(db -> db.collection(COLLECTION)
                .whereEqualTo("licensePlate.text", text));
    }

    public List<LicensePlate> findByNumber(String number) throws ExecutionException, InterruptedException {
        return queryList(db -> db.collection(COLLECTION)
                .whereEqualTo("licensePlate.number", number));
    }

    public List<LicensePlate> findByProvince(String province) throws ExecutionException, InterruptedException {
        return queryList(db -> db.collection(COLLECTION)
                .whereEqualTo("licensePlate.province", province));
    }

    public List<LicensePlate> findByTimestampRange(String start, String end) throws ExecutionException, InterruptedException {
        return queryList(db -> db.collection(COLLECTION)
                .whereGreaterThanOrEqualTo("timestamp", start)
                .whereLessThanOrEqualTo("timestamp", end));
    }

    public List<LicensePlate> findByCameraIdAndTimestampRange(String cameraId, String start, String end)
            throws ExecutionException, InterruptedException {
        return queryList(db -> db.collection(COLLECTION)
                .whereEqualTo("cameraId", cameraId)
                .whereGreaterThanOrEqualTo("timestamp", start)
                .whereLessThanOrEqualTo("timestamp", end));
    }

    // Helper: run a query and map all docs to LicensePlate
    private List<LicensePlate> queryList(java.util.function.Function<Firestore, Query> queryFn)
            throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        return queryFn.apply(db).get().get().getDocuments()
                .stream()
                .map(doc -> doc.toObject(LicensePlate.class))
                .collect(Collectors.toList());
    }
}
