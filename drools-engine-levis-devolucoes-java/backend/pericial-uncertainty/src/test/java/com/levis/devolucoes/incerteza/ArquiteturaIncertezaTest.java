package com.levis.devolucoes.incerteza;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

/** A camada de incerteza depende só do modelo (docs/08 §5.2): sem Spring, JPA nem Drools. */
@AnalyzeClasses(
    packages = "com.levis.devolucoes.incerteza",
    importOptions = ImportOption.DoNotIncludeTests.class)
class ArquiteturaIncertezaTest {

  @ArchTest
  static final ArchRule SEM_FRAMEWORKS =
      noClasses()
          .should()
          .dependOnClassesThat()
          .resideInAnyPackage(
              "org.springframework..", "jakarta.persistence..", "org.kie..", "org.drools..")
          .because("pericial-uncertainty é usado pelas regras e pelo serviço sem os conhecer");

  @ArchTest
  static final ArchRule SO_O_MODELO =
      noClasses()
          .should()
          .dependOnClassesThat()
          .resideInAnyPackage(
              "com.levis.devolucoes.regras..",
              "com.levis.devolucoes.explicacao..",
              "com.levis.devolucoes.dto..",
              "com.levis.devolucoes.persistencia..",
              "com.levis.devolucoes.service..",
              "com.levis.devolucoes.api..")
          .because("pericial-uncertainty depende só de pericial-model (docs/08 §5.2)");

  @ArchTest
  static final ArchRule JFUZZYLOGIC_SO_NO_MOTOR =
      noClasses()
          .that()
          .resideOutsideOfPackage("com.levis.devolucoes.incerteza.fuzzy..")
          .should()
          .dependOnClassesThat()
          .resideInAnyPackage("net.sourceforge.jFuzzyLogic..")
          .because("o jFuzzyLogic fica atrás da interface MotorFuzzy (ADR 0012)");
}
