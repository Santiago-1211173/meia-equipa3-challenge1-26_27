# ==============================================================================
# Dockerfile: FastAPI Backend Orchestrator Microservice
# ==============================================================================
# Multi-stage / optimized slim image for the Retail Returns & Exchanges
# Diagnostic Expert System Orchestrator layer.
# ==============================================================================

FROM python:3.11-slim

# Prevent Python from writing .pyc files and enable unbuffered logging
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

# Set working directory
WORKDIR /app

# Install dependencies first to leverage Docker layer caching
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /app/requirements.txt

# Copy application source code
COPY app/ /app/app/

# Expose HTTP service port
EXPOSE 8000

# Run FastAPI via Uvicorn ASGI server
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
