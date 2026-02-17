package com.backendcam.backendcam.service.category;

import com.backendcam.backendcam.model.dto.CameraInfo;
import com.backendcam.backendcam.model.entity.CameraCategory;
import com.backendcam.backendcam.model.entity.Category;
import com.backendcam.backendcam.model.dto.CategoryStreamResponse;
import com.backendcam.backendcam.model.entity.RTSP;
import com.backendcam.backendcam.repository.CameraCategoryRepository;
import com.backendcam.backendcam.repository.CategoryRepository;
import com.backendcam.backendcam.repository.CameraRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ExecutionException;

@Service
@RequiredArgsConstructor
public class CategoryStreamService {

    private static final Logger logger = LoggerFactory.getLogger(CategoryStreamService.class);

    private final CategoryRepository categoryRepository;
    private final CameraCategoryRepository cameraCategoryRepository;
    private final CameraRepository cameraRepository;

    /**
     * 1. Find category by name
     * 2. Get all camera IDs in that category
     * 3. For each camera, fetch name from Firebase
     * 4. Return category name + list of camera id/name pairs
     */
    public CategoryStreamResponse getStreamsByCategory(String categoryName)
            throws ExecutionException, InterruptedException {

        // 1. Find category by name
        Category category = categoryRepository.findByName(categoryName);
        if (category == null) {
            throw new IllegalArgumentException("Category not found: " + categoryName);
        }

        // 2. Get all camera IDs assigned to this category
        List<CameraCategory> cameraMappings = cameraCategoryRepository.getCamerasByCategory(category.getId());

        // 3. Fetch camera name for each ID from Firebase
        List<CameraInfo> cameras = new ArrayList<>();
        for (CameraCategory mapping : cameraMappings) {
            String cameraId = mapping.getCameraId();
            try {
                Optional<RTSP> cameraOpt = cameraRepository.getCameraById(cameraId);
                String cameraName = cameraOpt.map(RTSP::getName).orElse("Unknown");
                cameras.add(new CameraInfo(cameraId, cameraName));
            } catch (Exception e) {
                logger.warn("Failed to fetch camera info for {}: {}", cameraId, e.getMessage());
                cameras.add(new CameraInfo(cameraId, "Unknown"));
            }
        }

        return new CategoryStreamResponse(categoryName, category.getId(), cameras);
    }
}
