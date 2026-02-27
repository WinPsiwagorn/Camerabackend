from pydantic import BaseSettings

class Settings(BaseSettings):
    ENVIRONMENT: str
    KAFKA_BOOTSTRAP_SERVERS: str
    KAFKA_TOPIC: str
    KAFKA_GROUP_ID: str
    KAFKA_AUTO_OFFSET_RESET: str

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()