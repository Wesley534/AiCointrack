# Backend Authentication Examples

This file contains example implementations for verifying Firebase ID tokens on your backend.

## Python / FastAPI Example

```python
# backend/app/api/v1/endpoints/auth.py

import firebase_admin
from firebase_admin import auth, credentials
from fastapi import APIRouter, HTTPException, Depends, Header
from pydantic import BaseModel
from typing import Optional
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse
from app.core.config import settings

router = APIRouter(tags=["auth"])

class TokenRequest(BaseModel):
    idToken: str

class AuthResponse(BaseModel):
    success: bool
    userId: int
    email: str
    message: Optional[str] = None

@router.post("/register", response_model=AuthResponse)
async def register_with_firebase(
    request: TokenRequest,
    db: Session = Depends(get_db)
):
    """
    Register or authenticate user using Firebase ID token.
    
    This endpoint:
    1. Verifies the Firebase ID token using Firebase Admin SDK
    2. Extracts user info from the token
    3. Creates or updates user in database
    4. Returns user ID and email
    """
    try:
        # Verify the ID token with Firebase
        decoded_token = auth.verify_id_token(request.idToken)
        firebase_uid = decoded_token['uid']
        email = decoded_token.get('email')
        display_name = decoded_token.get('name')
        photo_url = decoded_token.get('picture')
        
        # Check if user already exists
        existing_user = db.query(User).filter(
            User.firebase_uid == firebase_uid
        ).first()
        
        if existing_user:
            # Update existing user
            existing_user.email = email
            existing_user.display_name = display_name
            existing_user.photo_url = photo_url
            db.commit()
            db.refresh(existing_user)
            
            return AuthResponse(
                success=True,
                userId=existing_user.id,
                email=existing_user.email,
                message="User updated successfully"
            )
        else:
            # Create new user
            new_user = User(
                firebase_uid=firebase_uid,
                email=email,
                display_name=display_name,
                photo_url=photo_url
            )
            db.add(new_user)
            db.commit()
            db.refresh(new_user)
            
            return AuthResponse(
                success=True,
                userId=new_user.id,
                email=new_user.email,
                message="User created successfully"
            )
    
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=401,
            detail="ID token has expired. Please sign in again."
        )
    except auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=401,
            detail="Invalid ID token. Authentication failed."
        )
    except auth.CertificateFetchError:
        raise HTTPException(
            status_code=500,
            detail="Failed to verify token. Please try again."
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Authentication error: {str(e)}"
        )

@router.post("/verify-token")
async def verify_token(
    authorization: str = Header(None)
):
    """
    Verify an ID token from Authorization header.
    
    Usage: Authorization: Bearer <token>
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Missing or invalid authorization header"
        )
    
    token = authorization.replace("Bearer ", "")
    
    try:
        decoded_token = auth.verify_id_token(token)
        return {
            "valid": True,
            "uid": decoded_token['uid'],
            "email": decoded_token.get('email'),
            "name": decoded_token.get('name')
        }
    except Exception as e:
        raise HTTPException(
            status_code=401,
            detail=f"Token verification failed: {str(e)}"
        )

@router.get("/profile")
async def get_user_profile(
    authorization: str = Header(None),
    db: Session = Depends(get_db)
):
    """Get authenticated user profile from database"""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Missing or invalid authorization header"
        )
    
    token = authorization.replace("Bearer ", "")
    
    try:
        decoded_token = auth.verify_id_token(token)
        firebase_uid = decoded_token['uid']
        
        user = db.query(User).filter(
            User.firebase_uid == firebase_uid
        ).first()
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        return {
            "id": user.id,
            "email": user.email,
            "display_name": user.display_name,
            "photo_url": user.photo_url,
            "created_at": user.created_at
        }
    except auth.InvalidIdTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")
```

## Setup Firebase Admin SDK

```python
# backend/app/core/firebase_init.py

import firebase_admin
from firebase_admin import credentials
import os

# Initialize Firebase Admin SDK
def init_firebase():
    # Option 1: Using service account key file
    cred = credentials.Certificate("path/to/serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
    
    # Option 2: Using GOOGLE_APPLICATION_CREDENTIALS env variable
    # firebase_admin.initialize_app()

# Call this in main.py or __init__.py
init_firebase()
```

Get `serviceAccountKey.json`:
1. Go to Firebase Console → Settings → Service Accounts
2. Click "Generate New Private Key"
3. Save the JSON file securely
4. Add to `.gitignore`

## User Model

```python
# backend/app/models/user.py

from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    firebase_uid = Column(String(255), unique=True, index=True)
    email = Column(String(255), unique=True, index=True)
    display_name = Column(String(255), nullable=True)
    photo_url = Column(String(500), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
```

## Node.js / Express Example

```javascript
// backend/routes/auth.js

const express = require('express');
const admin = require('firebase-admin');
const router = express.Router();
const User = require('../models/User');

// Middleware to verify Firebase token
const verifyFirebaseToken = async (req, res, next) => {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Missing or invalid auth header' });
    }
    
    const token = authHeader.replace('Bearer ', '');
    
    try {
        const decodedToken = await admin.auth().verifyIdToken(token);
        req.user = decodedToken;
        next();
    } catch (error) {
        return res.status(401).json({ error: 'Token verification failed' });
    }
};

// Register endpoint
router.post('/register', async (req, res) => {
    try {
        const { idToken } = req.body;
        
        // Verify token
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const { uid, email, name, picture } = decodedToken;
        
        // Find or create user
        let user = await User.findOne({ firebaseUid: uid });
        
        if (user) {
            // Update existing user
            user.email = email;
            user.displayName = name;
            user.photoUrl = picture;
            await user.save();
        } else {
            // Create new user
            user = new User({
                firebaseUid: uid,
                email,
                displayName: name,
                photoUrl: picture
            });
            await user.save();
        }
        
        res.json({
            success: true,
            userId: user._id,
            email: user.email
        });
    } catch (error) {
        console.error('Auth error:', error);
        res.status(401).json({ error: 'Authentication failed' });
    }
});

// Protected route example
router.get('/profile', verifyFirebaseToken, async (req, res) => {
    try {
        const user = await User.findOne({ firebaseUid: req.user.uid });
        
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        res.json(user);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch profile' });
    }
});

module.exports = router;
```

## Go / Gin Example

```go
// backend/handlers/auth.go

package handlers

import (
    "context"
    "net/http"
    "strings"
    
    "firebase.google.com/go/auth"
    "github.com/gin-gonic/gin"
    "yourapp/models"
    "yourapp/db"
)

type TokenRequest struct {
    IDToken string `json:"idToken"`
}

// RegisterWithFirebase registers or authenticates user
func RegisterWithFirebase(authClient *auth.Client) gin.HandlerFunc {
    return func(c *gin.Context) {
        var req TokenRequest
        
        if err := c.ShouldBindJSON(&req); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }
        
        // Verify token
        token, err := authClient.VerifyIDToken(context.Background(), req.IDToken)
        if err != nil {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
            return
        }
        
        claims := token.Claims
        uid := token.UID
        email := claims["email"].(string)
        
        // Find or create user
        user, err := db.FindUserByFirebaseUID(uid)
        if err != nil {
            // Create new user
            user = &models.User{
                FirebaseUID: uid,
                Email:       email,
            }
            err = db.CreateUser(user)
        } else {
            // Update user
            user.Email = email
            err = db.UpdateUser(user)
        }
        
        if err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save user"})
            return
        }
        
        c.JSON(http.StatusOK, gin.H{
            "success": true,
            "userId":  user.ID,
            "email":   user.Email,
        })
    }
}

// VerifyToken middleware
func VerifyFirebaseToken(authClient *auth.Client) gin.HandlerFunc {
    return func(c *gin.Context) {
        authHeader := c.GetHeader("Authorization")
        
        if !strings.HasPrefix(authHeader, "Bearer ") {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Missing token"})
            c.Abort()
            return
        }
        
        token := strings.TrimPrefix(authHeader, "Bearer ")
        decodedToken, err := authClient.VerifyIDToken(context.Background(), token)
        
        if err != nil {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
            c.Abort()
            return
        }
        
        c.Set("uid", decodedToken.UID)
        c.Next()
    }
}
```

---

## Common Issues & Solutions

### "Certificate not found"
- Ensure service account key is properly loaded
- Check file path is correct
- Verify JSON format

### "Token has expired"
- Tokens are valid for 1 hour
- Call `refreshIdToken()` on frontend before sending
- Implement token refresh mechanism

### "CORS errors when calling backend"
- Add CORS headers to backend responses
- Whitelist Flutter app domain in Firebase Console
- Use proper Content-Type headers

### Token verification fails despite valid token
- Ensure Firebase Admin SDK is initialized before verifying
- Check you're using the correct project credentials
- Verify token is complete (sometimes gets truncated in logs)
