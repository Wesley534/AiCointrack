from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    PROJECT_NAME: str
    VERSION: str
    API_V1_STR: str
    SECRET_KEY: str
    ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int

    MYSQL_USER: str
    MYSQL_PASSWORD: str
    MYSQL_SERVER: str
    MYSQL_PORT: str
    MYSQL_DB: str

    DATABASE_URL: str
    BASE_RPC_URL: str
    HF_API_KEY: str

    # Privy (embedded wallets for email/password users)
    PRIVY_APP_ID: str = ""
    PRIVY_APP_SECRET: str = ""  # Set in .env; required for wallet creation

    # Firebase Configuration
    FIREBASE_PROJECT_ID: str = ""
    FIREBASE_CREDENTIALS_PATH: str = ""
    FIREBASE_API_KEY: str = ""
    FIREBASE_DATABASE_URL: str = ""
    FIREBASE_STORAGE_BUCKET: str = ""

    @property
    def SQLALCHEMY_DATABASE_URI(self) -> str:
        # Prefer explicit DATABASE_URL if provided; otherwise build from parts.
        return self.DATABASE_URL or (
            f"mysql+pymysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}"
            f"@{self.MYSQL_SERVER}:{self.MYSQL_PORT}/{self.MYSQL_DB}"
        )

    # Pydantic v2 config
    model_config = {
        "case_sensitive": True,
        "env_file": ".env",
        "extra": "ignore",
    }


settings = Settings()
