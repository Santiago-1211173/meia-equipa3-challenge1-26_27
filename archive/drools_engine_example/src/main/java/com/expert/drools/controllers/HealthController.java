package com.expert.drools.controllers;

import com.expert.drools.dtos.HealthResponseDto;
import com.expert.drools.services.InferenceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Controller exposing health and status check endpoints.
 */
@RestController
@RequestMapping("/api/v1/inference")
@RequiredArgsConstructor
public class HealthController {

    private final InferenceService inferenceService;

    /**
     * Health check endpoint to verify that the Drools inference engine is alive and ready.
     *
     * @return current service and engine status
     */
    @GetMapping("/health")
    public ResponseEntity<HealthResponseDto> checkHealth() {
        HealthResponseDto health = inferenceService.getHealthStatus();
        return ResponseEntity.ok(health);
    }
}
