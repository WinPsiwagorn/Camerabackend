from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    ENVIRONMENT: str
    KAFKA_BOOTSTRAP_SERVERS: str
    KAFKA_TOPIC: str
    KAFKA_GROUP_ID: str
    KAFKA_AUTO_OFFSET_RESET: str

    model_config = {
        "env_file": "/app/.env",
        "env_file_encoding": "utf-8"
    }

settings = Settings()