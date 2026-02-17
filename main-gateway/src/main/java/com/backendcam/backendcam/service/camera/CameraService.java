package com.backendcam.backendcam.service.camera;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.backendcam.backendcam.model.dto.camera.CameraResponseDto;
import com.backendcam.backendcam.model.dto.camera.CreateCameraDto;
import com.backendcam.backendcam.model.entity.Camera;
import com.backendcam.backendcam.repository.CameraRepository;
import com.google.cloud.firestore.GeoPoint;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class CameraService {

    private final CameraRepository cameraRepository;

    public CameraResponseDto createCamera(CreateCameraDto createDto) {
        try {
            Camera camera = new Camera();
            camera.setName(createDto.getName());
            camera.setAddress(createDto.getAddress());
            camera.setRtspUrl(createDto.getRtspUrl());
            
            if (createDto.getLatLong() != null && !createDto.getLatLong().isBlank()) {
                String[] coords = createDto.getLatLong().split(",");
                if (coords.length == 2) {
                    double lat = Double.parseDouble(coords[0].trim());
                    double lon = Double.parseDouble(coords[1].trim());
                    camera.setLatLong(new GeoPoint(lat, lon));
                }
            }

            String id = cameraRepository.save(camera);
            camera.setId(id);
            return toDto(camera);
        } catch (Exception e) {
            throw new RuntimeException("Failed to create camera", e);
        }
    }

    public List<CameraResponseDto> getCamerasByPage(int page, int pageSize) {
        try {
            List<Camera> cameras = cameraRepository.getCamerasByPage(page, pageSize);
            return cameras.stream()
                    .map(this::toDto)
                    .collect(Collectors.toList());
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

    public void updateCamera(String id, Map<String, Object> updates) {
        try {
            cameraRepository.updateFields(id, updates);
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

    private CameraResponseDto toDto(Camera camera) {
        CameraResponseDto dto = new CameraResponseDto();
        dto.setId(camera.getId());
        dto.setName(camera.getName());
        
        if (camera.getLatLong() != null) {
            dto.setLatLong(camera.getLatLong().getLatitude() + "," + camera.getLatLong().getLongitude());
        }
        
        dto.setAddress(camera.getAddress());
        dto.setStatus(camera.getStatus());
        dto.setCategories(camera.getCategories());

        if (camera.getLastSeen() != null) {
            CameraResponseDto.LastSeen lastSeenDto = new CameraResponseDto.LastSeen();
            lastSeenDto.setMessage(camera.getLastSeen().getMessage());
            lastSeenDto.setTimestamp(camera.getLastSeen().getTimestamp());
            dto.setLastSeen(lastSeenDto);
        }

        return dto;
    }
}


