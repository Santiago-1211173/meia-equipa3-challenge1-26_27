package com.expert.drools.models;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Drools domain model representing the clinical evidence and symptoms observed in a patient.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Evidences {

    private String bloodEar;
    private String earAche;
    private String deafness;
    private String cerebrospinal;
    private String bloodNose;
    private String vomiting;
    private String bloodBrown;
    private String bloodMouth;
    private String bloodPenis;
    private String bloodAnus;
    private String bloodCoffee;
    private String headAche;
    private String bloodVagina;
}
