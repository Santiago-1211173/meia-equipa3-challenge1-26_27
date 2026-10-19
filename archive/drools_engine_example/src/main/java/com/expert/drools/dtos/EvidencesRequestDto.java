package com.expert.drools.dtos;

import com.expert.drools.models.Evidences;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Data Transfer Object for incoming inference requests.
 * Accepts clinical evidence indicators as 'yes' or 'no'.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class EvidencesRequestDto {

    private static final String YES_NO_PATTERN = "^(?i)(yes|no)?$";
    private static final String PATTERN_MESSAGE = "Value must be either 'yes' or 'no'";

    @Pattern(regexp = YES_NO_PATTERN, message = "bloodEar: " + PATTERN_MESSAGE)
    @JsonProperty("bloodEar")
    private String bloodEar;

    @Pattern(regexp = YES_NO_PATTERN, message = "earAche: " + PATTERN_MESSAGE)
    @JsonProperty("earAche")
    private String earAche;

    @Pattern(regexp = YES_NO_PATTERN, message = "deafness: " + PATTERN_MESSAGE)
    @JsonProperty("deafness")
    private String deafness;

    @Pattern(regexp = YES_NO_PATTERN, message = "cerebrospinal: " + PATTERN_MESSAGE)
    @JsonProperty("cerebrospinal")
    private String cerebrospinal;

    @Pattern(regexp = YES_NO_PATTERN, message = "bloodNose: " + PATTERN_MESSAGE)
    @JsonProperty("bloodNose")
    private String bloodNose;

    @Pattern(regexp = YES_NO_PATTERN, message = "vomiting: " + PATTERN_MESSAGE)
    @JsonProperty("vomiting")
    private String vomiting;

    @Pattern(regexp = YES_NO_PATTERN, message = "bloodBrown: " + PATTERN_MESSAGE)
    @JsonProperty("bloodBrown")
    private String bloodBrown;

    @Pattern(regexp = YES_NO_PATTERN, message = "bloodMouth: " + PATTERN_MESSAGE)
    @JsonProperty("bloodMouth")
    private String bloodMouth;

    @Pattern(regexp = YES_NO_PATTERN, message = "bloodPenis: " + PATTERN_MESSAGE)
    @JsonProperty("bloodPenis")
    private String bloodPenis;

    @Pattern(regexp = YES_NO_PATTERN, message = "bloodAnus: " + PATTERN_MESSAGE)
    @JsonProperty("bloodAnus")
    private String bloodAnus;

    @Pattern(regexp = YES_NO_PATTERN, message = "bloodCoffee: " + PATTERN_MESSAGE)
    @JsonProperty("bloodCoffee")
    private String bloodCoffee;

    @Pattern(regexp = YES_NO_PATTERN, message = "headAche: " + PATTERN_MESSAGE)
    @JsonProperty("headAche")
    private String headAche;

    @Pattern(regexp = YES_NO_PATTERN, message = "bloodVagina: " + PATTERN_MESSAGE)
    @JsonProperty("bloodVagina")
    private String bloodVagina;

    /**
     * Converts this DTO to a normalized domain {@link Evidences} object,
     * defaulting absent or null values to 'no'.
     *
     * @return the normalized domain entity
     */
    public Evidences toDomain() {
        return Evidences.builder()
                .bloodEar(normalize(bloodEar))
                .earAche(normalize(earAche))
                .deafness(normalize(deafness))
                .cerebrospinal(normalize(cerebrospinal))
                .bloodNose(normalize(bloodNose))
                .vomiting(normalize(vomiting))
                .bloodBrown(normalize(bloodBrown))
                .bloodMouth(normalize(bloodMouth))
                .bloodPenis(normalize(bloodPenis))
                .bloodAnus(normalize(bloodAnus))
                .bloodCoffee(normalize(bloodCoffee))
                .headAche(normalize(headAche))
                .bloodVagina(normalize(bloodVagina))
                .build();
    }

    private static String normalize(String value) {
        if (value == null || value.trim().isEmpty()) {
            return "no";
        }
        return value.trim().toLowerCase();
    }
}
