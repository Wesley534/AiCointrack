// miniapp/cointrack/app/.well-known/assetlinks.json/route.ts
//
// Serves the Android Digital Asset Links file that Android uses to verify
// App Links for the CoinTrack Flutter app.
//
// Once deployed, this will be accessible at:
//   https://app.aicointrack.xyz/.well-known/assetlinks.json
//
// Android verifies this file at install time to confirm that
// https://app.aicointrack.xyz app links should open in
// com.example.aicointrack instead of a browser.
//
// ────────────────────────────────────────────────────────────────────────────
// HOW TO GET YOUR SHA-256 FINGERPRINT
// ────────────────────────────────────────────────────────────────────────────
// Run this on your local machine (not inside the project directory):
//
//   keytool -list -v \
//     -keystore ~/.android/debug.keystore \
//     -alias androiddebugkey \
//     -storepass android \
//     -keypass android
//
// Copy the SHA-256 line (looks like: AB:CD:EF:12:34:...) and paste it below.
// Remove the colons — Android expects the raw hex format WITHOUT colons.
// Example: "AB:CD:EF" becomes "ABCDEF"
//
// For production (release APK), also add your release keystore SHA-256.
// ────────────────────────────────────────────────────────────────────────────

export async function GET() {
  const assetLinks = [
    {
      relation: ["delegate_permission/common.handle_all_urls"],
      target: {
        namespace: "android_app",
        package_name: "com.example.aicointrack",
        sha256_cert_fingerprints: [
          // ⚠️  Replace this with your actual debug SHA-256 (no colons)
          // Run: keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
          "69:95:42:1E:E5:BB:8F:C8:1E:E2:6E:63:32:01:F3:AA:60:3E:4C:6D:B8:9C:D6:75:51:05:86:DB:44:62:5D:C3",

          // Add your release SHA-256 here when you have one
          // "REPLACE_WITH_YOUR_RELEASE_SHA256_NO_COLONS",
        ],
      },
    },
  ];

  return Response.json(assetLinks, {
    headers: {
      // Must be application/json — Android rejects other content types
      "Content-Type": "application/json",
      // Cache for 1 hour — Android caches this aggressively
      "Cache-Control": "public, max-age=3600",
    },
  });
}