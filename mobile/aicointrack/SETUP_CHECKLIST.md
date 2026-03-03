# Firebase Setup Checklist

Complete this checklist to set up Firebase Authentication for your Flutter app.

## 📋 Phase 1: Firebase Project Setup

### Create Firebase Project
- [ ] Go to [Firebase Console](https://console.firebase.google.com/)
- [ ] Click "Create Project"
- [ ] Enter project name: `aicointrack` (or your preferred name)
- [ ] Choose region (keep default or select closer to your users)
- [ ] Enable/Disable Google Analytics (optional)
- [ ] Click "Create Project"
- [ ] Wait for project to be ready

### Get Firebase Credentials
- [ ] In Firebase Console, click ⚙️ (Settings) in top-left
- [ ] Go to "Project settings"
- [ ] Under "General" tab, find:
  - [ ] Copy **Project ID** → Keep safe
  - [ ] Copy **API Key** → Keep safe
  - [ ] Copy **App ID** → Keep safe
  - [ ] Copy **Messaging Sender ID** → Keep safe
  
### Enable Google Sign-In
- [ ] In Firebase Console, go to "Authentication"
- [ ] Click "Get started" if needed
- [ ] Go to "Sign-in method" tab
- [ ] Click on "Google"
- [ ] Toggle "Enable"
- [ ] Set project name in support email field
- [ ] Click "Save"

---

## 📱 Phase 2: Android Setup

### Get Debug SHA-1
- [ ] Open terminal in `mobile/aicointrack/android/`
- [ ] Run: `./gradlew signingReport`
- [ ] Look for "SHA-1" in output under "debug" config
- [ ] Copy the SHA-1 value

### Register Android App in Firebase
- [ ] In Firebase Console, click "Add App" → "Android"
- [ ] Android package name: Check in `android/app/build.gradle.kts`
  - [ ] Look for `applicationId = "com.example..."`
  - [ ] Use that as package name
- [ ] Debug SHA-1: Paste the SHA-1 from previous step
- [ ] App nickname (optional): `AICoinTrack Android`
- [ ] Click "Register app"

### Download & Place google-services.json
- [ ] Click "Download google-services.json"
- [ ] Save file
- [ ] Place in: `mobile/aicointrack/android/app/google-services.json`
- [ ] ⚠️ Add to `.gitignore`: `android/app/google-services.json`

### Update Gradle Files
- [ ] Open `android/build.gradle.kts` (project level)
- [ ] In `plugins` section, add:
  ```kotlin
  id("com.google.gms.google-services") version "4.4.0" apply false
  ```
- [ ] Open `android/app/build.gradle.kts`
- [ ] In `plugins` section, add:
  ```kotlin
  id("com.google.gms.google-services")
  ```
- [ ] Ensure `applicationId` matches Firebase package name

---

## 🍎 Phase 3: iOS Setup

### Register iOS App in Firebase
- [ ] In Firebase Console, click "Add App" → "iOS"
- [ ] iOS bundle ID: Check in `ios/Runner/Info.plist`
  - [ ] Look for `CFBundleIdentifier`
  - [ ] Use that value
- [ ] App store ID (optional, leave blank for now)
- [ ] App nickname (optional): `AICoinTrack iOS`
- [ ] Click "Register app"

### Download & Place GoogleService-Info.plist
- [ ] Click "Download GoogleService-Info.plist"
- [ ] Save file
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Right-click "Runner" folder → "Add Files to Runner"
- [ ] Select `GoogleService-Info.plist`
- [ ] Check "Copy items if needed"
- [ ] Check "Add to targets: Runner"
- [ ] Click "Add"
- [ ] ⚠️ Add to `.gitignore`: `ios/**/GoogleService-Info.plist`

### Update iOS Configuration
- [ ] In terminal: `cd mobile/aicointrack/ios`
- [ ] Run: `pod install --repo-update`
- [ ] If issues, try: `pod deintegrate && pod install --repo-update`
- [ ] Wait for completion

---

## 🔧 Phase 4: Flutter Configuration

### Update firebase_options.dart
- [ ] Open `lib/firebase_options.dart`
- [ ] Replace these placeholders with your actual credentials:
  ```dart
  return FirebaseOptions(
    apiKey: 'YOUR_API_KEY',              // From Project Settings
    appId: 'YOUR_APP_ID',                // From Project Settings
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',  // From Project Settings
    projectId: 'YOUR_PROJECT_ID',        // From Project Settings
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',  // Auto-generated
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',   // Optional
  );
  ```
- [ ] Save file

### Install Dependencies
- [ ] In terminal: `cd mobile/aicointrack`
- [ ] Run: `flutter clean`
- [ ] Run: `flutter pub get`
- [ ] Wait for dependencies to download

---

## 🧪 Phase 5: Testing

### Build & Run
- [ ] Connect Android device or emulator
- [ ] Run: `flutter run`
- [ ] Wait for build to complete
- [ ] App should launch showing LoginPage

### Test Sign-In Flow
- [ ] Click "Sign in with Google" button
- [ ] Select your Google account
- [ ] Verify app navigates to HomePage
- [ ] Check user name/email display
- [ ] Verify token is visible

### Test Sign-Out Flow
- [ ] Click sign-out button on HomePage
- [ ] Verify return to LoginPage
- [ ] Click sign-in again to test multiple times

### Test Session Persistence
- [ ] Sign in with Google
- [ ] Close the app completely (swipe away)
- [ ] Reopen the app
- [ ] Verify user is still logged in (HomePage shows)
- [ ] No need to sign in again

### Test Token Refresh
- [ ] On HomePage, click refresh icon near token
- [ ] Verify token is updated
- [ ] Check console for success message

---

## 📋 Phase 6: Optional - Backend Integration

### Configure API Service
- [ ] Open `lib/services/api_service.dart`
- [ ] Update `baseUrl` to your backend API:
  ```dart
  static const String baseUrl = 'https://your-api-domain.com';
  ```

### Implement Backend Token Verification
- [ ] Choose your backend language:
  - [ ] Python/FastAPI → See `FIREBASE_BACKEND_SETUP.md`
  - [ ] Node.js/Express → See `FIREBASE_BACKEND_SETUP.md`
  - [ ] Go/Gin → See `FIREBASE_BACKEND_SETUP.md`
- [ ] Set up Firebase Admin SDK on backend
- [ ] Create `/api/v1/auth/register` endpoint
- [ ] Test token verification with sample token

### Test Backend Integration
- [ ] Update `api_service.dart` with correct backend URL
- [ ] After sign-in, call: `await ApiService.registerUserWithBackend();`
- [ ] Verify user is created in your database
- [ ] Check token is properly verified on backend

---

## 🔐 Phase 7: Security & Production

### Security Checklist
- [ ] ✅ `.gitignore` includes:
  - [ ] `android/app/google-services.json`
  - [ ] `ios/**/GoogleService-Info.plist`
  - [ ] Service account keys (if using backend)
- [ ] ✅ Never commit Firebase config files
- [ ] ✅ Review Firebase Security Rules
- [ ] ✅ Enable 2FA for Firebase Console account
- [ ] ✅ Set up Firebase App Check (optional, but recommended)
- [ ] ✅ Review authentication error messages (don't expose sensitive info)

### Production Build
- [ ] [ ] Create release keystore for Android
- [ ] [ ] Sign APK/AAB with production key
- [ ] [ ] Register production SHA-1 in Firebase
- [ ] [ ] Generate iOS distribution certificate
- [ ] [ ] Test on physical devices
- [ ] [ ] Test in production Firebase environment

---

## ✅ Verification Checklist

### Files Exist
- [ ] `lib/main.dart` - Updated with Firebase init
- [ ] `lib/firebase_options.dart` - Has your credentials
- [ ] `lib/pages/login_page.dart` - Google Sign-In UI
- [ ] `lib/pages/home_page.dart` - User profile page
- [ ] `lib/services/auth_service.dart` - Auth logic
- [ ] `lib/services/api_service.dart` - Backend API client
- [ ] `pubspec.yaml` - Has Firebase dependencies

### Firebase Console
- [ ] Project created
- [ ] Android app registered with SHA-1
- [ ] iOS app registered with bundle ID
- [ ] Google Sign-In enabled
- [ ] Configuration files downloaded
- [ ] Credentials updated in `firebase_options.dart`

### Project Configuration
- [ ] `google-services.json` in `android/app/`
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] `android/app/build.gradle.kts` updated
- [ ] iOS pods updated (`pod install`)
- [ ] `flutter pub get` completed
- [ ] No build errors when running `flutter run`

### Functionality
- [ ] LoginPage displays without errors
- [ ] Google Sign-In button works
- [ ] Sign-in redirects to HomePage
- [ ] User info displays correctly
- [ ] Sign-out returns to LoginPage
- [ ] Session persists after app restart
- [ ] Token is visible and can be refreshed

---

## 🆘 Troubleshooting

If something doesn't work, check:

### App crashes on startup
- [ ] Check `firebase_options.dart` credentials
- [ ] Verify `WidgetsFlutterBinding.ensureInitialized()` in main()
- [ ] Check Firebase initialization error in console logs

### "Developer Error" on Android
- [ ] Verify Debug SHA-1 is correct
- [ ] Ensure SHA-1 is added to Firebase Console
- [ ] Check `google-services.json` is in correct location

### iOS build fails
```bash
cd ios
pod deintegrate
pod install --repo-update
cd ..
flutter clean
flutter pub get
flutter run -d ios
```

### LoginPage instead of HomePage after sign-in
- [ ] Check `StreamBuilder` in main.dart
- [ ] Verify `AuthService.authStateChanges()` works
- [ ] Check browser logs for auth errors

### Token is null
- [ ] Ensure user is signed in first
- [ ] Check `getIdToken()` is called after sign-in
- [ ] Token is auto-refreshed, wait a moment if expired

### Backend 401 errors
- [ ] Token might be expired (valid 1 hour)
- [ ] Call `refreshIdToken()` before sending
- [ ] Verify backend token verification code
- [ ] Check Authorization header format

For more help, see:
- [ ] `FIREBASE_SETUP.md` - Detailed setup guide
- [ ] `QUICK_REFERENCE.md` - Quick lookup reference
- [ ] `FIREBASE_BACKEND_SETUP.md` - Backend examples
- [ ] `IMPLEMENTATION_SUMMARY.md` - Implementation overview

---

## 📝 Notes

Use this space to track your credentials (keep safe!):

```
Project Name: _______________________
Project ID: _______________________
API Key: _______________________
App ID: _______________________
Messaging Sender ID: _______________________
Auth Domain: _______________________

Android Package Name: _______________________
Android Debug SHA-1: _______________________

iOS Bundle ID: _______________________

Backend API URL: _______________________
```

---

**Status**: Ready to Start! ✅
**Last Updated**: March 2, 2026

Once all items are checked, you have a fully functional Firebase authentication system!
