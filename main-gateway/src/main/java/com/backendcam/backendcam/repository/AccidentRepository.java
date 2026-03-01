package com.backendcam.backendcam.repository;

import com.backendcam.backendcam.model.entity.Accident;
import com.backendcam.backendcam.service.firestore.FirebaseAdminBootstrap;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ExecutionException;

@Repository
@RequiredArgsConstructor
public class AccidentRepository {

    private static final String COLLECTION = "accidents";

    private final FirebaseAdminBootstrap bootstrap;

    private Firestore getFirestore() {
        if (!bootstrap.isInitialized()) {
            throw new IllegalStateException("Firebase is not initialized");
        }
        return FirestoreClient.getFirestore();
    }

    public String save(Accident accident) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        ApiFuture<DocumentReference> future = db.collection(COLLECTION).add(accident.toMap());
        return future.get().getId();
    }

    public Optional<Accident> findById(String id) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        DocumentSnapshot snap = db.collection(COLLECTION).document(id).get().get();
        if (!snap.exists()) return Optional.empty();
        return Optional.of(Accident.fromMap(snap.getId(), snap.getData()));
    }

    public List<Accident> findAll() throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        List<Accident> accidents = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION).get();
        for (QueryDocumentSnapshot document : future.get().getDocuments()) {
            accidents.add(Accident.fromMap(document.getId(), document.getData()));
        }
        return accidents;
    }

    public List<Accident> findByPage(int page, int limit) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Query query = db.collection(COLLECTION)
                .orderBy("timestamp", Query.Direction.DESCENDING)
                .offset((page - 1) * limit)
                .limit(limit);
        List<Accident> accidents = new ArrayList<>();
        for (QueryDocumentSnapshot document : query.get().get().getDocuments()) {
            accidents.add(Accident.fromMap(document.getId(), document.getData()));
        }
        return accidents;
    }

    public List<Accident> findByCameraId(String cameraId) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION)
                .whereEqualTo("cameraId", cameraId)
                .orderBy("timestamp", Query.Direction.DESCENDING)
                .get();
        List<Accident> accidents = new ArrayList<>();
        for (QueryDocumentSnapshot document : future.get().getDocuments()) {
            accidents.add(Accident.fromMap(document.getId(), document.getData()));
        }
        return accidents;
    }

    public void delete(String id) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        db.collection(COLLECTION).document(id).delete().get();
    }

    public long getTotalCount() throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION).get();
        return future.get().size();
    }
}
