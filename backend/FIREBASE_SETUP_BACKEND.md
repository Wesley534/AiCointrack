# Firebase Backend Setup Instructions

This guide walks you through setting up Firebase authentication on the CoinTrack backend.

## 📋 Prerequisites

- Python 3.8+
- Firebase project created (see mobile setup)
- MySQL database running

## 🚀 Quick Setup

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

This installs `firebase-admin` SDK along with other dependencies.

### 2. Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click ⚙️ Settings → Project settings
4. Go to "Service accounts" tab
5. Click "Generate new private key"
6. Save the JSON file as `serviceAccountKey.json`
7. **IMPORTANT**: Place it in the `backend/` root directory

```bash
# Your structure should look like:
backend/
  ├── serviceAccountKey.json  ← Place here
  ├── app/
  ├── alembic/
  └── requirements.txt
```

### 3. Add to .gitignore

Ensure `serviceAccountKey.json` is in your `.gitignore`:

```bash
echo "serviceAccountKey.json" >> .gitignore
```

### 4. Run Database Migrations

Apply the new Firebase fields to your database:

```bash
# Make sure your .env file has correct DATABASE_URL
alembic upgrade head
```

This adds these columns to the `users` table:
- `firebase_uid` (String, unique, indexed)
- `display_name` (String)
- `photo_url` (String)
- `updated_at` (DateTime)
- Makes `hashed_password` nullable

### 5. Start the Backend

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

You should see:
```
✓ Firebase Admin SDK initialized with serviceAccountKey.json
INFO:     Uvicorn running on http://0.0.0.0:8000
```

## 🔌 API Endpoints

### 1. Register/Login with Firebase

**POST** `/api/v1/auth/firebase/register`

Request:
```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIs..."
}
```

Response:
```json
{
  "success": true,
  "userId": 1,
  "email": "user@example.com",
  "message": "User created successfully",
  "accessToken": "jwt_token_here"
}
```

### 2. Verify Firebase Token

**POST** `/api/v1/auth/firebase/verify`

Headers:
```
Authorization: Bearer <firebase_id_token>
```

Response:
```json
{
  "valid": true,
  "uid": "firebase_user_id",
  "email": "user@example.com",
  "name": "John Doe"
}
```

### 3. Get User Profile

**GET** `/api/v1/auth/profile`

Headers:
```
Authorization: Bearer <firebase_id_token>
```

Response:
```json
{
  "id": 1,
  "email": "user@example.com",
  "display_name": "John Doe",
  "photo_url": "https://...",
  "created_at": "2026-03-02T10:30:00"
}
```

## 🧪 Testing

### Test with curl

```bash
# First, get a Firebase ID token from your Flutter app
# (Check console logs when signing in)

# Register user
curl -X POST http://localhost:8000/api/v1/auth/firebase/register \
  -H "Content-Type: application/json" \
  -d '{"idToken": "YOUR_FIREBASE_TOKEN"}'

# Verify token
curl -X POST http://localhost:8000/api/v1/auth/firebase/verify \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN"

# Get profile
curl -X GET http://localhost:8000/api/v1/auth/profile \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN"
```

### Test with Flutter

From your Flutter app, after signing in:

```dart
// This will automatically register the user on backend
final result = await ApiService.registerUserWithBackend();
print('Backend registration: $result');
```

## 🔐 Security Notes

### Production Checklist

- [ ] ✅ `serviceAccountKey.json` is in `.gitignore`
- [ ] ✅ Never commit service account key to git
- [ ] ✅ Use environment variables for sensitive config
- [ ] ✅ Enable CORS only for specific origins (not `*`)
- [ ] ✅ Use HTTPS in production
- [ ] ✅ Set up proper Firebase Security Rules
- [ ] ✅ Rotate service account keys periodically
- [ ] ✅ Monitor authentication logs

### CORS Configuration

The backend has CORS enabled for all origins (`*`) in development. For production:

```python
# In app/main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://your-app-domain.com"],  # Specific domain
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)
```

## 🔄 How It Works

1. **User signs in** on Flutter app with Google
2. **Flutter gets Firebase ID token** (valid for 1 hour)
3. **Flutter sends token** to backend `/api/v1/auth/firebase/register`
4. **Backend verifies token** with Firebase Admin SDK
5. **Backend creates/updates user** in MySQL database
6. **Backend returns JWT token** (optional, for additional security)
7. **Flutter stores JWT** for subsequent API calls

## 📊 Database Schema

```sql
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(255) UNIQUE NOT NULL,
  hashed_password VARCHAR(255),  -- Nullable for Firebase users
  full_name VARCHAR(255),
  firebase_uid VARCHAR(255) UNIQUE,  -- Firebase UID
  display_name VARCHAR(255),  -- From Firebase profile
  photo_url VARCHAR(500),  -- Profile picture URL
  is_active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
  INDEX ix_users_email (email),
  INDEX ix_users_firebase_uid (firebase_uid)
);
```

## 🐛 Troubleshooting

### "Firebase initialization failed"

**Problem**: Backend can't find `serviceAccountKey.json`

**Solution**:
- Verify file is in `backend/` root directory
- Check filename is exactly `serviceAccountKey.json`
- Verify JSON format is valid

### "Token verification failed"

**Problem**: Firebase token is invalid or expired

**Solution**:
- Tokens expire after 1 hour
- Call `refreshIdToken()` in Flutter before sending
- Ensure Firebase project IDs match

### "Database migration failed"

**Problem**: Alembic can't apply migration

**Solution**:
```bash
# Check current migration status
alembic current

# If stuck, downgrade and re-upgrade
alembic downgrade -1
alembic upgrade head

# Or start fresh (WARNING: loses data)
alembic downgrade base
alembic upgrade head
```

### "CORS error from Flutter"

**Problem**: Browser blocks request due to CORS

**Solution**:
- Ensure CORS is enabled in `main.py`
- Add your domain to `allow_origins`
- Check preflight OPTIONS requests are handled

### "User not found after registration"

**Problem**: User registered but profile endpoint returns 404

**Solution**:
- Check `firebase_uid` is being saved correctly
- Verify token contains `uid` claim
- Check database has the user record

## 📝 Environment Variables

Add to your `.env` file:

```bash
# Existing variables
PROJECT_NAME=CoinTrack API
VERSION=1.0.0
API_V1_STR=/api/v1
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# Database
DATABASE_URL=mysql+pymysql://user:password@localhost:3306/cointrack_db

# Optional: Specify service account key path
GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json
```

## 🚀 Deployment

### Using Docker

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Copy service account key (or use secrets)
COPY serviceAccountKey.json .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Using Cloud Run / App Engine

Set service account key as environment variable or use Workload Identity:

```bash
# Set as environment variable (base64 encoded)
export FIREBASE_SERVICE_ACCOUNT=$(cat serviceAccountKey.json | base64)

# Or use Google Cloud's Workload Identity
# https://cloud.google.com/run/docs/configuring/service-accounts
```

## ✅ Success Checklist

- [ ] Dependencies installed (`pip install -r requirements.txt`)
- [ ] Service account key downloaded and placed
- [ ] `.gitignore` updated to exclude service account key
- [ ] Database migrations applied (`alembic upgrade head`)
- [ ] Backend starts without errors
- [ ] Firebase initialization message appears
- [ ] Can register user from Flutter app
- [ ] Profile endpoint returns user data
- [ ] CORS configured for production

## 📚 Additional Resources

- [Firebase Admin Python SDK](https://firebase.google.com/docs/admin/setup)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Alembic Migrations](https://alembic.sqlalchemy.org/)
- [SQLAlchemy ORM](https://www.sqlalchemy.org/)

---

**Status**: Ready for Development ✅
**Last Updated**: March 2, 2026
