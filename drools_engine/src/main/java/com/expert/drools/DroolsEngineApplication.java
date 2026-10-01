package com.expert.drools;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Main application class bootstrapping the Drools Inference Engine microservice.
 */
@SpringBootApplication
public class DroolsEngineApplication {

    public static void main(String[] args) {
        SpringApplication.run(DroolsEngineApplication.class, args);
    }
}
