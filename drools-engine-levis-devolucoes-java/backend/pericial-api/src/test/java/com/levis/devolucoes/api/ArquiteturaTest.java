package com.levis.devolucoes.api;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.Architectures.layeredArchitecture;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.core.importer.Location;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

/**
 * Arquitetura de todos os módulos (código de produção): controllers só com DTO e as fachadas do
 * serviço, nunca o modelo nem o Drools; modelo sem Spring, JPA nem Drools; dependências entre
 * camadas só numa direção (docs/05).
 */
@AnalyzeClasses(
    packages = "com.levis.devolucoes",
    importOptions = {ImportOption.DoNotIncludeTests.class, ArquiteturaTest.SemTestJars.class})
class ArquiteturaTest {

  private static final String API = "com.levis.devolucoes.api..";
  private static final String SERVICO = "com.levis.devolucoes.service..";
  private static final String PERSISTENCIA = "com.levis.devolucoes.persistencia..";
  private static final String EXPLICACAO = "com.levis.devolucoes.explicacao..";
  private static final String REGRAS = "com.levis.devolucoes.regras..";
  private static final String DTO = "com.levis.devolucoes.dto..";
  private static final String MODELO = "com.levis.devolucoes.model..";
  private static final String INCERTEZA = "com.levis.devolucoes.incerteza..";

  /** Exclui os test-jar publicados pelos outros módulos. */
  static final class SemTestJars implements ImportOption {
    @Override
    public boolean includes(Location localizacao) {
      return !localizacao.contains("-tests.jar");
    }
  }

  @ArchTest
  static final ArchRule CONTROLLERS_SO_USAM_DTO_E_FACHADAS =
      classes()
          .that()
          .resideInAPackage("com.levis.devolucoes.api.controller..")
          .should()
          .onlyDependOnClassesThat()
          .resideInAnyPackage(
              API,
              DTO,
              "com.levis.devolucoes.service.avaliacao..",
              "com.levis.devolucoes.service.explicacao..",
              "com.levis.devolucoes.service.simulacao..",
              "com.levis.devolucoes.service.regra..",
              "com.levis.devolucoes.service.incerteza..",
              "java..",
              "jakarta.validation..",
              "org.springframework..",
              "io.swagger.v3.oas.annotations..");

  @ArchTest
  static final ArchRule CONTROLLERS_NUNCA_ACEDEM_AO_MODELO_NEM_AO_DROOLS =
      noClasses()
          .that()
          .resideInAPackage(API)
          .should()
          .dependOnClassesThat()
          .resideInAnyPackage(
              MODELO,
              REGRAS,
              EXPLICACAO,
              INCERTEZA,
              PERSISTENCIA,
              "org.kie..",
              "org.drools..",
              "net.sourceforge.jFuzzyLogic..");

  @ArchTest
  static final ArchRule MODELO_SEM_SPRING_JPA_NEM_DROOLS =
      noClasses()
          .that()
          .resideInAPackage(MODELO)
          .should()
          .dependOnClassesThat()
          .resideInAnyPackage(
              "org.springframework..", "jakarta.persistence..", "org.kie..", "org.drools..");

  @ArchTest
  static final ArchRule DTO_SEM_MODELO_NEM_SPRING =
      noClasses()
          .that()
          .resideInAPackage(DTO)
          .should()
          .dependOnClassesThat()
          .resideInAnyPackage(MODELO, SERVICO, PERSISTENCIA, "org.springframework..");

  @ArchTest
  static final ArchRule CAMADAS =
      layeredArchitecture()
          .consideringOnlyDependenciesInLayers()
          .layer("API")
          .definedBy(API)
          .layer("Servico")
          .definedBy(SERVICO)
          .layer("Persistencia")
          .definedBy(PERSISTENCIA)
          .layer("Explicacao")
          .definedBy(EXPLICACAO)
          .layer("Regras")
          .definedBy(REGRAS)
          .layer("Dto")
          .definedBy(DTO)
          .layer("Modelo")
          .definedBy(MODELO)
          .whereLayer("API")
          .mayNotBeAccessedByAnyLayer()
          .whereLayer("Servico")
          .mayOnlyBeAccessedByLayers("API")
          .whereLayer("Persistencia")
          .mayOnlyBeAccessedByLayers("Servico")
          .whereLayer("Explicacao")
          .mayOnlyBeAccessedByLayers("Servico")
          .whereLayer("Regras")
          .mayOnlyBeAccessedByLayers("Explicacao", "Servico")
          .whereLayer("Dto")
          .mayOnlyBeAccessedByLayers("API", "Servico")
          .whereLayer("Modelo")
          .mayOnlyBeAccessedByLayers("Regras", "Explicacao", "Servico");
}
