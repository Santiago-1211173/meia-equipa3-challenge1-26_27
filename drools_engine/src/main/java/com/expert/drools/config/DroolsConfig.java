package com.expert.drools.config;

import org.kie.api.KieServices;
import org.kie.api.builder.KieBuilder;
import org.kie.api.builder.KieFileSystem;
import org.kie.api.builder.Message;
import org.kie.api.builder.Results;
import org.kie.api.runtime.KieContainer;
import org.kie.internal.io.ResourceFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;

import java.io.IOException;

/**
 * Spring configuration class responsible for creating and exposing the {@link KieContainer} bean.
 */
@Configuration
public class DroolsConfig {

    private static final Logger log = LoggerFactory.getLogger(DroolsConfig.class);

    @Bean
    public KieServices kieServices() {
        return KieServices.Factory.get();
    }

    @Bean
    public KieContainer kieContainer(KieServices kieServices) {
        log.info("Initializing Drools KieContainer...");

        try {
            KieContainer classpathContainer = kieServices.getKieClasspathContainer(getClass().getClassLoader());
            Results verifyResults = classpathContainer.verify();
            if (!verifyResults.hasMessages(Message.Level.ERROR)) {
                log.info("KieClasspathContainer initialized successfully with kmodule.xml");
                return classpathContainer;
            } else {
                log.warn("Classpath container verification had errors: {}. Falling back to KieFileSystem.",
                        verifyResults.getMessages());
            }
        } catch (Exception ex) {
            log.warn("KieClasspathContainer initialization failed: {}. Falling back to KieFileSystem.",
                    ex.getMessage());
        }

        try {
            KieFileSystem kieFileSystem = kieServices.newKieFileSystem();
            PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();

            Resource kmodule = resolver.getResource("classpath:META-INF/kmodule.xml");
            if (kmodule.exists()) {
                kieFileSystem.write("src/main/resources/META-INF/kmodule.xml",
                        ResourceFactory.newInputStreamResource(kmodule.getInputStream()));
            }

            Resource[] drlResources = resolver.getResources("classpath*:rules/*.drl");
            for (Resource drl : drlResources) {
                log.info("Loading DRL rule: {}", drl.getFilename());
                kieFileSystem.write("src/main/resources/rules/" + drl.getFilename(),
                        ResourceFactory.newInputStreamResource(drl.getInputStream()));
            }

            KieBuilder kieBuilder = kieServices.newKieBuilder(kieFileSystem);
            kieBuilder.buildAll();

            Results results = kieBuilder.getResults();
            if (results.hasMessages(Message.Level.ERROR)) {
                log.error("Drools compilation errors: {}", results.getMessages());
                throw new IllegalStateException("Failed to compile Drools rules: " + results.getMessages());
            }

            KieContainer container = kieServices.newKieContainer(kieServices.getRepository().getDefaultReleaseId());
            log.info("KieContainer initialized successfully via KieFileSystem.");
            return container;
        } catch (IOException ex) {
            throw new IllegalStateException("Could not read rule files from classpath", ex);
        }
    }
}
