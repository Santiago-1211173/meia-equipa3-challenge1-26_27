package com.expert.drools.controllers;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class InferenceControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("GET /api/v1/inference/health returns 200 OK and health details")
    void testHealthEndpoint() throws Exception {
        mockMvc.perform(get("/api/v1/inference/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status", is("UP")))
                .andExpect(jsonPath("$.service", is("drools-engine")))
                .andExpect(jsonPath("$.version", is("1.0.0")))
                .andExpect(jsonPath("$.totalRules", greaterThanOrEqualTo(10)));
    }

    @Test
    @DisplayName("POST /api/v1/inference/evaluate returns 200 OK with correct diagnosis for Otorrhagia")
    void testEvaluateEndpointSuccess() throws Exception {
        String jsonPayload = """
                {
                    "bloodEar": "yes",
                    "earAche": "yes"
                }
                """;

        mockMvc.perform(post("/api/v1/inference/evaluate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jsonPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status", is("SUCCESS")))
                .andExpect(jsonPath("$.hypothesis", is("upper type")))
                .andExpect(jsonPath("$.primaryDiagnosis", is("Otorrhagia")))
                .andExpect(jsonPath("$.conclusions", hasItem("Otorrhagia")))
                .andExpect(jsonPath("$.firedRules", hasItem("r1_upper_type_classification")))
                .andExpect(jsonPath("$.firedRules", hasItem("r3_otorrhagia_ear_ache")));
    }

    @Test
    @DisplayName("POST /api/v1/inference/evaluate returns 400 Bad Request on invalid evidence value")
    void testEvaluateEndpointValidationFailure() throws Exception {
        String invalidPayload = """
                {
                    "bloodEar": "invalid_value"
                }
                """;

        mockMvc.perform(post("/api/v1/inference/evaluate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidPayload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error", is("Bad Request")))
                .andExpect(jsonPath("$.status", is(400)))
                .andExpect(jsonPath("$.details", not(empty())));
    }
}
