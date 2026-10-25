# ADR 0010 — Java 25 LTS

- **Estado:** aceite
- **Data:** 2026-10-15

## Contexto

O backend estava definido para compilar com `release 21` e as imagens do Docker e o CI usavam JDK 21.
Java 25 é a versão LTS mais recente e está disponível no ambiente de desenvolvimento.

## Decisão

Atualizar o runtime e a compilação do backend para Java 25:

- o Maven compila com `release 25` e exige JDK 25 ou superior;
- o CI usa Temurin 25;
- as imagens de build e runtime da API usam Eclipse Temurin 25.

As regras de negócio e os documentos `docs/01` a `docs/06` não são alterados por esta atualização.
As referências a Java 21 nesses documentos mantêm-se como contexto histórico da arquitetura aprovada.

## Consequências

- O desenvolvimento local e os ambientes de execução da API precisam de JDK/JRE 25 ou superior.
- Build e testes devem confirmar a compatibilidade das versões atuais de Spring Boot, Drools e plugins Maven
  com Java 25.
