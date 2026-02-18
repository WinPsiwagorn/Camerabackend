package com.backendcam.backendcam.controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.backendcam.backendcam.model.dto.CameraInfo;
import com.backendcam.backendcam.model.dto.PageResponse;
import com.backendcam.backendcam.model.dto.camera.CameraResponseDto;
import com.backendcam.backendcam.model.dto.category.CategoryCreateDTO;
import com.backendcam.backendcam.model.dto.category.CategoryResponseDTO;
import com.backendcam.backendcam.service.camera.CameraService;
import com.backendcam.backendcam.service.category.CategoryService;

import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/category")
public class CategoryController {

    private final CategoryService categoryService;
    private final CameraService cameraService;

    // ==================== Category CRUD ====================

    @PostMapping
    public ResponseEntity<CategoryResponseDTO> createCategory(@RequestBody CategoryCreateDTO categoryDto) {
        CategoryResponseDTO created = categoryService.createCategory(categoryDto);
        return ResponseEntity.ok(created);
    }

    @GetMapping
    public ResponseEntity<PageResponse<List<CategoryResponseDTO>>> getCategories(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int limit) {
        PageResponse<List<CategoryResponseDTO>> response = categoryService.getCategoriesByPage(page, limit);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/all")
    public ResponseEntity<List<CategoryResponseDTO>> getAllCategories() {
        List<CategoryResponseDTO> categories = categoryService.getAllCategories();
        return ResponseEntity.ok(categories);
    }

    @GetMapping("/{id}")
    public ResponseEntity<CategoryResponseDTO> getCategoryById(@PathVariable String id) {
        return categoryService.getCategoryById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/{id}")
    public ResponseEntity<Void> updateCategory(@PathVariable String id, @RequestBody Map<String, Object> updates) {
        categoryService.updateCategory(id, updates);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCategory(@PathVariable String id) {
        categoryService.deleteCategory(id);
        return ResponseEntity.ok().build();
    }

    // ==================== Camera-Category Management ====================

    /**
     * Add a category to a camera's categories array
     */
    @PostMapping("/{categoryId}/cameras")
    public ResponseEntity<?> addCategoryToCamera(@PathVariable String categoryId, @RequestBody Map<String, String> request) {
        try {
            String cameraId = request.get("cameraId");
            if (cameraId == null) {
                return ResponseEntity.badRequest().body("cameraId is required");
            }
            cameraService.addCategoryToCamera(cameraId, categoryId);
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
            List<CameraResponseDto> cameras = cameraService.getCamerasByCategoryId(categoryId);
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
    @DeleteMapping("/{categoryId}/cameras/{cameraId}")
    public ResponseEntity<?> removeCategoryFromCamera(
            @PathVariable String categoryId,
            @PathVariable String cameraId) {
        try {
            cameraService.removeCategoryFromCamera(cameraId, categoryId);
            return ResponseEntity.ok("Category removed from camera successfully");
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Failed to remove category from camera: " + e.getMessage());
        }
    }
}
