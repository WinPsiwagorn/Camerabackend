package com.backendcam.backendcam.service.category;

import com.backendcam.backendcam.model.dto.CameraInfo;
import com.backendcam.backendcam.model.entity.Category;
import com.backendcam.backendcam.model.dto.CategoryStreamResponse;
import com.backendcam.backendcam.model.entity.RTSP;
import com.backendcam.backendcam.repository.CategoryRepository;
import com.backendcam.backendcam.repository.RTSPRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CategoryStreamService {

    private static final Logger logger = LoggerFactory.getLogger(CategoryStreamService.class);

    private final CategoryRepository categoryRepository;
    private final RTSPRepository rtspRepository;

    /**
     * 1. Find category by name
     * 2. Query all cameras that have this category ID in their categories array
     * 3. Return category name + list of camera id/name pairs
     */
    public CategoryStreamResponse getStreamsByCategory(String categoryName)
            throws ExecutionException, InterruptedException {

        // 1. Find category by name
        Category category = categoryRepository.findByName(categoryName);
        if (category == null) {
            throw new IllegalArgumentException("Category not found: " + categoryName);
        }

        // 2. Query cameras that have this category in their categories array
        List<RTSP> cameras = rtspRepository.getCamerasByCategoryId(category.getId());

        // 3. Map to CameraInfo (id + name)
        List<CameraInfo> cameraInfos = cameras.stream()
                .map(cam -> new CameraInfo(cam.getId(), cam.getName()))
                .collect(Collectors.toList());

        return new CategoryStreamResponse(categoryName, category.getId(), cameraInfos);
    }
}
