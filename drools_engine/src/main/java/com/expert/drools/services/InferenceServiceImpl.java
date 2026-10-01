package com.expert.drools.services;

import com.expert.drools.dtos.EvaluationResponseDto;
import com.expert.drools.dtos.EvidencesRequestDto;
import com.expert.drools.dtos.HealthResponseDto;
import com.expert.drools.models.Conclusion;
import com.expert.drools.models.Evidences;
import com.expert.drools.models.Hypothesis;
import lombok.RequiredArgsConstructor;
import org.kie.api.KieBase;
import org.kie.api.definition.KiePackage;
import org.kie.api.event.rule.AfterMatchFiredEvent;
import org.kie.api.event.rule.DefaultAgendaEventListener;
import org.kie.api.runtime.KieContainer;
import org.kie.api.runtime.KieSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Production implementation of the {@link InferenceService} leveraging Drools KieContainer.
 */
@Service
@RequiredArgsConstructor
public class InferenceServiceImpl implements InferenceService {

    private static final Logger log = LoggerFactory.getLogger(InferenceServiceImpl.class);

    private final KieContainer kieContainer;

    @Override
    public EvaluationResponseDto evaluate(EvidencesRequestDto requestDto) {
        log.info("Starting inference evaluation for request: {}", requestDto);

        Evidences evidences = requestDto.toDomain();
        KieSession kSession = createSession();
        List<String> firedRules = new ArrayList<>();

        try {
            // Track fired rules for explainability
            kSession.addEventListener(new DefaultAgendaEventListener() {
                @Override
                public void afterMatchFired(AfterMatchFiredEvent event) {
                    String ruleName = event.getMatch().getRule().getName();
                    firedRules.add(ruleName);
                    log.debug("Drools rule fired: {}", ruleName);
                }
            });

            // Insert facts and trigger inference
            kSession.insert(evidences);
            int rulesCount = kSession.fireAllRules();
            log.info("Inference completed. Total rules triggered: {}", rulesCount);

            // Extract conclusions and hypotheses from Working Memory
            Collection<?> objects = kSession.getObjects();

            List<String> conclusions = objects.stream()
                    .filter(Conclusion.class::isInstance)
                    .map(c -> ((Conclusion) c).getDescription())
                    .distinct()
                    .collect(Collectors.toList());

            String hypothesis = objects.stream()
                    .filter(Hypothesis.class::isInstance)
                    .map(h -> ((Hypothesis) h).getDescription())
                    .findFirst()
                    .orElse(null);

            String primaryDiagnosis = conclusions.isEmpty()
                    ? Conclusion.UNKNOWN
                    : conclusions.get(0);

            return EvaluationResponseDto.builder()
                    .status("SUCCESS")
                    .primaryDiagnosis(primaryDiagnosis)
                    .conclusions(conclusions)
                    .hypothesis(hypothesis)
                    .firedRules(firedRules)
                    .timestamp(Instant.now())
                    .evidencesEvaluated(requestDto)
                    .build();

        } finally {
            // Always dispose KieSession to prevent memory leaks
            kSession.dispose();
        }
    }

    @Override
    public HealthResponseDto getHealthStatus() {
        int totalRules = 0;
        String activeKieBase = "haemorrhageKBase";

        try {
            KieBase kieBase = kieContainer.getKieBase();
            if (kieBase != null) {
                for (KiePackage kp : kieBase.getKiePackages()) {
                    totalRules += kp.getRules().size();
                }
            }
        } catch (Exception ex) {
            log.warn("Unable to count rules in KieBase: {}", ex.getMessage());
        }

        return HealthResponseDto.builder()
                .status("UP")
                .service("drools-engine")
                .version("1.0.0")
                .activeKieBase(activeKieBase)
                .totalRules(totalRules)
                .timestamp(Instant.now())
                .build();
    }

    private KieSession createSession() {
        try {
            return kieContainer.newKieSession("haemorrhageKSession");
        } catch (Exception ex) {
            log.debug("Session 'haemorrhageKSession' not found directly by name, falling back to default session: {}",
                    ex.getMessage());
            return kieContainer.newKieSession();
        }
    }
}
