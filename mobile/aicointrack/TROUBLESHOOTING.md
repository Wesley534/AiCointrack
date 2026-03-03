# Firebase Google Sign-In Troubleshooting

## Platform-Specific Issues

### iOS: PlatformException

**Error:** `PlatformException: 25` or similar when clicking Sign-In

**Quick Fix:**
1. Verify `GoogleService-Info.plist` exists in Xcode (drag from Finder if missing)
2. Check URL schemes in `ios/Runner/Info.plist` are added
3. Run: `cd ios && pod install --repo-update && cd ..`
4. Clean and rebuild: `flutter clean && flutter run -d ios`

**Detailed Guide:** See [iOS_FIREBASE_SETUP.md](iOS_FIREBASE_SETUP.md)

---

### Android: "Lost connection to device" or "DEVELOPER_ERROR"

**Error:** App crashes or shows "DEVELOPER_ERROR" after clicking Sign-In

**Quick Fix:**
1. Get correct Debug SHA-1:
   ```bash
   cd android
   ./gradlew signingReport
   ```
2. Copy SHA-1 from output
3. Add to Firebase Console → Your Android app → SHA-1 certificates
4. Ensure `google-services.json` is in `android/app/`
5. Rebuild: `flutter clean && flutter run`

---

## Common Issues & Solutions

### Issue 1: App Shows "Firebase not configured" Error

**Cause:** Firebase credentials are placeholder values

**Solution:**
```dart
// Check firebase_options.dart
// Should have real values like:
apiKey: 'AIzaSyBtpTKlM02RgMVKDlTsDfzDUYdopO7gUks',
appId: '1:535383184685:android:a568344348097ff762efa4',
projectId: 'ecotrack-efd6e',
```

✅ **Already fixed** - your credentials are configured

---

### Issue 2: Google Sign-In Button Does Nothing

**Cause 1:** Firebase not initialized
- Check `main.dart` has `await Firebase.initializeApp(...)`
- Look for "Firebase initialized" message in console

**Cause 2:** Wrong configuration
- Verify `firebase_options.dart` has real credentials
- Check internet connection on device

**Cause 3:** Platform-specific config missing
- **Android:** Missing `google-services.json`
- **iOS:** Missing `GoogleService-Info.plist` or URL schemes

**Solution:**
```bash
# Check for config files
ls -la android/app/google-services.json    # Should exist
ls -la ios/Runner/GoogleService-Info.plist # Should exist

# If missing, download from Firebase Console and add them
```

---

### Issue 3: "Sign in with Google" Pop-up Closes Immediately

**Cause 1:** iOS URL schemes not configured
**Fix:** See [iOS_FIREBASE_SETUP.md](iOS_FIREBASE_SETUP.md) - Step 2

**Cause 2:** Android SHA-1 mismatch
**Fix:**
```bash
cd android && ./gradlew signingReport
# Copy SHA-1 and add to Firebase Console
```

---

### Issue 4: Backend Returns 401 "Invalid Token"

**Cause:** Token is expired (valid for 1 hour)

**Fix:**
1. Sign out and sign back in (fresh token)
2. Or call `refreshIdToken()` in Flutter:
```dart
String? newToken = await AuthService.refreshIdToken();
```

---

### Issue 5: Backend Can't Connect

**Cause 1:** Backend not running
```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --reload
```

**Cause 2:** Wrong backend URL in Flutter
Edit: `lib/services/api_service.dart`
```dart
static const String baseUrl = 'http://localhost:8000'; // Correct URL
```

**Cause 3:** CORS error
- Backend CORS is configured ✓
- Check backend logs for errors

---

## Diagnostic Steps

### Step 1: Check Firebase Initialization
Look for this in console when app starts:
```
✓ Firebase initialized successfully
```

If you see an error, check `firebase_options.dart` credentials.

### Step 2: Check Google Sign-In
Look for these logs when you click "Get Started":
```
Flutter: Signing in with Google...
Flutter: ID Token (send to backend): eyJ...
```

### Step 3: Check Backend Connection
Look for this log after sign-in:
```
Backend registration success: {...}
```

If not present, check:
- Backend URL in `api_service.dart`
- Backend is running on correct port
- Network connectivity

### Step 4: Check Token Verification
Backend should log:
```
User created/updated: user_id=1, email=...
```

If you see auth errors, token might be expired.

---

## Step-by-Step Diagnosis

### For iOS PlatformException:

```bash
# Step 1: Check GoogleService-Info.plist
ls -la ios/Runner/GoogleService-Info.plist
# If missing, download from Firebase

# Step 2: Check URL schemes in Info.plist
grep "CFBundleURLTypes" ios/Runner/Info.plist
# Should show your Google URL scheme

# Step 3: Update CocoaPods
cd ios
pod deintegrate
pod install --repo-update
cd ..

# Step 4: Clean and rebuild
flutter clean
flutter run -d ios
```

### For Android DEVELOPER_ERROR:

```bash
# Step 1: Get your SHA-1
cd android
./gradlew signingReport
# Copy the SHA-1 from "debug" output

# Step 2: Verify google-services.json exists
ls -la android/app/google-services.json
# If missing, download from Firebase

# Step 3: Add SHA-1 to Firebase Console
# Go to Firebase Console → Android app → SHA certificates
# Add the SHA-1 from Step 1

# Step 4: Rebuild
cd ..
flutter clean
flutter run
```

---

## Testing Checklist

### Before Testing:

- [ ] `firebase_options.dart` has real credentials
- [ ] `google-services.json` exists (Android)
- [ ] `GoogleService-Info.plist` exists (iOS)
- [ ] Backend is running (`uvicorn app.main:app`)
- [ ] Backend URL is correct in `api_service.dart`
- [ ] Device has internet connection

### During Testing:

1. **Start app:** Should see LoginPage
2. **Click "Get Started":** Should show sign-in popup
3. **Select Google account:** Should close popup and return to app
4. **Should see HomePage** with your profile
5. **Check backend logs** for user creation message

### If Stuck:

1. Check console for error messages
2. Follow diagnostic steps above for your platform
3. Clean build and try again
4. Check [iOS_FIREBASE_SETUP.md](iOS_FIREBASE_SETUP.md) or backend documentation

---

## File Locations

```
mobile/aicointrack/
├── lib/firebase_options.dart          # ✅ Has credentials
├── android/app/google-services.json   # ⏳ Need to verify
├── ios/Runner/GoogleService-Info.plist # ⏳ Need to verify
├── ios/Runner/Info.plist              # ✅ URL schemes added
└── lib/pages/login_page.dart          # ✅ Has error handling

backend/
├── app/main.py                        # ✅ Firebase init
├── app/core/firebase_init.py          # ✅ Admin SDK setup
├── app/api/v1/endpoints/auth.py       # ✅ Endpoints ready
└── requirements.txt                   # ✅ firebase-admin installed
```

---

## Quick Reference

| Platform | Issue | Fix |
|----------|-------|-----|
| iOS | PlatformException | Add URL schemes to Info.plist |
| iOS | Missing GoogleService-Info.plist | Download from Firebase, add to Xcode |
| iOS | "An internal error occurred" | Run `pod install --repo-update` |
| Android | DEVELOPER_ERROR | Add Debug SHA-1 to Firebase |
| Android | Missing google-services.json | Download from Firebase, place in android/app/ |
| Android | Lost connection | Check AndroidManifest.xml has internet permission |
| Both | "Firebase not configured" | Check firebase_options.dart credentials |
| Both | Backend 401 error | Token expired, sign out and back in |
| Both | Backend unreachable | Check baseUrl in api_service.dart, verify backend running |

---

## Contact Firebase Support

If you've tried everything above, you might need Firebase support:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click ⚙️ Settings
4. Go to "Help & Support" tab
5. Create a support case with:
   - Error message
   - Platform (iOS/Android)
   - Steps to reproduce
   - Firebase project ID: `ecotrack-efd6e`

---

**Last Updated:** March 2, 2026
**Project:** ecotrack-efd6e
**Status:** Troubleshooting Guide Ready
