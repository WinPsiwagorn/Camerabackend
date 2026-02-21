package com.backendcam.backendcam.controller;

import com.backendcam.backendcam.model.entity.LicensePlate;
import com.backendcam.backendcam.service.search.LicensePlateService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/license-plates")
public class LicensePlateController {

    private final LicensePlateService licensePlateService;

    /**
     * GET /api/license-plates/search?licensePlate=ABC123
     * Returns the top 10 fuzzy matches sorted by score then latest dateTime.
     */
    @GetMapping("/search")
    public ResponseEntity<?> searchLicensePlate(@RequestParam(required = false) String licensePlate) {
        try {
            List<LicensePlate> results;

            if (licensePlate == null || licensePlate.trim().isEmpty()) {
                results = licensePlateService.getAll();
            } else {
                results = licensePlateService.getTopMatchesByLicensePlate(licensePlate);
            }

            if (results.isEmpty()) {
                return ResponseEntity.notFound().build();
            }

            return ResponseEntity.ok(results);
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body("Error searching license plate: " + e.getMessage());
        }
    }
}
