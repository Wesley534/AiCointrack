# Quick Start Guide

## 🚀 Start the App in 5 Minutes

### Terminal 1: Backend

```bash
cd /home/wes/Desktop/projects/cointrack/backend

# Activate virtual environment (firebase-admin already installed ✓)
source venv/bin/activate

# Run database migrations (first time only)
alembic upgrade head

# Start the backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Expected output:
```
✓ Firebase Admin SDK initialized with default credentials
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Terminal 2: Flutter App

```bash
cd /home/wes/Desktop/projects/cointrack/mobile/aicointrack

# Install dependencies (if needed)
flutter pub get

# Run the app
flutter run
```

Expected output:
```
✓ Flutter engine started
✓ App started
[LoginPage showing "Get Started" button]
```

---

## 🧪 Test the Sign-In

1. **Click "Get Started"** on the login page
2. **Select your Google account** in the popup
3. **Wait for navigation** to HomePage
4. **See your profile** with name, email, and photo
5. **Check backend logs** for user creation message

---

## ⚡ Important Notes

### Firebase Credentials
✅ Already configured in `firebase_options.dart`
- Project: `ecotrack-efd6e`
- API Key: Set
- App ID: Set

### Backend Database
⏳ First time only:
```bash
cd backend && alembic upgrade head
```

### Service Account Key
⏳ Optional (for production):
1. Get from Firebase Console → Settings → Service Accounts
2. Save as `backend/serviceAccountKey.json`
3. Restart backend

---

## 🔗 Test API Endpoints

```bash
# Backend health check
curl http://localhost:8000/

# Should respond:
# {"message": "Welcome to CoinTrack API", "status": "active"}
```

---

## 📱 App Features

- ✅ Google Sign-In authentication
- ✅ User profile display (name, email, photo)
- ✅ Firebase token management
- ✅ Backend token verification
- ✅ Dark theme (CoinTrack MVP design)
- ✅ Error handling and loading states
- ✅ Sign-out functionality

---

## 🐛 Troubleshooting

### Backend won't start
```bash
# Make sure venv is activated
source venv/bin/activate

# Check firebase-admin is installed
pip list | grep firebase

# Should show: firebase-admin  7.2.0
```

### App shows "Firebase not configured" error
- Check `firebase_options.dart` has correct values
- Verify Firebase credentials are in place

### Backend 401 Unauthorized
- Token might be expired (valid 1 hour)
- Try signing out and signing back in

### Database migration fails
```bash
# Check current state
alembic current

# Upgrade all pending migrations
alembic upgrade head
```

---

## 📊 Project Structure

```
/home/wes/Desktop/projects/cointrack/
├── backend/                          # FastAPI backend
│   ├── app/main.py                  # Entry point
│   ├── requirements.txt              # Dependencies (firebase-admin added ✓)
│   └── serviceAccountKey.json        # ← Download from Firebase Console
│
└── mobile/aicointrack/              # Flutter app
    ├── lib/main.dart                # Firebase initialization
    ├── lib/firebase_options.dart    # ← Already configured ✓
    └── lib/pages/login_page.dart    # Google Sign-In UI
```

---

## ✅ Checklist

Before testing:

- [x] Backend dependencies installed (firebase-admin ✓)
- [x] Flutter dependencies installed
- [x] Firebase credentials configured in Flutter
- [ ] Database migrations applied (`alembic upgrade head`)
- [x] Backend auth endpoints implemented
- [x] Frontend Google Sign-In implemented
- [x] Theme updated to MVP design

---

## 🎯 What Happens When You Sign In

1. **User clicks "Get Started"**
   - Flutter opens Google Sign-In popup

2. **User selects Google account**
   - Google returns authentication token
   - Firebase verifies and creates session

3. **Flutter gets Firebase ID token**
   - Valid for 1 hour
   - Sent to backend

4. **Backend verifies token**
   - Uses Firebase Admin SDK
   - Checks signature and expiration

5. **Backend creates/updates user**
   - Saves to Neon PostgreSQL database
   - Returns user info

6. **App shows HomePage**
   - Displays user profile
   - Shows Firebase ID token

---

**Everything is ready to run!** 🚀

Start with the Quick Start commands above.
