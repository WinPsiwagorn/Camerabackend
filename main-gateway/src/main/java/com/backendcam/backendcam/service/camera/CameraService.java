package com.backendcam.backendcam.service.camera;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;

import com.backendcam.backendcam.exception.InvalidGeoPointException;
import com.backendcam.backendcam.model.dto.PageResponse;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.backendcam.backendcam.model.dto.camera.CameraMapResponseDto;
import com.backendcam.backendcam.model.dto.camera.CameraResponseDto;
import com.backendcam.backendcam.model.dto.camera.CameraTotalResponseDto;
import com.backendcam.backendcam.model.dto.camera.CreateCameraDto;
import com.backendcam.backendcam.model.dto.camera.UpdateCameraDto;
import com.backendcam.backendcam.model.dto.category.CategoryResponseDTO;
import com.backendcam.backendcam.model.entity.Camera;
import com.backendcam.backendcam.repository.CameraRepository;
import com.backendcam.backendcam.repository.CategoryRepository;
import com.backendcam.backendcam.util.PaginationUtil;
import com.google.cloud.firestore.GeoPoint;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class CameraService {

    private final CameraRepository cameraRepository;
    private final CategoryRepository categoryRepository;
    private final ObjectMapper objectMapper;

    public CameraResponseDto createCamera(CreateCameraDto createDto) {
        try {
            Camera camera = new Camera();
            camera.setName(createDto.getName());
            camera.setAddress(createDto.getAddress());
            camera.setRtspUrl(createDto.getRtspUrl());

            if (createDto.getLatLong() != null && !createDto.getLatLong().isBlank()) {
                camera.setLatLong(parseGeoPoint(createDto.getLatLong()));
            }

            String id = cameraRepository.save(camera);
            camera.setId(id);
            return toDto(camera);
        } catch (Exception e) {
            throw new RuntimeException("Failed to create camera", e);
        }
    }

    public PageResponse<List<CameraResponseDto>> getCamerasByPage(int page, int limit) {
        try {
            List<Camera> cameras = cameraRepository.getCamerasByPage(page, limit);
            long totalItems = cameraRepository.getTotalCount();
            List<CameraResponseDto> dtos = toDtoList(cameras);
            return PaginationUtil.createPaginationResponse(dtos, totalItems, page, limit, Function.identity());
        } catch (Exception e) {
            throw new RuntimeException("Failed to get cameras", e);
        }
    }

    public Optional<CameraResponseDto> getCameraById(String id) {
        try {
            return cameraRepository.getCameraById(id)
                    .map(this::toDto);
        } catch (Exception e) {
            throw new RuntimeException("Failed to get camera by id: " + id, e);
        }
    }

    public Optional<CameraResponseDto> updateCamera(String id, UpdateCameraDto updateDto) {
        try {
            Map<String, Object> updates = objectMapper.convertValue(updateDto, new TypeReference<Map<String, Object>>() {});

            if (updates.containsKey("latLong"))
                updates.put("latLong", parseGeoPoint((String) updates.get("latLong")));

            if (updates.isEmpty()) {
                return getCameraById(id);
            }

            Camera updatedCamera = cameraRepository.updateFields(id, updates);
            return Optional.of(toDto(updatedCamera));
        } catch (java.util.NoSuchElementException e) {
            return Optional.empty();
        } catch (Exception e) {
            throw new RuntimeException("Failed to update camera: " + id, e);
        }
    }

    public void deleteCamera(String id) {
        try {
            cameraRepository.delete(id);
        } catch (Exception e) {
            throw new RuntimeException("Failed to delete camera: " + id, e);
        }
    }

    public Optional<List<CameraResponseDto>> getCamerasByCategoryId(String categoryId) {
        try {
            return cameraRepository.getCamerasByCategoryId(categoryId)
                    .map(this::toDtoList);
        } catch (Exception e) {
            throw new RuntimeException("Failed to get cameras by category ID: " + categoryId, e);
        }
    }

    public Optional<CameraResponseDto> addCategoryToCamera(String cameraId, String categoryId) {
        try {
            Camera updatedCamera = cameraRepository.addCategoryToCamera(cameraId, categoryId);
            return Optional.of(toDto(updatedCamera));
        } catch (java.util.NoSuchElementException e) {
            return Optional.empty();
        } catch (Exception e) {
            throw new RuntimeException("Failed to add category to camera: " + cameraId, e);
        }
    }

    public void removeCategoryFromCamera(String cameraId, String categoryId) {
        try {
            cameraRepository.removeCategoryFromCamera(cameraId, categoryId);
        } catch (Exception e) {
            throw new RuntimeException("Failed to remove category from camera: " + cameraId, e);
        }
    }

    public List<CameraMapResponseDto> getCamerasForMap() {
        try {
            List<Camera> cameras = cameraRepository.getAllCameras();
            return cameras.stream()
                    .map(this::toMapDto)
                    .collect(Collectors.toList());
        } catch (Exception e) {
            throw new RuntimeException("Failed to get cameras for map", e);
        }
    }

    public CameraTotalResponseDto getCameraTotal() {
        try {
            long total = cameraRepository.getTotalCount();
            long online = cameraRepository.countByStatus("online");
            long offline = cameraRepository.countByStatus("offline");
            return new CameraTotalResponseDto(total, online, offline);
        } catch (Exception e) {
            throw new RuntimeException("Failed to get camera totals", e);
        }
    }

    /**
     * Batch-optimized list mapping — O(1) Firestore round trips regardless of list size.
     * 1. Collect all unique category IDs across all cameras  → Set<String>
     * 2. Fetch them all in ONE getAll() call                 → Map<id, CategoryResponseDTO>
     * 3. Map each camera using the pre-built lookup map      → no extra I/O per camera
     */
    private List<CameraResponseDto> toDtoList(List<Camera> cameras) {
        // Step 1 — collect unique category IDs across all cameras
        Set<String> uniqueCategoryIds = cameras.stream()
                .filter(c -> c.getCategories() != null)
                .flatMap(c -> c.getCategories().stream())
                .collect(Collectors.toSet());

        // Step 2 — ONE batch fetch for all unique IDs
        Map<String, CategoryResponseDTO> categoryMap = new HashMap<>();
        if (!uniqueCategoryIds.isEmpty()) {
            try {
                categoryRepository.getCategoriesByIds(new ArrayList<>(uniqueCategoryIds))
                        .forEach(cat -> categoryMap.put(cat.getId(),
                                new CategoryResponseDTO(cat.getId(), cat.getName())));
            } catch (Exception ignored) {}
        }

        // Step 3 — map each camera using the lookup map (no I/O)
        return cameras.stream()
                .map(camera -> toDto(camera, categoryMap))
                .collect(Collectors.toList());
    }

    private GeoPoint parseGeoPoint(String latLong) {
        try {
            String[] coords = latLong.split(",");
            if (coords.length != 2) throw new IllegalArgumentException();
            return new GeoPoint(
                Double.parseDouble(coords[0].trim()),
                Double.parseDouble(coords[1].trim())
            );
        } catch (Exception e) {
            throw new InvalidGeoPointException(latLong);
        }
    }

    private CameraResponseDto toDto(Camera camera) {
        // For single-camera calls — fetch only this camera's categories
        Map<String, CategoryResponseDTO> categoryMap = new HashMap<>();
        List<String> ids = camera.getCategories();
        if (ids != null && !ids.isEmpty()) {
            try {
                categoryRepository.getCategoriesByIds(ids)
                        .forEach(cat -> categoryMap.put(cat.getId(),
                                new CategoryResponseDTO(cat.getId(), cat.getName())));
            } catch (Exception ignored) {}
        }
        return toDto(camera, categoryMap);
    }

    private CameraResponseDto toDto(Camera camera, Map<String, CategoryResponseDTO> categoryMap) {
        CameraResponseDto dto = new CameraResponseDto();
        dto.setId(camera.getId());
        dto.setName(camera.getName());

        if (camera.getLatLong() != null) {
            dto.setLatLong(camera.getLatLong().getLatitude() + "," + camera.getLatLong().getLongitude());
        }

        dto.setAddress(camera.getAddress());
        dto.setStatus(camera.getStatus());

        List<String> categoryIds = camera.getCategories();
        if (categoryIds != null && !categoryIds.isEmpty()) {
            List<CategoryResponseDTO> categories = categoryIds.stream()
                    .map(categoryMap::get)
                    .filter(cat -> cat != null)
                    .collect(Collectors.toList());
            dto.setCategories(categories);
        } else {
            dto.setCategories(new ArrayList<>());
        }

        if (camera.getLastSeen() != null) {
            CameraResponseDto.LastSeen lastSeenDto = new CameraResponseDto.LastSeen();
            lastSeenDto.setTimestamp(camera.getLastSeen().getTimestamp());
            dto.setLastSeen(lastSeenDto);
        }

        return dto;
    }

    private CameraMapResponseDto toMapDto(Camera camera) {
        CameraMapResponseDto dto = new CameraMapResponseDto();
        dto.setId(camera.getId());
        dto.setName(camera.getName());
        
        if (camera.getLatLong() != null) {
            dto.setLatLong(camera.getLatLong().getLatitude() + "," + camera.getLatLong().getLongitude());
        }

        dto.setStatus(camera.getStatus());
        
        return dto;
    }
}


