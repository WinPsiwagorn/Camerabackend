package com.backendcam.backendcam.controller;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.backendcam.backendcam.model.dto.CameraInfo;
import com.backendcam.backendcam.model.entity.Category;
import com.backendcam.backendcam.model.entity.RTSP;
import com.backendcam.backendcam.repository.RTSPRepository;
import com.backendcam.backendcam.service.category.CategoryService;

@RestController
@RequestMapping("/category")
@CrossOrigin(origins = "*")
public class CategoryController {

    @Autowired
    private CategoryService categoryService;

    @Autowired
    private RTSPRepository rtspRepository;

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
            boolean deleted = categoryService.deleteCategory(id);
            if (!deleted) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok("Category deleted successfully");
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Failed to delete category: " + e.getMessage());
        }
    }

    // ==================== Camera-Category Management ====================

    /**
     * Add a category to a camera's categories array
     */
    @PostMapping("/camera")
    public ResponseEntity<?> addCategoryToCamera(@RequestBody Map<String, String> request) {
        try {
            String categoryId = request.get("categoryId");
            String cameraId = request.get("cameraId");
            if (categoryId == null || cameraId == null) {
                return ResponseEntity.badRequest().body("categoryId and cameraId are required");
            }
            rtspRepository.addCategoryToCamera(cameraId, categoryId);
            return ResponseEntity.ok(Map.of("message", "Category added to camera", "categoryId", categoryId, "cameraId", cameraId));
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Failed to add category to camera: " + e.getMessage());
        }
    }

    /**
     * Get all cameras in a category
     */
    @GetMapping("/{categoryId}/cameras")
    public ResponseEntity<?> getCamerasByCategory(@PathVariable String categoryId) {
        try {
            List<RTSP> cameras = rtspRepository.getCamerasByCategoryId(categoryId);
            List<CameraInfo> cameraInfos = cameras.stream()
                    .map(cam -> new CameraInfo(cam.getId(), cam.getName()))
                    .toList();
            return ResponseEntity.ok(cameraInfos);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Failed to fetch cameras: " + e.getMessage());
        }
    }

    /**
     * Remove a category from a camera's categories array
     */
    @DeleteMapping("/{categoryId}/camera/{cameraId}")
    public ResponseEntity<?> removeCategoryFromCamera(
            @PathVariable String categoryId,
            @PathVariable String cameraId) {
        try {
            rtspRepository.removeCategoryFromCamera(cameraId, categoryId);
            return ResponseEntity.ok("Category removed from camera successfully");
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Failed to remove category from camera: " + e.getMessage());
        }
    }
}
