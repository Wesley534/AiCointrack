"""
Firebase Admin SDK initialization for backend authentication.

This module initializes Firebase Admin SDK and provides token verification.
Token verification uses Google's public certificates, so it doesn't require
service account credentials.
"""

import firebase_admin
from firebase_admin import credentials
import os
from pathlib import Path
import logging
import google.oauth2.id_token
from google.auth.transport import requests as google_requests

from app.core.config import settings

logger = logging.getLogger(__name__)

_firebase_initialized = False
_certs_request = None


def init_firebase():
    """
    Initialize Firebase Admin SDK.
    
    Uses credentials in this order:
    1. FIREBASE_CREDENTIALS_PATH from .env (service account key JSON)
    2. GOOGLE_APPLICATION_CREDENTIALS environment variable
    3. serviceAccountKey.json in backend root
    4. Falls back to project ID only mode (uses Google's public certs for verification)
    
    Requires FIREBASE_PROJECT_ID to be set in .env file.
    """
    global _firebase_initialized, _certs_request
    
    if _firebase_initialized:
        return
    
    try:
        # Check if project ID is configured
        if not settings.FIREBASE_PROJECT_ID:
            raise ValueError(
                "FIREBASE_PROJECT_ID not set in .env file. "
                "Get this from: Firebase Console > Settings > General > Project ID"
            )
        
        # Initialize request for certificate fetching (used for token verification)
        _certs_request = google_requests.Request()
        logger.info(f"Initialized certificate request handler")
        
        # Try to get service account key path from settings
        service_account_path = settings.FIREBASE_CREDENTIALS_PATH
        
        if service_account_path and os.path.exists(service_account_path):
            # Initialize with service account key file from settings
            logger.info(f"Loading service account from: {service_account_path}")
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
            logger.info(f"✓ Firebase Admin SDK initialized with service account")
        elif os.getenv("GOOGLE_APPLICATION_CREDENTIALS") and os.path.exists(os.getenv("GOOGLE_APPLICATION_CREDENTIALS")):
            # Try environment variable
            logger.info("Loading credentials from GOOGLE_APPLICATION_CREDENTIALS")
            cred = credentials.Certificate(os.getenv("GOOGLE_APPLICATION_CREDENTIALS"))
            firebase_admin.initialize_app(cred)
            logger.info("✓ Firebase Admin SDK initialized with GOOGLE_APPLICATION_CREDENTIALS")
        else:
            # Try default location
            default_path = Path(__file__).parent.parent.parent / "serviceAccountKey.json"
            if default_path.exists():
                logger.info(f"Loading service account from: {default_path}")
                cred = credentials.Certificate(str(default_path))
                firebase_admin.initialize_app(cred)
                logger.info("✓ Firebase Admin SDK initialized with serviceAccountKey.json")
            else:
                # Initialize without credentials
                logger.info("⚠ No service account credentials found")
                logger.info(f"  Using project ID only: {settings.FIREBASE_PROJECT_ID}")
                logger.info("  Token verification will use Google's public certificates")
                
                try:
                    firebase_admin.initialize_app(
                        options={'projectId': settings.FIREBASE_PROJECT_ID}
                    )
                    logger.info(f"✓ Firebase initialized (Project ID: {settings.FIREBASE_PROJECT_ID})")
                except ValueError as e:
                    # App already initialized
                    logger.info("✓ Firebase already initialized")
        
        _firebase_initialized = True
    except Exception as e:
        logger.error(f"✗ Firebase initialization failed: {e}")
        logger.error("However, token verification should still work using Google's public certificates")
        _firebase_initialized = True  # Still mark as initialized so verification can proceed


def verify_firebase_token(token: str) -> dict:
    """
    Verify a Firebase ID token using Google's public certificates.
    
    This method works without requiring service account credentials.
    It verifies:
    - Token signature using Google's public certificates
    - Token expiration
    - Token audience (project ID) matches configured project
    - Token issuer is Firebase
    
    Args:
        token: The Firebase ID token to verify
        
    Returns:
        dict: Decoded token containing user information (uid, email, name, picture, etc.)
        
    Raises:
        ValueError: If token is invalid or expired
        Exception: If certificate fetch fails
    """
    global _certs_request
    
    logger.debug(f"Verifying token (length: {len(token)} chars)")
    
    if not settings.FIREBASE_PROJECT_ID:
        raise ValueError("FIREBASE_PROJECT_ID not configured in .env")
    
    try:
        # Verify the token using Google's public certificates
        # This is the standard way to verify Firebase tokens without service account credentials
        claims = google.oauth2.id_token.verify_firebase_token(
            token,
            _certs_request,
            audience=settings.FIREBASE_PROJECT_ID
        )
        
        logger.debug(f"✓ Token verified successfully")
        logger.debug(f"  UID: {claims.get('uid')}")
        logger.debug(f"  Email: {claims.get('email')}")
        
        # Add 'uid' field for compatibility (Firebase Admin SDK does this automatically)
        # The 'sub' field contains the Firebase user ID
        if 'uid' not in claims and 'sub' in claims:
            claims['uid'] = claims['sub']
        
        return claims
    
    except ValueError as e:
        error_msg = str(e)
        logger.error(f"✗ Token verification failed: {error_msg}")
        
        if "expired" in error_msg.lower():
            raise ValueError(f"ID token has expired: {e}")
        elif "audience" in error_msg.lower():
            raise ValueError(
                f"Token audience mismatch. Expected: {settings.FIREBASE_PROJECT_ID}. "
                f"Make sure token is from the correct Firebase project."
            )
        else:
            raise ValueError(f"Invalid ID token: {e}")
    
    except Exception as e:
        logger.error(f"✗ Certificate verification error: {e}", exc_info=True)
        raise Exception(
            f"Failed to verify token - certificate fetch error: {e}. "
            f"This might be a temporary network issue. Please try again."
        )


def get_firebase_user(uid: str):
    """
    Get Firebase user by UID.
    
    Note: This requires service account credentials and won't work
    if only using project ID.
    
    Args:
        uid: Firebase user ID
        
    Returns:
        UserRecord: Firebase user record
    """
    from firebase_admin import auth
    
    if not _firebase_initialized:
        raise RuntimeError("Firebase not initialized. Call init_firebase() first.")
    
    try:
        return auth.get_user(uid)
    except Exception as e:
        logger.error(f"Failed to get Firebase user {uid}: {e}")
        raise
