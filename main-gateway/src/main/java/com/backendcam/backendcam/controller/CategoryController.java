package com.backendcam.backendcam.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.backendcam.backendcam.model.entity.CameraCategory;
import com.backendcam.backendcam.model.entity.Category;
import com.backendcam.backendcam.service.category.CameraCategoryService;
import com.backendcam.backendcam.service.category.CategoryService;

@RestController
@RequestMapping("/category")
@CrossOrigin(origins = "*")
public class CategoryController {

    @Autowired
    private CategoryService categoryService;

    @Autowired
    private CameraCategoryService cameraCategoryService;

    // ==================== Category CRUD ====================

    @PostMapping
    public ResponseEntity<?> createCategory(@RequestBody Category category) {
        try {
            Category created = categoryService.createCategoryWithId(category);
            return ResponseEntity.ok(created);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Failed to create category: " + e.getMessage());
        }
    }

    @GetMapping
    public ResponseEntity<?> getAllCategories() {
        try {
            List<Category> categories = categoryService.getAllCategories();
            return ResponseEntity.ok(categories);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Failed to fetch categories: " + e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getCategoryById(@PathVariable String id) {
        try {
            Category category = categoryService.getCategoryById(id);
            if (category == null) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok(category);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Failed to fetch category: " + e.getMessage());
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateCategory(@PathVariable String id, @RequestBody Category category) {
        try {
            Category updated = categoryService.updateCategory(id, category);
            if (updated == null) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok(updated);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Failed to update category: " + e.getMessage());
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteCategory(@PathVariable String id) {
        try {
            // Also remove all camera-category mappings for this category
            cameraCategoryService.deleteAllByCategory(id);

            boolean deleted = categoryService.deleteCategory(id);
            if (!deleted) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok("Category deleted successfully");
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Failed to delete category: " + e.getMessage());
        }
    }

    // ==================== CameraCategory CRUD ====================

    @PostMapping("/camera")
    public ResponseEntity<?> addCameraToCategory(@RequestBody CameraCategory cameraCategory) {
        try {
            CameraCategory created = cameraCategoryService.addCameraToCategory(cameraCategory);
            return ResponseEntity.ok(created);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Failed to add camera to category: " + e.getMessage());
        }
    }

    @GetMapping("/camera")
    public ResponseEntity<?> getAllCameraCategories() {
        try {
            List<CameraCategory> all = cameraCategoryService.getAll();
            return ResponseEntity.ok(all);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Failed to fetch camera categories: " + e.getMessage());
        }
    }

    @GetMapping("/{categoryId}/cameras")
    public ResponseEntity<?> getCamerasByCategory(@PathVariable String categoryId) {
        try {
            List<CameraCategory> cameras = cameraCategoryService.getCamerasByCategory(categoryId);
            return ResponseEntity.ok(cameras);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Failed to fetch cameras: " + e.getMessage());
        }
    }

    @GetMapping("/camera/{cameraId}")
    public ResponseEntity<?> getCategoriesByCamera(@PathVariable String cameraId) {
        try {
            List<CameraCategory> categories = cameraCategoryService.getCategoriesByCamera(cameraId);
            return ResponseEntity.ok(categories);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Failed to fetch categories for camera: " + e.getMessage());
        }
    }

    @DeleteMapping("/{categoryId}/camera/{cameraId}")
    public ResponseEntity<?> removeCameraFromCategory(
            @PathVariable String categoryId,
            @PathVariable String cameraId) {
        try {
            boolean removed = cameraCategoryService.removeCameraFromCategory(categoryId, cameraId);
            if (!removed) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok("Camera removed from category successfully");
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Failed to remove camera from category: " + e.getMessage());
        }
    }
}
