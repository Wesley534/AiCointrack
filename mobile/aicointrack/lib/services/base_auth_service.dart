import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'token_service.dart';
import '../main.dart' show navigatorKey;
import '../pages/home_page.dart';

/// Handles "Sign in with Base" using the miniapp /login page.
///
/// Flow:
///   1. Opens https://cointrack-nu.vercel.app/login?redirect=aicointrack
///      in an in-app browser tab (flutter_web_auth_2).
///   2. The web page connects the user's Base smart wallet, builds a SIWE
///      message, requests a passkey-backed signature, then redirects to
///      aicointrack://login?address=…&message=…&signature=…
///   3. flutter_web_auth_2 intercepts that redirect (it matches the scheme
///      registered in AndroidManifest.xml / CFBundleURLSchemes) and returns
///      the full URL to this service.
///   4. We parse address, message, signature from the URL, call
///      POST /api/v1/auth/wallet on the backend, store the returned JWT (and
///      optionally sign into Firebase with the custom token), then return true.
///
/// On user cancellation (back-press in the browser) the method returns false
/// without throwing.
class BaseAuthService {
  /// The callback URL scheme that the miniapp will redirect to.
  /// Must match the deep-link scheme registered in AndroidManifest.xml.
  static const String _callbackScheme = 'aicointrack';

  /// Full URL of the miniapp login page.
  static const String _loginUrl =
      'https://cointrack-nu.vercel.app/login?redirect=$_callbackScheme';

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Opens the Base smart-wallet login page and, on success, stores the JWT
  /// and optionally creates a Firebase session.
  ///
  /// Returns `true` on success, `false` if the user cancelled without error.
  /// Throws on unrecoverable network / backend errors so the caller can surface
  /// a specific message.
  static Future<bool> loginWithBase(BuildContext context) async {
    try {
      debugPrint('BaseAuth: loginWithBase start -> opening $_loginUrl');
      // ── 1. Open the miniapp /login page ─────────────────────────────────────
      final resultUrl = await FlutterWebAuth2.authenticate(
        url: _loginUrl,
        callbackUrlScheme: _callbackScheme,
        options: const FlutterWebAuth2Options(
          // Keep the browser session alive so the passkey/Face-ID flow works.
          preferEphemeral: false,
          // Do NOT use ephemeralIntentFlags — on some Android OEMs (Infinix,
          // Tecno, etc.) FLAG_ACTIVITY_NO_HISTORY prevents the Custom Tab
          // from properly forwarding the aicointrack:// redirect to the
          // CallbackActivity, causing the WebView to hang instead of dismissing.
        ),
      );

      // ── 2. Parse the callback URL ────────────────────────────────────────────
      // Expected: aicointrack://login?address=0x…&message=…&signature=0x…
      final uri = Uri.parse(resultUrl);
      debugPrint('BaseAuth: callback uri received path=${uri.path} host=${uri.host}');

      final address = uri.queryParameters['address'];
      // The miniapp URL-encodes the message via URLSearchParams; Uri.parse
      // automatically percent-decodes query values for us.
      final message = uri.queryParameters['message'];
      final signature = uri.queryParameters['signature'];

      if (address == null || message == null || signature == null) {
        throw const FormatException(
          'Callback URL is missing required parameters (address / message / signature).',
        );
      }

      debugPrint('✓ BaseAuth: received callback for $address');

      // ── 3. Send to backend ───────────────────────────────────────────────────
      final data = await ApiService.walletLogin(
        address: address,
        signature: signature,
        message: message,
      );

      // ── 4. Store JWT ─────────────────────────────────────────────────────────
      final jwt = (data['jwt'] ?? data['accessToken']) as String?;
      if (jwt == null || jwt.isEmpty) {
        throw Exception(
          data['detail']?.toString() ?? 'No token returned from backend.',
        );
      }
      await TokenService.saveJwt(jwt);
      debugPrint('✓ BaseAuth: JWT stored (length=${jwt.length})');

      // ── 5. Optionally sign into Firebase ─────────────────────────────────────
      final firebaseToken = data['firebase_custom_token'] as String?;
      if (firebaseToken != null && firebaseToken.isNotEmpty) {
        try {
          await AuthService.signInWithCustomToken(firebaseToken);
          debugPrint('✓ BaseAuth: Firebase custom-token sign-in complete');
        } catch (e) {
          debugPrint('BaseAuth: Firebase custom-token sign-in skipped: $e');
        }
      } else {
        debugPrint('BaseAuth: no firebase_custom_token returned (JWT-only session)');
      }

      // ── 6. Force navigation regardless of stream timing ──────────────────────
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        debugPrint('BaseAuth: forcing navigation to HomePage using navigatorKey');
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      } else {
        debugPrint('BaseAuth: navigatorKey context unavailable; relying on auth stream/FutureBuilder');
      }

      debugPrint('BaseAuth: loginWithBase success');
      return true;
    } on PlatformException catch (e) {
      // flutter_web_auth_2 throws PlatformException(code: 'CANCELED') when the
      // user dismisses the browser tab without completing the flow.
      if (e.code == 'CANCELED' || e.code == 'USER_CANCELED') {
        debugPrint('BaseAuth: User cancelled (${e.message})');
        return false;
      }
      // Any other platform error (e.g. missing URL scheme) — re-throw.
      rethrow;
    } catch (e, stack) {
      // Re-throw real errors so the LoginPage can show an error banner.
      debugPrint('BaseAuth: unexpected error: $e\n$stack');
      rethrow;
    }
  }
}
