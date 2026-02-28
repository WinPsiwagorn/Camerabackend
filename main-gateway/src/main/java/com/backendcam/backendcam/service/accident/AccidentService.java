package com.backendcam.backendcam.service.accident;

import com.backendcam.backendcam.model.dto.PageResponse;
import com.backendcam.backendcam.model.dto.accident.AccidentResponseDto;
import com.backendcam.backendcam.model.dto.accident.CreateAccidentDto;
import com.backendcam.backendcam.model.entity.Accident;
import com.backendcam.backendcam.repository.AccidentRepository;
import com.backendcam.backendcam.util.PaginationUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AccidentService {

    private final AccidentRepository accidentRepository;

    public AccidentResponseDto createAccident(CreateAccidentDto createDto) {
        try {
            Accident accident = new Accident();
            accident.setCameraId(createDto.getCameraId());
            accident.setImageUrl(createDto.getImageUrl());
            accident.setTimestamp(createDto.getTimestamp());

            String id = accidentRepository.save(accident);
            accident.setId(id);
            return toDto(accident);
        } catch (Exception e) {
            throw new RuntimeException("Failed to create accident", e);
        }
    }

    public Optional<AccidentResponseDto> getAccidentById(String id) {
        try {
            return accidentRepository.findById(id).map(this::toDto);
        } catch (Exception e) {
            throw new RuntimeException("Failed to get accident by id", e);
        }
    }

    public PageResponse<List<AccidentResponseDto>> getAccidentsByPage(int page, int limit) {
        try {
            List<Accident> accidents = accidentRepository.findByPage(page, limit);
            long totalItems = accidentRepository.getTotalCount();
            return PaginationUtil.createPaginationResponse(accidents, totalItems, page, limit, this::toDto);
        } catch (Exception e) {
            throw new RuntimeException("Failed to get accidents by page", e);
        }
    }

    public List<AccidentResponseDto> getAccidentsByCameraId(String cameraId) {
        try {
            return accidentRepository.findByCameraId(cameraId).stream()
                    .map(this::toDto)
                    .toList();
        } catch (Exception e) {
            throw new RuntimeException("Failed to get accidents by cameraId", e);
        }
    }

    public void deleteAccident(String id) {
        try {
            accidentRepository.findById(id)
                    .orElseThrow(() -> new java.util.NoSuchElementException("Accident not found: " + id));
            accidentRepository.delete(id);
        } catch (java.util.NoSuchElementException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Failed to delete accident", e);
        }
    }

    private AccidentResponseDto toDto(Accident accident) {
        return new AccidentResponseDto(
                accident.getId(),
                accident.getCameraId(),
                accident.getImageUrl(),
                accident.getTimestamp()
        );
    }
}
