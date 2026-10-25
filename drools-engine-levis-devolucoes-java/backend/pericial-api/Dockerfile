# Imagem da API. Contexto de build: a raiz do repositório (projeto Maven multi-módulo).
#   docker build -f backend/pericial-api/Dockerfile -t pericial-api .

FROM maven:3.9-eclipse-temurin-25 AS build
WORKDIR /src
# Dependências primeiro, para aproveitar a cache das camadas
COPY pom.xml .
COPY .mvn .mvn
COPY config config
COPY backend backend
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B -ntp -pl backend/pericial-api -am package \
        -DskipTests -Djacoco.skip=true -Dspotless.check.skip=true -Dcheckstyle.skip=true

FROM eclipse-temurin:25-jre
# A imagem Java 25 (Ubuntu 26.04) não traz o wget usado pelo HEALTHCHECK
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system pericial && useradd --system --gid pericial pericial
WORKDIR /app
COPY --from=build /src/backend/pericial-api/target/pericial-api-*.jar app.jar
USER pericial
# Dentro do contentor a API usa sempre a 8080; fora dele a predefinição é a 8082 (application.yml)
ENV SERVER_PORT=8080
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=3s --start-period=60s --retries=5 \
    CMD wget -qO- http://localhost:8080/actuator/health/readiness || exit 1
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "/app/app.jar"]
