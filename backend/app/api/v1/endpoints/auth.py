from datetime import timedelta
from typing import Optional
import logging

from fastapi import APIRouter, Depends, HTTPException, status, Header
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel
from firebase_admin import auth

from app.core.config import settings
from app.core.security import create_access_token, get_password_hash, verify_password
from app.core.firebase_init import verify_firebase_token
from app.db.session import get_db
from app.models.user import User
from app.schemas.token import Token
from app.schemas.user import UserCreate, UserResponse

# Setup logging
logger = logging.getLogger(__name__)


router = APIRouter()


# Firebase Authentication Schemas
class FirebaseTokenRequest(BaseModel):
    idToken: str


class FirebaseAuthResponse(BaseModel):
    success: bool
    userId: int
    email: str
    message: Optional[str] = None
    accessToken: Optional[str] = None


@router.post("/firebase/register", response_model=FirebaseAuthResponse)
async def register_with_firebase(
    request: FirebaseTokenRequest,
    db: Session = Depends(get_db),
):
    """
    Register or authenticate user using Firebase ID token.
    
    This endpoint:
    1. Verifies the Firebase ID token using Firebase Admin SDK
    2. Extracts user info from the token
    3. Creates or updates user in database
    4. Returns user ID, email, and access token
    """
    logger.info("=" * 80)
    logger.info("🔐 Firebase Registration Request Received")
    logger.info("=" * 80)
    
    try:
        # Log request
        logger.info(f"Token length: {len(request.idToken)} characters")
        logger.info(f"Token prefix: {request.idToken[:50]}...")
        
        # Verify the ID token with Firebase
        logger.info("Step 1: Verifying Firebase ID token...")
        decoded_token = verify_firebase_token(request.idToken)
        logger.info(f"✓ Token verified successfully")
        logger.debug(f"Decoded token keys: {decoded_token.keys()}")
        
        # Firebase tokens have 'sub' (subject) which is the Firebase UID
        # Firebase Admin SDK adds 'uid' as an alias, but we're using raw token verification
        firebase_uid = decoded_token.get('sub') or decoded_token.get('user_id') or decoded_token.get('uid')
        email = decoded_token.get('email')
        display_name = decoded_token.get('name')
        photo_url = decoded_token.get('picture')
        
        logger.info(f"Token details:")
        logger.info(f"  - Firebase UID: {firebase_uid}")
        logger.info(f"  - Email: {email}")
        logger.info(f"  - Display Name: {display_name}")
        logger.info(f"  - Photo URL: {photo_url}")
        
        # Check if user already exists by firebase_uid
        logger.info("Step 2: Checking for existing user by firebase_uid...")
        existing_user = db.query(User).filter(
            User.firebase_uid == firebase_uid
        ).first()
        
        if existing_user:
            logger.info(f"✓ User found with firebase_uid: {existing_user.id}")
            # Update existing user
            logger.info("Updating existing user details...")
            existing_user.email = email
            existing_user.display_name = display_name
            existing_user.photo_url = photo_url
            db.commit()
            db.refresh(existing_user)
            logger.info(f"✓ User updated successfully")
            
            # Generate JWT access token
            logger.info("Step 3: Generating access token...")
            access_token = create_access_token(subject=str(existing_user.id))
            logger.info(f"✓ Access token generated")
            
            logger.info("=" * 80)
            logger.info(f"✓ Firebase Registration Complete - User Updated (ID: {existing_user.id})")
            logger.info("=" * 80)
            
            return FirebaseAuthResponse(
                success=True,
                userId=existing_user.id,
                email=existing_user.email,
                message="User updated successfully",
                accessToken=access_token,
            )
        else:
            logger.info("✗ No user found with this firebase_uid")
            
            # Check if email already exists (user might have signed up with password)
            logger.info("Step 2b: Checking for existing user by email...")
            email_user = db.query(User).filter(User.email == email).first()
            if email_user:
                logger.info(f"✓ User found with email: {email_user.id}")
                # Link Firebase account to existing user
                logger.info("Linking Firebase account to existing user...")
                email_user.firebase_uid = firebase_uid
                email_user.display_name = display_name
                email_user.photo_url = photo_url
                db.commit()
                db.refresh(email_user)
                logger.info(f"✓ Firebase account linked")
                
                access_token = create_access_token(subject=str(email_user.id))
                logger.info(f"✓ Access token generated")
                
                logger.info("=" * 80)
                logger.info(f"✓ Firebase Registration Complete - Account Linked (ID: {email_user.id})")
                logger.info("=" * 80)
                
                return FirebaseAuthResponse(
                    success=True,
                    userId=email_user.id,
                    email=email_user.email,
                    message="Firebase account linked to existing user",
                    accessToken=access_token,
                )
            
            # Create new user
            logger.info("Step 2c: Creating new user...")
            new_user = User(
                firebase_uid=firebase_uid,
                email=email,
                display_name=display_name,
                photo_url=photo_url,
                full_name=display_name,
            )
            logger.debug(f"New user object created with firebase_uid: {firebase_uid}")
            
            try:
                db.add(new_user)
                logger.info("User added to session")
                
                db.commit()
                logger.info("Database commit successful")
                
                db.refresh(new_user)
                logger.info(f"✓ New user created with ID: {new_user.id}")
            except Exception as db_error:
                logger.error(f"✗ Database error while creating user: {db_error}", exc_info=True)
                db.rollback()
                raise
            
            # Generate JWT access token
            logger.info("Step 3: Generating access token...")
            access_token = create_access_token(subject=str(new_user.id))
            logger.info(f"✓ Access token generated")
            
            logger.info("=" * 80)
            logger.info(f"✓ Firebase Registration Complete - New User Created (ID: {new_user.id})")
            logger.info("=" * 80)
            
            return FirebaseAuthResponse(
                success=True,
                userId=new_user.id,
                email=new_user.email,
                message="User created successfully",
                accessToken=access_token,
            )
    
    except auth.ExpiredIdTokenError as e:
        logger.error(f"✗ ID token has expired: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="ID token has expired. Please sign in again.",
        )
    except auth.InvalidIdTokenError as e:
        logger.error(f"✗ Invalid ID token: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid ID token. Authentication failed.",
        )
    except auth.CertificateFetchError as e:
        logger.error(f"✗ Certificate fetch error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to verify token. Please try again.",
        )
    except ValueError as e:
        # Catch ValueError from verify_firebase_token (token invalid, expired, etc.)
        logger.error(f"✗ Token verification failed: {e}", exc_info=True)
        error_msg = str(e)
        if "expired" in error_msg.lower():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="ID token has expired. Please sign in again.",
            )
        elif "audience" in error_msg.lower():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Firebase project. Token is from a different project.",
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid ID token: {error_msg}",
            )
    except HTTPException:
        raise  # Re-raise HTTP exceptions as-is
    except Exception as e:
        logger.error(f"✗ Unexpected error during Firebase registration: {e}", exc_info=True)
        logger.error(f"Error type: {type(e).__name__}")
        logger.error(f"Error details: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Authentication error: {str(e)}",
        )


@router.post("/firebase/verify")
async def verify_firebase_token_endpoint(
    authorization: str = Header(None),
):
    """
    Verify a Firebase ID token from Authorization header.
    
    Usage: Authorization: Bearer <token>
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authorization header",
        )
    
    token = authorization.replace("Bearer ", "")
    
    try:
        decoded_token = verify_firebase_token(token)
        return {
            "valid": True,
            "uid": decoded_token['uid'],
            "email": decoded_token.get('email'),
            "name": decoded_token.get('name'),
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token verification failed: {str(e)}",
        )


@router.get("/profile")
async def get_user_profile(
    authorization: str = Header(None),
    db: Session = Depends(get_db),
):
    """Get authenticated user profile from database using Firebase token"""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authorization header",
        )
    
    token = authorization.replace("Bearer ", "")
    
    try:
        decoded_token = verify_firebase_token(token)
        firebase_uid = decoded_token['uid']
        
        user = db.query(User).filter(
            User.firebase_uid == firebase_uid
        ).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )
        
        return {
            "id": user.id,
            "email": user.email,
            "display_name": user.display_name,
            "photo_url": user.photo_url,
            "created_at": user.created_at,
        }
    except auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )


# Original password-based authentication endpoints (keep for backward compatibility)
@router.post("/signup", response_model=UserResponse)
def signup(user_in: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == user_in.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )
    user = User(
        email=user_in.email,
        full_name=user_in.full_name,
        hashed_password=get_password_hash(user_in.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=Token)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not user.hashed_password or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect email or password",
        )
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        subject=str(user.id),
        expires_delta=access_token_expires,
    )
    return Token(access_token=access_token)

