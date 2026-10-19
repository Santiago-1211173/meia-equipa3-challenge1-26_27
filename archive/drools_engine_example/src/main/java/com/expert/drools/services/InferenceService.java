package com.expert.drools.services;

import com.expert.drools.dtos.EvaluationResponseDto;
import com.expert.drools.dtos.EvidencesRequestDto;
import com.expert.drools.dtos.HealthResponseDto;

/**
 * Service interface for expert system inference operations and engine health status.
 */
public interface InferenceService {

    /**
     * Evaluates a set of clinical evidences against Drools business rules.
     *
     * @param requestDto the incoming evidences payload
     * @return the inference evaluation response containing conclusions, hypotheses, and fired rules
     */
    EvaluationResponseDto evaluate(EvidencesRequestDto requestDto);

    /**
     * Inspects the health and readiness of the Drools rule engine.
     *
     * @return the health status DTO
     */
    HealthResponseDto getHealthStatus();
}
