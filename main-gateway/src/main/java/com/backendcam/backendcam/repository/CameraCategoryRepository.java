package com.backendcam.backendcam.repository;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

import org.springframework.stereotype.Repository;

import com.backendcam.backendcam.model.entity.CameraCategory;
import com.backendcam.backendcam.service.firestore.FirebaseAdminBootstrap;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.firebase.cloud.FirestoreClient;

import lombok.RequiredArgsConstructor;

@Repository
@RequiredArgsConstructor
public class CameraCategoryRepository {

    private static final String COLLECTION = "cameraCategories";
    private final FirebaseAdminBootstrap bootstrap;

    private Firestore getFirestore() {
        if (!bootstrap.isInitialized()) {
            throw new IllegalStateException("Firebase is not initialized");
        }
        return FirestoreClient.getFirestore();
    }

    /**
     * Assign a camera to a category
     */
    public CameraCategory addCameraToCategory(CameraCategory cameraCategory)
            throws ExecutionException, InterruptedException {

        Firestore db = getFirestore();

        // Use a composite key: categoryId_cameraId
        String docId = cameraCategory.getCategoryId() + "_" + cameraCategory.getCameraId();

        Map<String, Object> data = new HashMap<>();
        data.put("categoryId", cameraCategory.getCategoryId());
        data.put("cameraId", cameraCategory.getCameraId());

        db.collection(COLLECTION).document(docId).set(data).get();
        return cameraCategory;
    }

    /**
     * Remove a camera from a category
     */
    public boolean removeCameraFromCategory(int categoryId, String cameraId)
            throws ExecutionException, InterruptedException {

        Firestore db = getFirestore();
        String docId = categoryId + "_" + cameraId;

        DocumentSnapshot doc = db.collection(COLLECTION).document(docId).get().get();
        if (!doc.exists()) {
            return false;
        }

        db.collection(COLLECTION).document(docId).delete().get();
        return true;
    }

    /**
     * Get all camera-category mappings
     */
    public List<CameraCategory> getAll() throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION).get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        List<CameraCategory> result = new ArrayList<>();
        for (QueryDocumentSnapshot doc : documents) {
            CameraCategory cc = new CameraCategory();
            Long catId = doc.getLong("categoryId");
            cc.setCategoryId(catId != null ? catId.intValue() : 0);
            cc.setCameraId(doc.getString("cameraId"));
            result.add(cc);
        }
        return result;
    }

    /**
     * Get all cameras belonging to a specific category
     */
    public List<CameraCategory> getCamerasByCategory(int categoryId)
            throws ExecutionException, InterruptedException {

        Firestore db = getFirestore();
        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION)
                .whereEqualTo("categoryId", categoryId)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        List<CameraCategory> result = new ArrayList<>();
        for (QueryDocumentSnapshot doc : documents) {
            CameraCategory cc = new CameraCategory();
            Long catId = doc.getLong("categoryId");
            cc.setCategoryId(catId != null ? catId.intValue() : 0);
            cc.setCameraId(doc.getString("cameraId"));
            result.add(cc);
        }
        return result;
    }

    /**
     * Get all categories for a specific camera
     */
    public List<CameraCategory> getCategoriesByCamera(String cameraId)
            throws ExecutionException, InterruptedException {

        Firestore db = getFirestore();
        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION)
                .whereEqualTo("cameraId", cameraId)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        List<CameraCategory> result = new ArrayList<>();
        for (QueryDocumentSnapshot doc : documents) {
            CameraCategory cc = new CameraCategory();
            Long catId = doc.getLong("categoryId");
            cc.setCategoryId(catId != null ? catId.intValue() : 0);
            cc.setCameraId(doc.getString("cameraId"));
            result.add(cc);
        }
        return result;
    }

    /**
     * Delete all camera-category mappings for a given category
     */
    public void deleteAllByCategory(int categoryId) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        List<QueryDocumentSnapshot> docs = db.collection(COLLECTION)
                .whereEqualTo("categoryId", categoryId)
                .get().get().getDocuments();

        for (QueryDocumentSnapshot doc : docs) {
            doc.getReference().delete().get();
        }
    }
}
