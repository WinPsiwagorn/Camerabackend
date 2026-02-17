package com.backendcam.backendcam.repository;

import com.backendcam.backendcam.model.entity.Camera;
import com.backendcam.backendcam.service.firestore.FirebaseAdminBootstrap;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;

import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Repository;

import java.util.*;
import java.util.concurrent.ExecutionException;

@Repository
@RequiredArgsConstructor
public class CameraRepository {
    
    private static final String COLLECTION = "cameras";
    private final FirebaseAdminBootstrap bootstrap;

    private Firestore getFirestore() {
        if (!bootstrap.isInitialized()) {
            throw new IllegalStateException("Firebase is not initialized");
        }
        return FirestoreClient.getFirestore();
    }

    public List<Camera> getCamerasByPage(int page, int pageSize) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Query query = db.collection(COLLECTION)
                .orderBy(FieldPath.documentId())
                .limit(pageSize);

        if (page > 1) {
            int docsToSkip = (page - 1) * pageSize;
            QuerySnapshot skipped = db.collection(COLLECTION)
                    .orderBy(FieldPath.documentId())
                    .limit(docsToSkip)
                    .get()
                    .get();

            if (!skipped.isEmpty()) {
                DocumentSnapshot lastDoc = skipped.getDocuments().get(skipped.size() - 1);
                query = query.startAfter(lastDoc);
            }
        }

        List<Camera> cameras = new ArrayList<>();
        QuerySnapshot querySnapshot = query.get().get();
        
        for (QueryDocumentSnapshot document : querySnapshot.getDocuments()) {
            Camera camera = document.toObject(Camera.class);
            camera.setId(document.getId());
            cameras.add(camera);
        }

        return cameras;
    }

    public Optional<Camera> getCameraById(String id) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        DocumentReference docRef = db.collection(COLLECTION).document(id);
        ApiFuture<DocumentSnapshot> future = docRef.get();
        DocumentSnapshot document = future.get();

        if (document.exists()) {
            Camera camera = document.toObject(Camera.class);
            camera.setId(document.getId());
            return Optional.of(camera);
        }

        return Optional.empty();
    }

    public void updateFields(String id, Map<String, Object> updates) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        db.collection(COLLECTION).document(id).update(updates).get();
    }

    public String save(Camera camera) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        ApiFuture<DocumentReference> future = db.collection(COLLECTION).add(camera);
        return future.get().getId();
    }

    public void delete(String id) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        db.collection(COLLECTION).document(id).delete().get();
    }

    public List<Camera> getCamerasByCategoryId(String categoryId) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        List<Camera> cameras = new ArrayList<>();

        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION)
                .whereArrayContains("categories", categoryId)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        for (QueryDocumentSnapshot document : documents) {
            Camera camera = document.toObject(Camera.class);
            camera.setId(document.getId());
            cameras.add(camera);
        }

        return cameras;
    }

    public void addCategoryToCamera(String cameraId, String categoryId) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        db.collection(COLLECTION).document(cameraId)
                .update("categories", FieldValue.arrayUnion(categoryId)).get();
    }

    public void removeCategoryFromCamera(String cameraId, String categoryId) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        db.collection(COLLECTION).document(cameraId)
                .update("categories", FieldValue.arrayRemove(categoryId)).get();
    }
}