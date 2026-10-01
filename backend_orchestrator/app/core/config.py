"""Application configuration module using Pydantic Settings."""

import json
from pathlib import Path
from typing import List, Union

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# Base directory for the backend orchestrator service (root of backend_orchestrator)
BASE_DIR = Path(__file__).resolve().parent.parent.parent


class Settings(BaseSettings):
    """Central application settings loaded from environment variables or .env file."""

    model_config = SettingsConfigDict(
        env_file=(str(BASE_DIR / ".env"), ".env"),
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    PROJECT_NAME: str = "Retail Returns & Exchanges Diagnostic Orchestrator"
    API_V1_STR: str = "/api/v1"
    DEBUG: bool = True
    PORT: int = 8000
    PROLOG_ENGINE_URL: str = "http://localhost:8080"
    PROLOG_TIMEOUT_SECONDS: float = 5.0
    DROOLS_ENGINE_URL: str = "http://localhost:8082"
    DROOLS_TIMEOUT_SECONDS: float = 5.0
    INFERENCE_ENGINE_ENABLED: bool = True  # Feature toggle for the academic example engine (sp_exp2.pl from Moodle)
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:5173",
        "http://localhost:8000",
    ]

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        """Parse CORS_ORIGINS from a JSON list string or comma-separated values."""
        if isinstance(v, str):
            v_stripped = v.strip()
            if v_stripped.startswith("[") and v_stripped.endswith("]"):
                try:
                    parsed = json.loads(v_stripped)
                    if isinstance(parsed, list):
                        return parsed
                except Exception:
                    pass
            return [origin.strip() for origin in v_stripped.split(",") if origin.strip()]
        return v


# Singleton instance used throughout the application
settings = Settings()
