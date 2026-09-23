# ==============================================================================
# Dockerfile: Prolog Inference Engine Microservice
# ==============================================================================
# Microservice based on official SWI-Prolog image exposing the REST API
# for the Retail Returns & Exchanges Diagnostic POC.
# ==============================================================================

# Use official SWI-Prolog base image
FROM swipl:latest

# Define working directory in container
WORKDIR /app

# Copy application source code into container
COPY src/ /app/src/

# Expose default HTTP port
EXPOSE 8080

# Set default environment variables
ENV PORT=8080

# Launch application entrypoint
CMD ["swipl", "-s", "src/main.pl", "-g", "main", "-t", "halt"]
