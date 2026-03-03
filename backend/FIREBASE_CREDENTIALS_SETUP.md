# Firebase Backend Credentials Setup

All Firebase credentials should be configured in your `.env` file. This guide explains each credential and where to find it.

## Required Credentials

### 1. **FIREBASE_PROJECT_ID** (Required)
- **What it is:** Your Firebase project's unique identifier
- **Where to find it:**
  1. Go to [Firebase Console](https://console.firebase.google.com)
  2. Select your project
  3. Click ⚙️ Settings icon → Project Settings
  4. Copy the **Project ID** field
- **Example:** `ecotrack-efd6e`
- **Status:** ✅ Already configured in `.env`

```env
FIREBASE_PROJECT_ID=ecotrack-efd6e
```

---

### 2. **FIREBASE_CREDENTIALS_PATH** (Optional but Recommended)
- **What it is:** Path to your service account key JSON file
- **When needed:** If you want to authenticate with a service account (more secure for production)
- **When not needed:** If running on Google Cloud (Cloud Run, Cloud Functions, App Engine) with default credentials
- **Where to get it:**
  1. Go to Firebase Console → Project Settings
  2. Click the **Service Accounts** tab
  3. Click **Generate New Private Key**
  4. Save the JSON file as `serviceAccountKey.json` in the backend root directory
  5. In `.env`, set: `FIREBASE_CREDENTIALS_PATH=./serviceAccountKey.json`
- **Example:**
```env
FIREBASE_CREDENTIALS_PATH=./serviceAccountKey.json
```

> ⚠️ **Important:** Add `serviceAccountKey.json` to `.gitignore`! Never commit this file.

---

### 3. **FIREBASE_API_KEY** (Optional)
- **What it is:** Your Firebase Web API key
- **Where to find it:**
  1. Firebase Console → Project Settings → General tab
  2. Look for the **Web API Key** field
- **When needed:** For client-side operations (already in Flutter app, less critical for backend)
- **Example:**
```env
FIREBASE_API_KEY=AIzaSyBtpTKlM02RgMVKDlTsDfzDUYdopO7gUks
```

---

### 4. **FIREBASE_DATABASE_URL** (Optional)
- **What it is:** URL for Firebase Realtime Database
- **Where to find it:**
  1. Firebase Console → Realtime Database
  2. Copy the database URL from the top of the page
- **When needed:** Only if using Firebase Realtime Database
- **Example:**
```env
FIREBASE_DATABASE_URL=https://ecotrack-efd6e.firebaseio.com
```

---

### 5. **FIREBASE_STORAGE_BUCKET** (Optional)
- **What it is:** Your Cloud Storage bucket name
- **Where to find it:**
  1. Firebase Console → Storage
  2. Copy the bucket name (format: `project-id.appspot.com`)
- **When needed:** Only if using Firebase Cloud Storage
- **Example:**
```env
FIREBASE_STORAGE_BUCKET=ecotrack-efd6e.appspot.com
```

---

## Current .env Configuration

Your `.env` file should look like this:

```env
PROJECT_NAME="CoinTrack API"
VERSION="1.0.0"
API_V1_STR="/api/v1"

# Security
SECRET_KEY="your-super-secret-key-change-in-production"
ALGORITHM="HS256"
ACCESS_TOKEN_EXPIRE_MINUTES=11520

# MySQL Database
MYSQL_USER=root
MYSQL_PASSWORD=7459
MYSQL_SERVER=localhost
MYSQL_PORT=3306
MYSQL_DB=cointrack_db
DATABASE_URL="mysql+pymysql://root:7459@localhost:3306/cointrack_db"

# Firebase Configuration
FIREBASE_PROJECT_ID=ecotrack-efd6e
FIREBASE_CREDENTIALS_PATH=
FIREBASE_API_KEY=AIzaSyBtpTKlM02RgMVKDlTsDfzDUYdopO7gUks
FIREBASE_DATABASE_URL=https://ecotrack-efd6e.firebaseio.com
FIREBASE_STORAGE_BUCKET=ecotrack-efd6e.appspot.com

# External (Placeholders)
BASE_RPC_URL=https://mainnet.base.org
HF_API_KEY=your_huggingface_key
```

---

## How the Backend Uses These Credentials

### 1. **Project ID (Required)**
Used to verify Firebase ID tokens sent from your Flutter app:
```python
# Automatically used by Firebase Admin SDK
# Token verification ensures the token is:
# - Signed by Google
# - Issued for your project
# - Not expired
# - Matches your project ID
```

### 2. **Service Account Key (Optional)**
Used for additional operations if needed:
```python
from firebase_admin import credentials, auth

# If using service account:
# - Can create custom tokens
# - Can manage users in Firebase Auth
# - Can access Realtime Database
# - Higher permission level
```

### 3. **Default Credentials** (Automatic)
If no service account key is provided, the SDK will:
- Try `GOOGLE_APPLICATION_CREDENTIALS` environment variable
- Try `serviceAccountKey.json` in backend root
- Use default credentials (for Google Cloud environments)

---

## Testing Your Setup

### 1. **Check if Firebase is initialized correctly:**
```bash
cd backend/
python -m uvicorn app.main:app --reload
```

You should see:
```
✓ Firebase Admin SDK initialized with default credentials (Project: ecotrack-efd6e)
```

### 2. **Test token verification:**
```python
# Send a request from Flutter, check backend logs
# If it works, you'll see: "✓ Token verified successfully"
# If it fails, you'll see the error in the logs
```

---

## Security Best Practices

✅ **DO:**
- Use `.env` files to store sensitive credentials
- Add `serviceAccountKey.json` to `.gitignore`
- Use different service account keys for different environments (dev, staging, prod)
- Rotate service account keys periodically
- Enable API key restrictions in Firebase Console

❌ **DON'T:**
- Commit `.env` files to git
- Hardcode credentials in Python files
- Share `serviceAccountKey.json` files
- Use production keys in development
- Expose credentials in logs or error messages

---

## Next Steps

1. ✅ **FIREBASE_PROJECT_ID** is already set: `ecotrack-efd6e`
2. ⏳ **FIREBASE_CREDENTIALS_PATH** is optional (empty for now = using default credentials)
3. ✅ **FIREBASE_API_KEY** is set
4. ✅ **FIREBASE_DATABASE_URL** and **FIREBASE_STORAGE_BUCKET** are set

Your backend should now work with Firebase Auth! Run the backend and test the authentication flow from your Flutter app.

---

## Troubleshooting

### Error: "FIREBASE_PROJECT_ID not set"
**Solution:** Add `FIREBASE_PROJECT_ID=ecotrack-efd6e` to your `.env` file

### Error: "Failed to verify token"
**Possible causes:**
1. Token is expired (tokens are valid for 1 hour)
2. Token is from a different Firebase project
3. Backend project ID doesn't match token issuer
4. Token format is invalid

**Solution:** Check the token details in your Flutter logs, ensure project IDs match

### Error: "Cannot find service account key"
**Solutions:**
1. Leave `FIREBASE_CREDENTIALS_PATH` empty to use default credentials
2. Or download service account key and set the path correctly
3. Or run on Google Cloud (automatic credentials)

---

## Additional Resources

- [Firebase Admin SDK Python Documentation](https://firebase.google.com/docs/reference/admin/python)
- [Firebase Authentication Guide](https://firebase.google.com/docs/auth)
- [Service Account Setup](https://firebase.google.com/docs/admin/setup#initialize_the_sdk)
