from datetime import timedelta
from typing import Optional, List
import logging

from fastapi import APIRouter, Depends, HTTPException, status, Header
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel
from firebase_admin import auth

from app.core.config import settings
from app.core.security import create_access_token, decode_access_token, get_password_hash, verify_password
from app.core.firebase_init import verify_firebase_token, create_custom_token
from app.core.siwe_verify import verify_siwe_signature
from app.core.deps import get_current_user_jwt
from app.db.session import get_db
from app.models.user import User
from app.schemas.token import Token
from app.schemas.user import UserCreate, UserResponse

# Setup logging
logger = logging.getLogger(__name__)


router = APIRouter()


def _ensure_auth_provider(providers: Optional[List[str]], provider: str) -> List[str]:
    """Ensure provider is in list, return new list."""
    p = list(providers or [])
    if provider not in p:
        p.append(provider)
    return p


# Firebase Authentication Schemas
class FirebaseTokenRequest(BaseModel):
    idToken: Optional[str] = None
    id_token: Optional[str] = None  # alias for spec compatibility


class FirebaseAuthResponse(BaseModel):
    success: bool
    userId: int
    email: Optional[str] = None
    message: Optional[str] = None
    accessToken: Optional[str] = None
    user: Optional[dict] = None


class WalletLoginRequest(BaseModel):
    address: str
    signature: str
    message: str


class WalletAuthResponse(BaseModel):
    jwt: str
    firebase_custom_token: Optional[str] = None
    user: dict


class LinkWalletRequest(BaseModel):
    firebase_token: str  # or id_token from Firebase
    address: str
    signature: str
    message: str


class CreateWalletResponse(BaseModel):
    wallet_address: str
    user: dict


def _user_to_dict(user: User) -> dict:
    """Serialize user for API response."""
    return {
        "id": user.id,
        "email": user.email,
        "display_name": user.display_name,
        "photo_url": user.photo_url,
        "wallet_address": user.wallet_address,
        "auth_providers": user.auth_providers or [],
        "created_at": user.created_at.isoformat() if user.created_at else None,
    }


@router.post("/firebase", response_model=FirebaseAuthResponse)
@router.post("/firebase/register", response_model=FirebaseAuthResponse)
async def register_with_firebase(
    request: FirebaseTokenRequest,
    db: Session = Depends(get_db),
):
    """
    Register or authenticate user using Firebase ID token (Google or Email/Password).
    
    Body: { "id_token": "..." } or { "idToken": "..." }
    
    Returns: { jwt, user } — use jwt for subsequent API calls.
    """
    token = request.idToken or request.id_token or ""
    if not token:
        raise HTTPException(status_code=400, detail="id_token or idToken required")

    logger.info("🔐 Firebase Registration Request Received")

    try:
        decoded_token = verify_firebase_token(token)
        # Firebase tokens have 'sub' (subject) which is the Firebase UID
        # Firebase Admin SDK adds 'uid' as an alias, but we're using raw token verification
        firebase_uid = decoded_token.get('sub') or decoded_token.get('user_id') or decoded_token.get('uid')
        email = decoded_token.get('email')
        display_name = decoded_token.get('name')
        photo_url = decoded_token.get('picture')
        
        # Check if user already exists by firebase_uid
        existing_user = db.query(User).filter(
            User.firebase_uid == firebase_uid
        ).first()
        
        if existing_user:
            existing_user.email = email or existing_user.email
            existing_user.display_name = display_name or existing_user.display_name
            existing_user.photo_url = photo_url or existing_user.photo_url
            firebase_provider = (decoded_token.get("firebase") or {}).get("sign_in_provider") or ""
            provider_name = "google" if "google" in str(firebase_provider).lower() else "email"
            existing_user.auth_providers = _ensure_auth_provider(existing_user.auth_providers, provider_name)
            db.commit()
            db.refresh(existing_user)
            access_token = create_access_token(subject=str(existing_user.id))
            return FirebaseAuthResponse(
                success=True,
                userId=existing_user.id,
                email=existing_user.email or "",
                message="User updated successfully",
                accessToken=access_token,
                user=_user_to_dict(existing_user),
            )
        else:
            # Check if email already exists (user might have signed up with password)
            email_user = db.query(User).filter(User.email == email).first() if email else None
            if email_user:
                email_user.firebase_uid = firebase_uid
                email_user.display_name = display_name or email_user.display_name
                email_user.photo_url = photo_url or email_user.photo_url
                firebase_provider = (decoded_token.get("firebase") or {}).get("sign_in_provider") or ""
                provider_name = "google" if "google" in str(firebase_provider).lower() else "email"
                email_user.auth_providers = _ensure_auth_provider(email_user.auth_providers, provider_name)
                db.commit()
                db.refresh(email_user)
                access_token = create_access_token(subject=str(email_user.id))
                return FirebaseAuthResponse(
                    success=True,
                    userId=email_user.id,
                    email=email_user.email or "",
                    message="Firebase account linked to existing user",
                    accessToken=access_token,
                    user=_user_to_dict(email_user),
                )
            
            # Create new user
            firebase_provider = (decoded_token.get("firebase") or {}).get("sign_in_provider") or ""
            provider_name = "google" if "google" in str(firebase_provider).lower() else "email"
            new_user = User(
                firebase_uid=firebase_uid,
                email=email,
                display_name=display_name,
                photo_url=photo_url,
                full_name=display_name,
                auth_providers=[provider_name],
            )
            try:
                db.add(new_user)
                db.commit()
                db.refresh(new_user)
            except Exception as db_error:
                logger.error(f"Database error while creating user: {db_error}", exc_info=True)
                db.rollback()
                raise
            access_token = create_access_token(subject=str(new_user.id))
            return FirebaseAuthResponse(
                success=True,
                userId=new_user.id,
                email=new_user.email or "",
                message="User created successfully",
                accessToken=access_token,
                user=_user_to_dict(new_user),
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


@router.post("/wallet", response_model=WalletAuthResponse)
async def wallet_login(
    req: WalletLoginRequest,
    db: Session = Depends(get_db),
):
    """
    Miniapp or Flutter: Sign in with Base wallet via SIWE.
    Body: { address, signature, message }
    Returns: { jwt, firebase_custom_token?, user }
    """
    try:
        verify_siwe_signature(req.address, req.message, req.signature)
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))

    addr = req.address
    if not addr.startswith("0x"):
        addr = "0x" + addr

    user = db.query(User).filter(User.wallet_address == addr).first()

    if user:
        jwt_token = create_access_token(subject=str(user.id))
        firebase_token = None
        try:
            if user.firebase_uid:
                firebase_token = create_custom_token(user.firebase_uid)
        except ValueError:
            pass  # No service account; miniapp doesn't need it
        return WalletAuthResponse(
            jwt=jwt_token,
            firebase_custom_token=firebase_token,
            user=_user_to_dict(user),
        )

    # New user — use deterministic UID; create_custom_token will let Flutter sign in
    firebase_uid = f"wallet_{addr.lower()}"

    new_user = User(
        firebase_uid=firebase_uid,
        email=None,
        wallet_address=addr,
        auth_providers=["wallet"],
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    jwt_token = create_access_token(subject=str(new_user.id))
    firebase_token = None
    try:
        firebase_token = create_custom_token(firebase_uid)
    except ValueError:
        pass

    return WalletAuthResponse(
        jwt=jwt_token,
        firebase_custom_token=firebase_token,
        user=_user_to_dict(new_user),
    )


@router.post("/link-wallet")
async def link_wallet(
    req: LinkWalletRequest,
    db: Session = Depends(get_db),
):
    """
    Link wallet to existing Firebase (email/Google) account.
    Body: { firebase_token, address, signature, message }
    """
    try:
        decoded = verify_firebase_token(req.firebase_token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid Firebase token")

    firebase_uid = decoded.get("uid") or decoded.get("sub")
    if not firebase_uid:
        raise HTTPException(status_code=401, detail="Invalid token payload")

    try:
        verify_siwe_signature(req.address, req.message, req.signature)
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))

    addr = req.address if req.address.startswith("0x") else "0x" + req.address

    existing_wallet = db.query(User).filter(User.wallet_address == addr).first()
    if existing_wallet and existing_wallet.firebase_uid != firebase_uid:
        raise HTTPException(
            status_code=400,
            detail="Wallet is already linked to another account",
        )

    user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.wallet_address = addr
    user.auth_providers = _ensure_auth_provider(user.auth_providers, "wallet")
    db.commit()
    db.refresh(user)

    return {"user": _user_to_dict(user)}


@router.post("/create-wallet", response_model=CreateWalletResponse)
async def create_wallet_for_user(
    authorization: str = Header(None),
    db: Session = Depends(get_db),
):
    """
    Create smart wallet for user (placeholder — integrate Privy/Coinbase Smart Wallet).
    Requires Firebase or JWT.
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Authorization required")

    token = authorization.replace("Bearer ", "")
    user = None

    payload = decode_access_token(token)
    if payload and payload.get("sub"):
        user = db.query(User).filter(User.id == int(payload["sub"])).first()
    if not user:
        try:
            decoded = verify_firebase_token(token)
            firebase_uid = decoded.get("uid") or decoded.get("sub")
            user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
        except Exception:
            pass

    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    if user.wallet_address:
        raise HTTPException(
            status_code=400,
            detail="User already has a wallet. Use link-wallet for existing wallet.",
        )

    # Placeholder: in production, call Privy or Coinbase Smart Wallet SDK
    raise HTTPException(
        status_code=501,
        detail="Create wallet not yet implemented. Integrate Privy or Coinbase Smart Wallet SDK.",
    )


@router.get("/me")
async def get_current_user(
    user: User = Depends(get_current_user_jwt),
):
    """
    Get current user from JWT.
    Header: Authorization: Bearer <jwt>
    """
    return _user_to_dict(user)


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
        auth_providers=["email"],
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

