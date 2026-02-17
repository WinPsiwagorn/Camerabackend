package com.backendcam.backendcam.service.category;

import java.util.List;
import java.util.concurrent.ExecutionException;

import org.springframework.stereotype.Service;

import com.backendcam.backendcam.model.entity.CameraCategory;
import com.backendcam.backendcam.repository.CameraCategoryRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class CameraCategoryService {

    private final CameraCategoryRepository cameraCategoryRepository;

    public CameraCategory addCameraToCategory(CameraCategory cameraCategory)
            throws ExecutionException, InterruptedException {
        return cameraCategoryRepository.addCameraToCategory(cameraCategory);
    }

    public boolean removeCameraFromCategory(String categoryId, String cameraId)
            throws ExecutionException, InterruptedException {
        return cameraCategoryRepository.removeCameraFromCategory(categoryId, cameraId);
    }

    public List<CameraCategory> getAll() throws ExecutionException, InterruptedException {
        return cameraCategoryRepository.getAll();
    }

    public List<CameraCategory> getCamerasByCategory(String categoryId)
            throws ExecutionException, InterruptedException {
        return cameraCategoryRepository.getCamerasByCategory(categoryId);
    }

    public List<CameraCategory> getCategoriesByCamera(String cameraId)
            throws ExecutionException, InterruptedException {
        return cameraCategoryRepository.getCategoriesByCamera(cameraId);
    }

    public void deleteAllByCategory(String categoryId) throws ExecutionException, InterruptedException {
        cameraCategoryRepository.deleteAllByCategory(categoryId);
    }
}
