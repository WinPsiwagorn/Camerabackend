package com.backendcam.backendcam.controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.backendcam.backendcam.model.dto.MessageResponseDTO;
import com.backendcam.backendcam.model.dto.PageResponse;
import com.backendcam.backendcam.model.dto.camera.CameraResponseDto;
import com.backendcam.backendcam.model.dto.category.AddCategoryDto;
import com.backendcam.backendcam.model.dto.category.CategoryCreateDTO;
import com.backendcam.backendcam.model.dto.category.CategoryResponseDTO;
import com.backendcam.backendcam.service.camera.CameraService;
import com.backendcam.backendcam.service.category.CategoryService;

import jakarta.validation.Valid;
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
        @RequestParam(defaultValue = "10") int limit
    ) {
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
    public ResponseEntity<CategoryResponseDTO> updateCategory(
        @PathVariable String id, 
        @RequestBody Map<String, Object> updates
    ) {
        return categoryService.updateCategory(id, updates)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<MessageResponseDTO> deleteCategory(@PathVariable String id) {
        categoryService.deleteCategory(id);
        return ResponseEntity.ok(new MessageResponseDTO("Category ID: " + id + " deleted successfully"));
    }

    // ==================== Camera-Category Management ====================

    /**
     * Add a category to a camera's categories array
     */
    @PostMapping("/{categoryId}/cameras")
    public ResponseEntity<CameraResponseDto> addCategoryToCamera(
        @PathVariable String categoryId,
        @Valid @RequestBody AddCategoryDto dto
    ) {
        String cameraId = dto.getCameraId();
        return cameraService.addCategoryToCamera(cameraId, categoryId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Get all cameras in a category by category ID
     */
    @GetMapping("/{categoryId}/cameras")
    public ResponseEntity<List<CameraResponseDto>> getCamerasByCategory(@PathVariable String categoryId) {
        return cameraService.getCamerasByCategoryId(categoryId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Remove a category from a camera's categories array
     */
    @DeleteMapping("/{categoryId}/cameras/{cameraId}")
    public ResponseEntity<MessageResponseDTO> removeCategoryFromCamera(
        @PathVariable String categoryId,
        @PathVariable String cameraId
    ) {
        cameraService.removeCategoryFromCamera(cameraId, categoryId);
        return ResponseEntity.ok(new MessageResponseDTO("Category removed from camera successfully"));
    }
}
