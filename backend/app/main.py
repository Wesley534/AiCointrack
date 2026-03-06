from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

from app.api.v1.api import api_router
from app.core.config import settings
from app.core.firebase_init import init_firebase

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    redirect_slashes=False,
)

# Configure CORS (miniapp, Flutter, local dev)
# Explicitly list origins to avoid DevTunnel CORS issues
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:3001",
        "https://cointrack-nu.vercel.app",
        "*",  # Fallback for other origins
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Initialize Firebase Admin SDK on startup
@app.on_event("startup")
async def startup_event():
    try:
        logger.info("Starting up - Initializing Firebase Admin SDK")
        init_firebase()
        logger.info("✓ Firebase Admin SDK initialized successfully")
    except Exception as e:
        logger.error(f"✗ Firebase initialization failed - {e}", exc_info=True)
        print("Warning: Firebase initialization failed - {e}")
        print("Firebase authentication endpoints will not work without proper setup")

app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/")
def root():
    return {"message": "Welcome to CoinTrack API", "status": "active"}

