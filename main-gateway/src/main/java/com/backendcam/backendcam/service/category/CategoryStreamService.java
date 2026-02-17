package com.backendcam.backendcam.service.category;

import com.backendcam.backendcam.model.entity.CameraCategory;
import com.backendcam.backendcam.model.dto.CameraHlsInfo;
import com.backendcam.backendcam.model.entity.Category;
import com.backendcam.backendcam.model.dto.CategoryStreamResponse;
import com.backendcam.backendcam.model.entity.RTSP;
import com.backendcam.backendcam.repository.CameraCategoryRepository;
import com.backendcam.backendcam.repository.CategoryRepository;
import com.backendcam.backendcam.repository.RTSPRepository;
import com.backendcam.backendcam.service.hls.HLSStreamService;
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
    private final RTSPRepository rtspRepository;
    private final HLSStreamService hlsStreamService;

    /**
     * 1. Find category by name
     * 2. Get all camera IDs in that category
     * 3. For each camera, get RTSP link and start HLS stream
     * 4. Return category name + list of camera names & HLS URLs
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

        // 3. For each camera, get RTSP info and start HLS
        List<CameraHlsInfo> cameraHlsList = new ArrayList<>();

        for (CameraCategory mapping : cameraMappings) {
            String cameraId = mapping.getCameraId();

            try {
                // Camera ID is the document ID in the cameras collection
                Optional<RTSP> cameraOpt = rtspRepository.getCameraById(cameraId);

                if (cameraOpt.isEmpty()) {
                    logger.warn("Camera not found for id: {}", cameraId);
                    continue;
                }

                RTSP camera = cameraOpt.get();

                if (camera.getRtspUrl() == null || camera.getRtspUrl().isBlank()) {
                    logger.warn("No RTSP URL for camera: {} ({})", camera.getName(), cameraId);
                    continue;
                }

                // Sanitize stream name (use camera ID as unique stream key)
                String streamName = cameraId.replaceAll("[^a-zA-Z0-9_-]", "_");

                // Start HLS stream (returns existing URL if already running)
                String hlsUrl = hlsStreamService.startHLSStream(camera.getRtspUrl(), streamName);

                cameraHlsList.add(new CameraHlsInfo(cameraId, camera.getName(), hlsUrl));

            } catch (Exception e) {
                logger.error("Failed to start stream for camera {}: {}", cameraId, e.getMessage());
            }
        }

        return new CategoryStreamResponse(categoryName, category.getId(), cameraHlsList);
    }
}
