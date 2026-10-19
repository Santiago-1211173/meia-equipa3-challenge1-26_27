"""Database initialization with exponential backoff retry mechanism."""

import asyncio
import logging
from sqlalchemy.exc import OperationalError
from app.db.session import async_engine, Base
# Import models to ensure they are registered with Base.metadata
import app.db.models  # noqa: F401

logger = logging.getLogger(__name__)


async def init_db(max_retries: int = 5, delay: float = 2.0) -> None:
    """Initialize database tables with exponential backoff retry."""
    for attempt in range(1, max_retries + 1):
        try:
            logger.info(f"[DB] Initializing database schema (attempt {attempt}/{max_retries})...")
            async with async_engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            logger.info("[DB] Database tables successfully verified/created.")
            return
        except (OperationalError, ConnectionRefusedError, OSError, Exception) as exc:
            if attempt == max_retries:
                logger.error(f"[DB] Failed to connect to database after {max_retries} attempts: {exc}")
                raise
            sleep_time = delay * (2 ** (attempt - 1))
            logger.warning(f"[DB] Connection failed (attempt {attempt}/{max_retries}). Retrying in {sleep_time:.1f}s... ({exc})")
            await asyncio.sleep(sleep_time)
