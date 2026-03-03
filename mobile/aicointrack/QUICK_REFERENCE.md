# Flutter Firebase Auth - Quick Reference

## Project Structure

```
lib/
├── main.dart                    # App entry point with Firebase init
├── firebase_options.dart        # Firebase credentials (REQUIRES SETUP)
├── pages/
│   ├── login_page.dart         # Google Sign-In UI
│   └── home_page.dart          # User profile & token display
└── services/
    ├── auth_service.dart       # Authentication logic
    └── api_service.dart        # Backend API communication
```

---

## Key Classes & Methods

### AuthService

```dart
// Sign in with Google
UserCredential? credential = await AuthService.signInWithGoogle();

// Sign out
await AuthService.signOut();

// Get current user
User? user = AuthService.getCurrentUser();

// Get ID token for backend
String? token = await AuthService.getIdToken();

// Refresh token
String? newToken = await AuthService.refreshIdToken();

// Check if signed in
bool isSignedIn = AuthService.isUserSignedIn();

// Listen to auth state changes
Stream<User?> authStream = AuthService.authStateChanges();
```

### ApiService

```dart
// Register user with backend
Map<String, dynamic> response = await ApiService.registerUserWithBackend();

// Get user profile from backend
Map<String, dynamic> profile = await ApiService.fetchUserProfile();

// Refresh and sync token
String? newToken = await ApiService.refreshAndSendToken();
```

---

## Quick Setup Checklist

- [ ] Create Firebase project in [Firebase Console](https://console.firebase.google.com)
- [ ] Register Android app (add Debug SHA-1)
- [ ] Register iOS app
- [ ] Enable Google Sign-In in Firebase Console → Authentication → Sign-in method
- [ ] Download `google-services.json` (Android)
- [ ] Download `GoogleService-Info.plist` (iOS)
- [ ] Update `firebase_options.dart` with your credentials
- [ ] Run `flutter pub get`
- [ ] Run `flutter run`
- [ ] Test Google Sign-In flow

---

## Getting Firebase Credentials

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click ⚙️ Settings icon → Project settings
4. Find these values:
   - **API Key** (under "Your web API key")
   - **App ID** (under "App ID")
   - **Messaging Sender ID** (under "Cloud Messaging")
   - **Project ID** (Project ID field)
   - **Auth Domain**: `PROJECT_ID.firebaseapp.com`
   - **Storage Bucket**: `PROJECT_ID.appspot.com` (optional)

---

## File Modifications Required

### 1. firebase_options.dart
Replace placeholder values with your Firebase credentials:
```dart
return FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
);
```

### 2. api_service.dart (Optional)
Update API base URL for your backend:
```dart
static const String baseUrl = 'https://your-api-domain.com';
```

### 3. Android Configuration
In `android/app/build.gradle.kts`:
```kotlin
applicationId = "com.example.aicointrack"  // Must match Firebase
```

---

## Common Flutter Commands

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Run on specific device
flutter run -d android
flutter run -d ios

# Clean build
flutter clean
flutter pub get
flutter run

# Build APK (Android)
flutter build apk --release

# Build iOS app
flutter build ios --release

# Show connected devices
flutter devices
```

---

## Firebase ID Token Info

The ID token contains:
```json
{
  "iss": "https://securetoken.google.com/your-project-id",
  "aud": "your-project-id",
  "auth_time": 1234567890,
  "user_id": "unique_user_id",
  "sub": "unique_user_id",
  "iat": 1234567890,
  "exp": 1234571490,
  "email": "user@example.com",
  "email_verified": false,
  "firebase": {
    "identities": {
      "google.com": ["123456789"]
    },
    "sign_in_provider": "google.com"
  }
}
```

**Valid for**: 1 hour
**Use**: Send to backend for authentication
**Refresh**: Call `refreshIdToken()` when expired

---

## Error Handling

### Sign-In Errors
```dart
try {
  await AuthService.signInWithGoogle();
} on FirebaseAuthException catch (e) {
  print('Firebase error: ${e.code}');
  // Handle specific error codes
} catch (e) {
  print('Other error: $e');
}
```

### Backend Request Errors
```dart
try {
  await ApiService.registerUserWithBackend();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

---

## Platform-Specific Setup

### Android
1. Run: `./gradlew signingReport`
2. Copy Debug SHA-1
3. Add to Firebase Console → Project settings → Your apps
4. Download `google-services.json`
5. Place in `android/app/`

### iOS
1. Download `GoogleService-Info.plist`
2. Open Xcode: `open ios/Runner.xcworkspace`
3. Right-click Runner → Add Files
4. Select `GoogleService-Info.plist`
5. Ensure it's added to Runner target

### Web
1. Add Firebase config to `web/index.html`
2. Enable Google Sign-In in Firebase Console
3. Add redirect URLs to OAuth consent screen

---

## Testing Checklist

- [ ] App starts without crashes
- [ ] LoginPage displays correctly
- [ ] Google Sign-In button works
- [ ] Successful login redirects to HomePage
- [ ] User info displays on HomePage
- [ ] ID token is visible
- [ ] Sign-out works and returns to LoginPage
- [ ] Closing and reopening app keeps user logged in
- [ ] Token refresh works

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Developer Error" on Android | Add correct Debug SHA-1 to Firebase |
| iOS build fails | Run `pod install --repo-update` in ios/ |
| "No App" error | Check firebase_options.dart values |
| Token always null | Ensure user is signed in first |
| Backend 401 errors | Token might be expired, call refreshIdToken() |
| CORS errors | Configure CORS on backend |

---

## Security Tips

✅ Use `getIdToken()` to get fresh tokens
✅ Always verify tokens on backend
✅ Use HTTPS for all API calls
✅ Set Firebase Security Rules
✅ Enable 2FA for Firebase Console
✅ Keep `google-services.json` and `GoogleService-Info.plist` in `.gitignore`
✅ Use environment variables for sensitive config

❌ Don't hardcode API URLs
❌ Don't log tokens in production
❌ Don't trust tokens without server verification
❌ Don't commit service account keys
❌ Don't expose error details to users

---

## Useful Links

- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [FlutterFire GitHub](https://github.com/firebase/flutterfire)
- [Google Sign-In Package](https://pub.dev/packages/google_sign_in)
- [Firebase Console](https://console.firebase.google.com)
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security)
- [Dart Null Safety Guide](https://dart.dev/null-safety)
