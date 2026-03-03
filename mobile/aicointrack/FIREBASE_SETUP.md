# Flutter + Firebase Authentication Setup Guide

## Overview

This guide provides step-by-step instructions for setting up Firebase Authentication with Google Sign-In in your Flutter app. The implementation includes:

- ✅ Firebase initialization for all platforms (iOS, Android, Web, macOS, Linux, Windows)
- ✅ Google Sign-In authentication
- ✅ Full null safety support
- ✅ Cross-platform compatibility
- ✅ Error handling and loading states
- ✅ Firebase ID token retrieval for backend authentication
- ✅ Automatic auth state management

---

## Files Created/Modified

### 1. **pubspec.yaml** (Modified)
Added Firebase and Google Sign-In dependencies:
```yaml
dependencies:
  firebase_core: ^3.5.0
  firebase_auth: ^5.3.0
  google_sign_in: ^6.2.1
  http: ^1.2.0
```

### 2. **lib/main.dart** (Replaced)
- Firebase initialization with error handling
- Auth state stream listener for automatic navigation
- MaterialApp configuration with Material 3

### 3. **lib/firebase_options.dart** (New)
- Platform-specific Firebase configuration
- **TODO**: Replace placeholder values with your Firebase project credentials

### 4. **lib/services/auth_service.dart** (New)
Core authentication service with:
- `signInWithGoogle()` - Google Sign-In implementation
- `signOut()` - Sign out and cleanup
- `getIdToken()` - Get Firebase ID token for backend
- `refreshIdToken()` - Token refresh
- `authStateChanges()` - Listen to auth state changes
- Helper methods for user information

### 5. **lib/pages/login_page.dart** (New)
Login UI with:
- Google Sign-In button
- Error message display
- Loading state management
- Beautiful Material Design UI
- Information panel about authentication

### 6. **lib/pages/home_page.dart** (New)
Home page after login with:
- User profile display (name, email, photo)
- Firebase ID token display
- Token refresh functionality
- Sign-out button
- Token management for backend communication

### 7. **lib/services/api_service.dart** (New)
Backend API integration service:
- `registerUserWithBackend()` - Send ID token to backend
- `refreshAndSendToken()` - Refresh and sync token
- `fetchUserProfile()` - Get user data from backend
- Comprehensive error handling

---

## Setup Instructions

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create Project"
3. Name your project (e.g., "AICoinTrack")
4. Enable Google Analytics (optional)
5. Click "Create Project"

### Step 2: Register Apps in Firebase

#### For Android:
1. In Firebase Console, click "Add App" → "Android"
2. Package name: `com.example.aicointrack` (check your android/app/build.gradle)
3. Debug SHA-1: Run `./gradlew signingReport` in android/ folder
4. Copy the debug SHA-1 and paste it in Firebase
5. Download `google-services.json`
6. Place it in `android/app/`

#### For iOS:
1. In Firebase Console, click "Add App" → "iOS"
2. Bundle ID: `com.example.aicointrack` (check ios/Runner/Info.plist)
3. Download `GoogleService-Info.plist`
4. In Xcode: Right-click Runner → Add Files
5. Select `GoogleService-Info.plist` → Add to Runner target

### Step 3: Update firebase_options.dart

1. Open [Firebase Console Settings](https://console.firebase.google.com/project/_/settings/general)
2. Copy your Firebase project credentials:
   - API Key
   - App ID
   - Messaging Sender ID
   - Project ID
   - Auth Domain
   - Storage Bucket (if applicable)

3. Update `lib/firebase_options.dart`:
```dart
return FirebaseOptions(
  apiKey: 'YOUR_API_KEY',           // From Settings
  appId: 'YOUR_APP_ID',             // From Settings
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',  // From Settings
  projectId: 'YOUR_PROJECT_ID',     // From Settings
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',  // Usually projectId.firebaseapp.com
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',   // Optional
);
```

### Step 4: Enable Google Sign-In

1. In Firebase Console, go to "Authentication" → "Sign-in method"
2. Click "Google"
3. Enable it and configure OAuth consent screen if needed
4. Save

### Step 5: Configure Android

1. Open `android/app/build.gradle.kts`
2. Update `applicationId` (should match Firebase package name):
```kotlin
applicationId = "com.example.aicointrack"
```

3. Add to `android/app/build.gradle.kts` dependencies:
```kotlin
dependencies {
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.android.gms:play-services-auth")
}
```

4. Update `android/build.gradle.kts` to add Google Services plugin:
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

5. Apply plugin in `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")  // Add this
    id("dev.flutter.flutter-gradle-plugin")
}
```

### Step 6: Configure iOS

1. Ensure Flutter iOS build uses CocoaPods:
   ```bash
   cd ios
   pod deintegrate
   pod install --repo-update
   ```

2. Update `ios/Podfile` (if not auto-generated):
   ```ruby
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       target.build_configurations.each do |config|
         config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
           '$(inherited)',
           'PERMISSION_CAMERA=1',
         ]
       end
     end
   end
   ```

### Step 7: Get Dependencies

```bash
cd /home/wes/Desktop/projects/cointrack/mobile/aicointrack
flutter pub get
```

### Step 8: Run the App

```bash
flutter run
```

Or for specific platform:
```bash
flutter run -d android    # Android
flutter run -d ios        # iOS
flutter run -w             # Web
```

---

## How Authentication Flow Works

### Login Flow:
1. User opens app → Checks auth state (StreamBuilder in main.dart)
2. If not signed in → Shows LoginPage
3. User clicks "Sign in with Google"
4. Google Sign-In opens → User selects account
5. Firebase verifies credentials → Creates session
6. App navigates to HomePage
7. User info is displayed

### Home Page Features:
1. Displays user profile (name, email, photo)
2. Shows Firebase ID token (truncated for security)
3. Token can be refreshed
4. Token can be sent to backend API
5. Sign-out clears session

### Sign-Out Flow:
1. User clicks "Sign Out"
2. Firebase session cleared
3. Google Sign-In cleared
4. Redirected to LoginPage
5. Auth state updated in real-time

---

## Sending ID Token to Backend (Optional)

The Firebase ID token can be used to authenticate requests to your backend API.

### Backend Implementation Example (Python/FastAPI):

```python
from firebase_admin import auth
from fastapi import HTTPException, Header

async def register_user(idToken: str):
    """Verify Firebase ID token and register user in database"""
    try:
        # Verify the token with Firebase Admin SDK
        decoded_token = auth.verify_id_token(idToken)
        uid = decoded_token['uid']
        email = decoded_token['email']
        
        # Create user in your database
        user = User(
            firebase_uid=uid,
            email=email,
            display_name=decoded_token.get('name')
        )
        db.add(user)
        db.commit()
        
        return {"success": True, "userId": user.id}
    except auth.InvalidIdTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")
```

### From Frontend:

```dart
// In api_service.dart
await ApiService.registerUserWithBackend();
```

---

## Environment Variables (Optional)

To avoid hardcoding API URLs, use flutter_dotenv:

1. Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

2. Create `.env` file:
```
API_BASE_URL=https://your-api.com
```

3. Update `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(...);
  runApp(const MyApp());
}
```

---

## Troubleshooting

### "GoogleSignInException: 10: DEVELOPER_ERROR"
- Missing or incorrect SHA-1 fingerprint
- Run: `./gradlew signingReport`
- Add the Debug SHA-1 to Firebase Console

### "FirebaseException: [firebase_core/no-app]"
- Firebase not initialized properly
- Check firebase_options.dart values
- Ensure `Firebase.initializeApp()` called before runApp()

### iOS Build Fails
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install --repo-update
cd ..
flutter clean
flutter pub get
flutter run
```

### Token Verification Fails on Backend
- Token might be expired (valid for 1 hour)
- Use `refreshIdToken()` before sending
- Verify token with Firebase Admin SDK, not manually

### App Still Shows LoginPage After Sign-In
- Check StreamBuilder in main.dart
- Ensure `AuthService.authStateChanges()` is working
- Check Firebase rules aren't blocking operations

---

## Security Best Practices

✅ **DO:**
- Always verify tokens on backend with Firebase Admin SDK
- Use HTTPS for all API calls
- Never log or expose ID tokens in production
- Implement token refresh before expiry
- Use Firebase Security Rules for Firestore/Database
- Enable 2FA for Firebase Console

❌ **DON'T:**
- Hardcode API URLs in app (use environment variables)
- Trust tokens without server verification
- Store tokens in shared preferences (use secure storage)
- Use debug keys in production
- Expose error messages with sensitive details

---

## Next Steps

1. Replace placeholders in `firebase_options.dart`
2. Configure Firebase Console for your apps
3. Set up backend API integration with `api_service.dart`
4. Implement custom user profile features
5. Add logging/analytics
6. Test on physical devices
7. Submit to App Stores

---

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Firebase Plugin](https://firebase.flutter.dev/)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security)
- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)
