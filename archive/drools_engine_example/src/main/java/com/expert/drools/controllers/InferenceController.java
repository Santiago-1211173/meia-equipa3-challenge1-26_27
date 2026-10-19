package com.expert.drools.controllers;

import com.expert.drools.dtos.EvaluationResponseDto;
import com.expert.drools.dtos.EvidencesRequestDto;
import com.expert.drools.services.InferenceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Controller exposing the inference evaluation API for expert rule deduction.
 */
@RestController
@RequestMapping("/api/v1/inference")
@RequiredArgsConstructor
public class InferenceController {

    private final InferenceService inferenceService;

    /**
     * Evaluates incoming clinical evidence against Drools business rules.
     *
     * @param requestDto the clinical evidence payload
     * @return the diagnostic evaluation response
     */
    @PostMapping("/evaluate")
    public ResponseEntity<EvaluationResponseDto> evaluate(@Valid @RequestBody EvidencesRequestDto requestDto) {
        EvaluationResponseDto response = inferenceService.evaluate(requestDto);
        return ResponseEntity.ok(response);
    }
}
