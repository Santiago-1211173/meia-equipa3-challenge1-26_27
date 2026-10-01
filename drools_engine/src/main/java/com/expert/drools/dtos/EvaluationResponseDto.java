package com.expert.drools.dtos;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.List;

/**
 * Data Transfer Object returned upon inference evaluation.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class EvaluationResponseDto {

    private String status;
    private String primaryDiagnosis;
    private List<String> conclusions;
    private String hypothesis;
    private List<String> firedRules;
    private Instant timestamp;
    private EvidencesRequestDto evidencesEvaluated;
}
