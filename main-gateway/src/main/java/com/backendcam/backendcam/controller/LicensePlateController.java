package com.backendcam.backendcam.controller;

import com.backendcam.backendcam.model.entity.LicensePlate;
import com.backendcam.backendcam.service.licenseplate.LicensePlateService;
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
     * GET /api/license-plates/search
     *
     * All params are optional and combinable:
     *   ?fullPlate=8กผ 8167  → fuzzy search on fullPlate (exact first, fuzzy fallback)
     *   ?cameraId=camera123 → filter by camera
     *   ?text=8กผ           → filter by plate text
     *   ?number=8167        → filter by plate number
     *   ?province=กรุงเทพมหานคร → filter by province
     *   ?start=20260215_000000&end=20260225_235959 → timestamp range
     *
     * Params can be combined: ?cameraId=camera123&number=8167
     * If nothing is provided → returns all records.
     */
    @GetMapping("/search")
    public ResponseEntity<List<LicensePlate>> search(
            @RequestParam(required = false) String fullPlate,
            @RequestParam(required = false) String cameraId,
            @RequestParam(required = false) String text,
            @RequestParam(required = false) String number,
            @RequestParam(required = false) String province,
            @RequestParam(required = false) String start,
            @RequestParam(required = false) String end) {

        List<LicensePlate> results = licensePlateService.search(
                fullPlate, cameraId, text, number, province, start, end);

        if (results.isEmpty()) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(results);
    }
}
