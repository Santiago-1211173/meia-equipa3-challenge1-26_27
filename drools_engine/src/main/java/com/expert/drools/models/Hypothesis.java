package com.expert.drools.models;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Drools domain model representing intermediate reasoning hypotheses (e.g., "upper type", "lower type").
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Hypothesis {

    private String description;
}
