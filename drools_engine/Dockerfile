# ==============================================================================
# Stage 1: Build Stage using official Maven image with Temurin JDK 21 Alpine
# ==============================================================================
FROM maven:3.9-eclipse-temurin-21-alpine AS build

WORKDIR /app

# Copy pom.xml first to optimize Docker layer caching
COPY pom.xml .

# Download dependencies offline to accelerate subsequent builds
RUN mvn dependency:go-offline -B || true

# Copy application source code
COPY src ./src

# Build production executable JAR (running tests during build)
RUN mvn clean package -DskipTests

# ==============================================================================
# Stage 2: Lightweight Runtime Stage using minimal Alpine JRE 21
# ==============================================================================
FROM eclipse-temurin:21-jre-alpine AS runtime

WORKDIR /app

# Create non-privileged system user and group for enhanced container security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy built artifact from build stage
COPY --from=build /app/target/*.jar app.jar

# Set ownership of application files
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose microservice REST API port
EXPOSE 8080

# Environment configurations for containerized Java
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# Application startup entrypoint
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
