package com.backendcam.backendcam.repository;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ExecutionException;

import org.springframework.stereotype.Repository;

import com.backendcam.backendcam.model.entity.Category;
import com.backendcam.backendcam.service.firestore.FirebaseAdminBootstrap;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
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

    public String createCategory(Category category) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        ApiFuture<DocumentReference> future = db.collection(COLLECTION).add(category);
        return future.get().getId();
    }

    public Optional<Category> getCategoryById(String id) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        DocumentReference docRef = db.collection(COLLECTION).document(id);
        ApiFuture<DocumentSnapshot> future = docRef.get();
        DocumentSnapshot document = future.get();

        if (document.exists()) {
            Category category = document.toObject(Category.class);
            category.setId(document.getId());
            return Optional.of(category);
        }

        return Optional.empty();
    }

    public List<Category> getAllCategories() throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION).get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        List<Category> categories = new ArrayList<>();
        for (QueryDocumentSnapshot doc : documents) {
            Category category = doc.toObject(Category.class);
            category.setId(doc.getId());
            categories.add(category);
        }
        return categories;
    }

    public long getTotalCount() throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        ApiFuture<QuerySnapshot> future = db.collection(COLLECTION).get();
        return future.get().size();
    }

    public List<Category> getCategoriesByPage(int page, int limit) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        
        Query query = db.collection(COLLECTION);
        
        if (limit > 0) {
            int offset = (page - 1) * limit;
            query = query.limit(limit).offset(offset);
        }

        ApiFuture<QuerySnapshot> future = query.get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        List<Category> categories = new ArrayList<>();
        
        for (QueryDocumentSnapshot doc : documents) {
            Category category = doc.toObject(Category.class);
            category.setId(doc.getId());
            categories.add(category);
        }
        
        return categories;
    }

    public Category updateCategory(String id, Map<String, Object> updates) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        DocumentReference docRef = db.collection(COLLECTION).document(id);

        // Check if document exists
        DocumentSnapshot snapshot = docRef.get().get();
        if (!snapshot.exists()) {
            throw new java.util.NoSuchElementException("Category not found with id: " + id);
        }

        docRef.update(updates).get();

        // Fetch and return the updated document
        DocumentSnapshot updatedSnapshot = docRef.get().get();
        Category category = updatedSnapshot.toObject(Category.class);
        category.setId(updatedSnapshot.getId());
        return category;
    }

    public boolean deleteCategory(String id) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        db.collection(COLLECTION).document(id).delete().get();
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
        category.setId(doc.getId());
        category.setName(doc.getString("name"));
        return category;
    }

    /**
     * Batch-fetch multiple categories by their IDs in a single Firestore round trip.
     * This is the official Firestore equivalent of MongoDB's populate/$in.
     */
    public List<Category> getCategoriesByIds(List<String> ids) throws ExecutionException, InterruptedException {
        if (ids == null || ids.isEmpty()) {
            return new ArrayList<>();
        }

        Firestore db = getFirestore();

        // Build DocumentReferences for all IDs
        DocumentReference[] refs = ids.stream()
                .map(id -> db.collection(COLLECTION).document(id))
                .toArray(DocumentReference[]::new);

        // getAll() fetches all docs in ONE round trip — the official Firestore batch-get API
        List<DocumentSnapshot> snapshots = db.getAll(refs).get();

        List<Category> categories = new ArrayList<>();
        for (DocumentSnapshot snapshot : snapshots) {
            if (snapshot.exists()) {
                Category category = snapshot.toObject(Category.class);
                category.setId(snapshot.getId());
                categories.add(category);
            }
        }
        return categories;
    }
}
