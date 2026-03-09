import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'token_service.dart';

/// Authentication service that handles Firebase Auth operations
/// including Google Sign-In, Email/Password, Custom Token (wallet), and JWT management.
class AuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─── Google Sign-In ────────────────────────────────────────────────────────

  /// Sign in with Google using Firebase Authentication.
  /// Returns the authenticated [UserCredential], or null if the user cancelled.
  /// Throws [FirebaseAuthException] or generic [Exception] on failure.
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the sign-in flow
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // ─── Email / Password ──────────────────────────────────────────────────────

  /// Sign in with email and password.
  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Create a new account with email and password.
  /// Optionally sets a display name immediately after account creation.
  static Future<UserCredential> createUserWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (displayName != null && displayName.isNotEmpty && cred.user != null) {
      await cred.user!.updateDisplayName(displayName);
    }
    return cred;
  }

  // ─── Wallet / Custom Token ─────────────────────────────────────────────────

  /// Sign in with a Firebase custom token.
  ///
  /// Used after a successful Base Wallet SIWE login: the backend returns a
  /// firebase_custom_token which is passed here so the Firebase auth stream
  /// also becomes authenticated (enabling features that depend on Firebase Auth).
  static Future<UserCredential> signInWithCustomToken(String token) async {
    return await _firebaseAuth.signInWithCustomToken(token);
  }

  // ─── Sign Out ──────────────────────────────────────────────────────────────

  /// Sign out from Firebase, Google, and clear stored JWT.
  /// Safe to call for any auth method (Google, email, or wallet).
  static Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      // Google sign-out is a no-op if the user didn't sign in with Google
      await _googleSignIn.signOut().catchError((_) {});
      await TokenService.clearJwt();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // ─── Token Management ──────────────────────────────────────────────────────

  /// Returns the Firebase ID token for the current user, or null if not signed in.
  /// This token should be sent to the backend for Firebase-authenticated endpoints.
  static Future<String?> getIdToken() async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken();
    } catch (e) {
      throw Exception('Failed to get ID token: $e');
    }
  }

  /// Forces a token refresh and returns the new token.
  /// Call this when the current token may have expired (tokens are valid 1 hour).
  static Future<String?> refreshIdToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        return await user.getIdToken(true);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to refresh ID token: $e');
    }
  }

  // ─── User State ────────────────────────────────────────────────────────────

  /// Returns the currently signed-in Firebase user, or null.
  static User? getCurrentUser() => _firebaseAuth.currentUser;

  /// Returns true if a Firebase user is currently signed in.
  static bool isUserSignedIn() => _firebaseAuth.currentUser != null;

  /// Raw Firebase auth state stream. Emits [User?] on every auth change.
  static Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  // ─── App-level Auth Stream ─────────────────────────────────────────────────

  /// Combined auth stream used by [main.dart]'s StreamBuilder to gate navigation.
  ///
  /// Emits `true` when the user is authenticated by EITHER:
  ///   - Firebase Auth (Google, email, or custom token after wallet login), OR
  ///   - A stored JWT (wallet-only users whose backend didn't return a
  ///     firebase_custom_token, e.g. when no service account is configured)
  ///
  /// This means wallet users who never get a Firebase session are still treated
  /// as signed-in as long as their JWT is present in SharedPreferences.
  static Stream<bool> appAuthStateChanges() async* {
    await for (final user in _firebaseAuth.authStateChanges()) {
      if (user != null) {
        // Firebase session active — always authenticated
        yield true;
      } else {
        // No Firebase session — fall back to JWT check for wallet-only users
        final jwt = await TokenService.getJwt();
        yield jwt != null && jwt.isNotEmpty;
      }
    }
  }
}