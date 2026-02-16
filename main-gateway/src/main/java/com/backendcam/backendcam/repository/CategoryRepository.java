package com.backendcam.backendcam.repository;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

import org.springframework.stereotype.Repository;

import com.backendcam.backendcam.model.entity.Category;
import com.backendcam.backendcam.service.firestore.FirebaseAdminBootstrap;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.firebase.cloud.FirestoreClient;

import lombok.RequiredArgsConstructor;

@Repository
@RequiredArgsConstructor
public class CategoryRepository {

    private static final String COLLECTION = "categories";
    private final FirebaseAdminBootstrap bootstrap;

    private Firestore getFirestore() {
        if (!bootstrap.isInitialized()) {
            throw new IllegalStateException("Firebase is not initialized");
        }
        return FirestoreClient.getFirestore();
    }

    public Category createCategory(Category category) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();

        Map<String, Object> data = new HashMap<>();
        data.put("name", category.getName());

        DocumentReference docRef = db.collection(COLLECTION).document();
        docRef.set(data).get();

        category.setId(docRef.getId().hashCode());
        return category;
    }

    public Category createCategoryWithId(Category category) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();

        Map<String, Object> data = new HashMap<>();
        data.put("id", category.getId());
        data.put("name", category.getName());

        String docId = String.valueOf(category.getId());
        db.collection(COLLECTION).document(docId).set(data).get();

        return category;
    }

    public Category getCategoryById(int id) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        DocumentSnapshot doc = db.collection(COLLECTION).document(String.valueOf(id)).get().get();

        if (!doc.exists()) {
            return null;
        }

        Category category = new Category();
        category.setId(id);
        category.setName(doc.getString("name"));
        return category;
    }

    public List<Category> getAllCategories() throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION).get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        List<Category> categories = new ArrayList<>();
        for (QueryDocumentSnapshot doc : documents) {
            Category category = new Category();
            Long idVal = doc.getLong("id");
            category.setId(idVal != null ? idVal.intValue() : doc.getId().hashCode());
            category.setName(doc.getString("name"));
            categories.add(category);
        }
        return categories;
    }

    public Category updateCategory(int id, Category category) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        String docId = String.valueOf(id);
        DocumentSnapshot doc = db.collection(COLLECTION).document(docId).get().get();

        if (!doc.exists()) {
            return null;
        }

        Map<String, Object> data = new HashMap<>();
        data.put("id", id);
        data.put("name", category.getName());

        db.collection(COLLECTION).document(docId).set(data).get();

        category.setId(id);
        return category;
    }

    public boolean deleteCategory(int id) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        String docId = String.valueOf(id);
        DocumentSnapshot doc = db.collection(COLLECTION).document(docId).get().get();

        if (!doc.exists()) {
            return false;
        }

        db.collection(COLLECTION).document(docId).delete().get();
        return true;
    }

    /**
     * Find a category by its name
     */
    public Category findByName(String name) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION)
                .whereEqualTo("name", name)
                .limit(1)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        if (documents.isEmpty()) {
            return null;
        }

        QueryDocumentSnapshot doc = documents.get(0);
        Category category = new Category();
        Long idVal = doc.getLong("id");
        category.setId(idVal != null ? idVal.intValue() : doc.getId().hashCode());
        category.setName(doc.getString("name"));
        return category;
    }
}
