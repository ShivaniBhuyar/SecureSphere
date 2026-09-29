import os
from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    HOST: str = "0.0.0.0"
    PORT: int = int(os.environ.get("PORT", 8000))
    ENVIRONMENT: str = os.environ.get("ENVIRONMENT", "development")
    DATABASE_URL: str = os.environ.get("DATABASE_URL", "sqlite:///./securesphere.db")

    # External Security APIs (Backend only)
    VIRUSTOTAL_API_KEY: Optional[str] = None
    GOOGLE_SAFE_BROWSING_KEY: Optional[str] = None
    PHISHTANK_API_KEY: Optional[str] = None
    OPENAI_API_KEY: Optional[str] = None

    class Config:
        env_file = os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env")
        env_file_encoding = "utf-8"
        extra = "ignore"

settings = Settings()
