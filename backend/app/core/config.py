from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    PROJECT_NAME: str
    VERSION: str
    API_V1_STR: str
    SECRET_KEY: str
    ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int

    # Database — set DATABASE_URL to your Neon PostgreSQL connection string.
    # Format: postgresql://user:password@ep-xxx.us-east-2.aws.neon.tech/neondb?sslmode=require
    DATABASE_URL: str

    BASE_RPC_URL: str
    CHAIN_ID: int = 84532
    FRONTEND_URL: str = "https://app.aicointrack.xyz"
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
        # Use pg8000 (pure Python, no C extensions) instead of psycopg2
        url = self.DATABASE_URL
        if url.startswith('postgresql://'):
            url = url.replace('postgresql://', 'postgresql+pg8000://', 1)
        # pg8000 doesn't support sslmode or channel_binding query params;
        # it uses SSL by default for remote connections, so we strip them.
        from urllib.parse import urlparse, urlencode, parse_qs
        parsed = urlparse(url)
        query = parse_qs(parsed.query)
        for key in ('sslmode', 'channel_binding'):
            query.pop(key, None)
        if query:
            new_query = urlencode(query, doseq=True)
            url = url.replace(f'?{parsed.query}', f'?{new_query}')
        else:
            url = url.split('?')[0] if '?' in url else url
        return url

    # Pydantic v2 config
    model_config = {
        "case_sensitive": True,
        "env_file": ".env",
        "extra": "ignore",
    }


settings = Settings()
