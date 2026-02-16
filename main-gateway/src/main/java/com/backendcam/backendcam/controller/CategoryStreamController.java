package com.backendcam.backendcam.controller;

import com.backendcam.backendcam.model.dto.CategoryStreamResponse;
import com.backendcam.backendcam.service.category.CategoryStreamService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/stream/category")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class CategoryStreamController {

    private final CategoryStreamService categoryStreamService;

    /**
     * GET /api/stream/category?name=CategoryName
     * Returns the category info with HLS URLs for all cameras in that category.
     */
    @GetMapping
    public ResponseEntity<?> getStreamsByCategory(@RequestParam String name) {
        try {
            CategoryStreamResponse response = categoryStreamService.getStreamsByCategory(name);

            if (response.getCameras().isEmpty()) {
                return ResponseEntity.ok(Map.of(
                        "categoryName", response.getCategoryName(),
                        "categoryId", response.getCategoryId(),
                        "message", "No cameras found or no streams available for this category"
                ));
            }

            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to get streams: " + e.getMessage()));
        }
    }
}
