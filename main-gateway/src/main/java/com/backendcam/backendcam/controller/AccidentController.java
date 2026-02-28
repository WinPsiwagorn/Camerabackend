package com.backendcam.backendcam.controller;

import com.backendcam.backendcam.model.dto.MessageResponse;
import com.backendcam.backendcam.model.dto.PageResponse;
import com.backendcam.backendcam.model.dto.accident.AccidentResponseDto;
import com.backendcam.backendcam.model.dto.accident.CreateAccidentDto;
import com.backendcam.backendcam.service.accident.AccidentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/accidents")
public class AccidentController {

    private final AccidentService accidentService;

    @PostMapping
    public ResponseEntity<AccidentResponseDto> createAccident(@RequestBody CreateAccidentDto createDto) {
        AccidentResponseDto accident = accidentService.createAccident(createDto);
        return ResponseEntity.ok(accident);
    }

    @GetMapping
    public ResponseEntity<PageResponse<List<AccidentResponseDto>>> getAccidents(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int limit) {
        PageResponse<List<AccidentResponseDto>> accidents = accidentService.getAccidentsByPage(page, limit);
        return ResponseEntity.ok(accidents);
    }

    @GetMapping("/{id}")
    public ResponseEntity<AccidentResponseDto> getAccidentById(@PathVariable String id) {
        return accidentService.getAccidentById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/camera/{cameraId}")
    public ResponseEntity<List<AccidentResponseDto>> getAccidentsByCameraId(@PathVariable String cameraId) {
        List<AccidentResponseDto> accidents = accidentService.getAccidentsByCameraId(cameraId);
        if (accidents.isEmpty()) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(accidents);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<MessageResponse> deleteAccident(@PathVariable String id) {
        accidentService.deleteAccident(id);
        return ResponseEntity.ok(new MessageResponse("Accident ID: " + id + " deleted successfully"));
    }
}
