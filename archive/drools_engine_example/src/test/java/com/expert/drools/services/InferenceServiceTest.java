package com.expert.drools.services;

import com.expert.drools.dtos.EvaluationResponseDto;
import com.expert.drools.dtos.EvidencesRequestDto;
import com.expert.drools.models.Conclusion;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class InferenceServiceTest {

    @Autowired
    private InferenceService inferenceService;

    @Test
    @DisplayName("Should infer Otorrhagia when blood from ear and ear ache are present")
    void testOtorrhagiaWithEarAche() {
        EvidencesRequestDto request = EvidencesRequestDto.builder()
                .bloodEar("yes")
                .earAche("yes")
                .build();

        EvaluationResponseDto response = inferenceService.evaluate(request);

        assertNotNull(response);
        assertEquals("SUCCESS", response.getStatus());
        assertEquals("upper type", response.getHypothesis());
        assertTrue(response.getConclusions().contains(Conclusion.OTORRHAGIA));
        assertEquals(Conclusion.OTORRHAGIA, response.getPrimaryDiagnosis());
        assertTrue(response.getFiredRules().contains("r1_upper_type_classification"));
        assertTrue(response.getFiredRules().contains("r3_otorrhagia_ear_ache"));
    }

    @Test
    @DisplayName("Should infer Otorrhagia when blood from ear and deafness are present")
    void testOtorrhagiaWithDeafness() {
        EvidencesRequestDto request = EvidencesRequestDto.builder()
                .bloodEar("yes")
                .deafness("yes")
                .build();

        EvaluationResponseDto response = inferenceService.evaluate(request);

        assertNotNull(response);
        assertEquals("upper type", response.getHypothesis());
        assertTrue(response.getConclusions().contains(Conclusion.OTORRHAGIA));
    }

    @Test
    @DisplayName("Should infer Skull fracture when blood from ear and cerebrospinal fluid are present")
    void testSkullFracture() {
        EvidencesRequestDto request = EvidencesRequestDto.builder()
                .bloodEar("yes")
                .cerebrospinal("yes")
                .build();

        EvaluationResponseDto response = inferenceService.evaluate(request);

        assertNotNull(response);
        assertEquals("upper type", response.getHypothesis());
        assertTrue(response.getConclusions().contains(Conclusion.SKULL_FRACTURE));
    }

    @Test
    @DisplayName("Should infer Epistaxe when no blood ear and nose bleed is present")
    void testEpistaxe() {
        EvidencesRequestDto request = EvidencesRequestDto.builder()
                .bloodEar("no")
                .bloodNose("yes")
                .build();

        EvaluationResponseDto response = inferenceService.evaluate(request);

        assertNotNull(response);
        assertEquals("lower type", response.getHypothesis());
        assertTrue(response.getConclusions().contains(Conclusion.EPISTAXE));
    }

    @Test
    @DisplayName("Should infer Hemathese when lower type and blood mouth, brown blood, and vomiting")
    void testHemathese() {
        EvidencesRequestDto request = EvidencesRequestDto.builder()
                .bloodEar("no")
                .bloodMouth("yes")
                .bloodBrown("yes")
                .vomiting("yes")
                .build();

        EvaluationResponseDto response = inferenceService.evaluate(request);

        assertNotNull(response);
        assertEquals("lower type", response.getHypothesis());
        assertTrue(response.getConclusions().contains(Conclusion.HEMATHESE));
    }

    @Test
    @DisplayName("Should infer Mouth haemorrhage when lower type, blood mouth, but NOT brown and NOT vomiting")
    void testMouthHaemorrhage() {
        EvidencesRequestDto request = EvidencesRequestDto.builder()
                .bloodEar("no")
                .bloodMouth("yes")
                .bloodBrown("no")
                .vomiting("no")
                .build();

        EvaluationResponseDto response = inferenceService.evaluate(request);

        assertNotNull(response);
        assertEquals("lower type", response.getHypothesis());
        assertTrue(response.getConclusions().contains(Conclusion.MOUTH_HAEMORRHAGE));
    }

    @Test
    @DisplayName("Should infer Metrorrhagia when lower type and vaginal bleeding")
    void testMetrorrhagia() {
        EvidencesRequestDto request = EvidencesRequestDto.builder()
                .bloodEar("no")
                .bloodVagina("yes")
                .build();

        EvaluationResponseDto response = inferenceService.evaluate(request);

        assertNotNull(response);
        assertEquals("lower type", response.getHypothesis());
        assertTrue(response.getConclusions().contains(Conclusion.METRORRHAGIA));
    }

    @Test
    @DisplayName("Should infer Hematuria when lower type and penile bleeding")
    void testHematuria() {
        EvidencesRequestDto request = EvidencesRequestDto.builder()
                .bloodEar("no")
                .bloodPenis("yes")
                .build();

        EvaluationResponseDto response = inferenceService.evaluate(request);

        assertNotNull(response);
        assertEquals("lower type", response.getHypothesis());
        assertTrue(response.getConclusions().contains(Conclusion.HEMATURIA));
    }

    @Test
    @DisplayName("Should infer Melena when lower type, anal bleeding, and coffee ground blood")
    void testMelena() {
        EvidencesRequestDto request = EvidencesRequestDto.builder()
                .bloodEar("no")
                .bloodAnus("yes")
                .bloodCoffee("yes")
                .build();

        EvaluationResponseDto response = inferenceService.evaluate(request);

        assertNotNull(response);
        assertEquals("lower type", response.getHypothesis());
        assertTrue(response.getConclusions().contains(Conclusion.MELENA));
    }

    @Test
    @DisplayName("Should infer Rectal bleeding when lower type, anal bleeding, and NOT coffee ground blood")
    void testRectalBleeding() {
        EvidencesRequestDto request = EvidencesRequestDto.builder()
                .bloodEar("no")
                .bloodAnus("yes")
                .bloodCoffee("no")
                .build();

        EvaluationResponseDto response = inferenceService.evaluate(request);

        assertNotNull(response);
        assertEquals("lower type", response.getHypothesis());
        assertTrue(response.getConclusions().contains(Conclusion.RECTAL_BLEEDING));
    }

    @Test
    @DisplayName("Should fallback to unknown / look for doctor when no diagnostic rules match")
    void testUnknownFallback() {
        // No symptoms provided
        EvidencesRequestDto request = EvidencesRequestDto.builder().build();

        EvaluationResponseDto response = inferenceService.evaluate(request);

        assertNotNull(response);
        assertTrue(response.getConclusions().contains(Conclusion.UNKNOWN));
        assertEquals(Conclusion.UNKNOWN, response.getPrimaryDiagnosis());
        assertTrue(response.getFiredRules().contains("r13_unknown_diagnosis_fallback"));
    }
}
