# iOS Firebase/Google Sign-In Setup

## Fix PlatformException on iOS

If you're seeing a `PlatformException` when trying to sign in on iOS, follow these steps:

### Step 1: Verify GoogleService-Info.plist

1. **Check it exists in Xcode:**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Look for `GoogleService-Info.plist` in the file tree
   - It should be under the Runner folder

2. **If it's missing:**
   - Download from Firebase Console → Project settings → iOS app
   - Click "Download GoogleService-Info.plist"
   - Drag into Xcode under Runner folder
   - Check "Copy items if needed"
   - Check "Add to targets: Runner"
   - Click Add

3. **Verify it's added to Runner target:**
   - Click on `GoogleService-Info.plist` in Xcode
   - In the inspector panel on the right, ensure "Runner" is checked under Target Membership

### Step 2: Add URL Schemes to Info.plist

The URL schemes are necessary for Google Sign-In to work on iOS. They tell iOS how to handle the callback from Google.

✅ **Already added to `ios/Runner/Info.plist`:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.535383184685-ueol0pnl3nk8ubk8k8u8k8u8k8u8k8u8</string>
        </array>
    </dict>
</array>
```

This URL scheme should match your Firebase project's Google Sign-In configuration.

### Step 3: Update CocoaPods

```bash
cd ios

# Remove old pods
pod deintegrate

# Update pod specs
pod repo update

# Reinstall pods
pod install --repo-update

cd ..
```

### Step 4: Clean and Rebuild

```bash
# Clean Flutter build
flutter clean

# Clean Xcode build
cd ios
rm -rf Pods
rm Podfile.lock
pod install --repo-update
cd ..

# Get dependencies
flutter pub get

# Run the app
flutter run -d ios
```

### Step 5: Verify in Xcode

1. Open `ios/Runner.xcworkspace` (not .xcodeproj!)
2. Select Runner → Runner (the project)
3. Select Runner (the target)
4. Go to "Build Settings" tab
5. Search for "Bundle Identifier"
6. Verify it matches your Firebase project's iOS bundle ID
7. Should be: `com.example.aicointrack` (or whatever you configured)

### Step 6: Check Signing & Capabilities

1. In Xcode, select Runner target
2. Go to "Signing & Capabilities" tab
3. Ensure:
   - Team is selected (your Apple Developer account)
   - Bundle Identifier is correct
   - iOS Deployment Target is 11.0 or higher

---

## Common iOS Errors & Fixes

### Error: "PlatformException: 25: An internal error occurred"
**Cause:** GoogleService-Info.plist not found or URL schemes not configured

**Fix:**
- Verify GoogleService-Info.plist is in Xcode project
- Check URL schemes are in Info.plist
- Run `pod install --repo-update`
- Clean and rebuild

### Error: "PlatformException: 10: DEVELOPER_ERROR"
**Cause:** SHA certificate doesn't match Firebase configuration

**Fix (on macOS):**
```bash
# Get your development certificate's SHA1
security find-certificate -c "iPhone Developer" -p | \
  openssl x509 -inform DER -noout -fingerprint | \
  sed 's/://g' | sed 's/SHA1 Fingerprint=//' | tr '[:upper:]' '[:lower:]'
```

Then add this to your Firebase Console iOS app settings.

### Error: "PlatformException: 12: INVALID_CLIENT"
**Cause:** Bundle ID doesn't match Firebase configuration

**Fix:**
- Check your Xcode bundle identifier
- Go to Firebase Console → iOS app settings
- Verify bundle ID matches exactly
- Update if needed

### Error: "The operation couldn't be completed. (com.google.GIDSignIn error 2.)"
**Cause:** CocoaPods version issue or outdated dependencies

**Fix:**
```bash
cd ios
pod deintegrate
rm Podfile.lock
pod install --repo-update
cd ..
```

---

## Verify Setup is Correct

### Check 1: GoogleService-Info.plist exists
```bash
ls -la ios/Runner/GoogleService-Info.plist
# Should output the file, not "No such file"
```

### Check 2: Info.plist has URL schemes
```bash
grep -A 5 "CFBundleURLTypes" ios/Runner/Info.plist
# Should show your Google URL scheme
```

### Check 3: Bundle identifier matches
```bash
# Check Xcode bundle ID
grep -A 1 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | head -2

# Should match Firebase iOS app bundle ID
# Both should be: com.example.aicointrack
```

### Check 4: Firebase project is correct
- Firebase Project: `ecotrack-efd6e`
- iOS Bundle ID: Should match your bundle identifier
- Verify in Firebase Console → Project settings → iOS app

---

## Full Clean Build Process

If you're still having issues, try this nuclear option:

```bash
# 1. Clean everything
flutter clean
cd ios
rm -rf Pods
rm Podfile.lock
rm -rf Podfile
rm -rf .symlinks
rm -rf Flutter/Flutter.podspec
cd ..

# 2. Get fresh dependencies
flutter pub get

# 3. Reinstall CocoaPods
cd ios
pod install --repo-update
cd ..

# 4. Run the app
flutter run -d ios
```

---

## Test the Setup

Once you've completed the above:

```bash
flutter run -d ios
```

You should see:
1. ✅ App starts on iOS simulator/device
2. ✅ LoginPage displays with "Get Started" button
3. ✅ Clicking button opens Google Sign-In
4. ✅ Can select Google account
5. ✅ Returns to app with user profile

---

## Additional Resources

- [Google Sign-In for Flutter - iOS Setup](https://pub.dev/packages/google_sign_in#ios)
- [Firebase iOS Setup](https://firebase.flutter.dev/docs/installation/ios)
- [Flutter iOS Deployment](https://flutter.dev/docs/deployment/ios)
- [iOS URL Schemes Documentation](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme)

---

## Need Help?

If you're still seeing PlatformException:

1. **Check exact error message:**
   - Look at console output for the error code and message
   - Error codes like "25", "10", "12" have different causes (see above)

2. **Verify all prerequisites:**
   - GoogleService-Info.plist downloaded from Firebase
   - URL schemes added to Info.plist
   - Bundle identifier matches Firebase
   - iOS Deployment Target ≥ 11.0
   - Running on iOS simulator or device (not just flutter run)

3. **Check Firebase Console:**
   - Project: `ecotrack-efd6e`
   - iOS app is registered
   - Download latest GoogleService-Info.plist

4. **Clean rebuild:**
   - Follow the "Full Clean Build Process" above

---

**Status**: iOS setup guide complete
**Firebase Project**: ecotrack-efd6e
**Bundle ID**: com.example.aicointrack (verify this matches your project)
