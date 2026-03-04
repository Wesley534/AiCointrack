import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'token_service.dart';

/// Authentication service that handles Firebase Auth operations
/// including Google Sign-In, Email/Password, Custom Token, and token management.
class AuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Sign in with Google using Firebase Authentication
  /// Returns the authenticated user or throws an exception
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Begin the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User canceled the sign-in
      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the Google user
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential using the Google tokens
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.message,
      );
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  /// Sign out from Firebase, Google, and clear stored JWT
  static Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      await TokenService.clearJwt();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Get the current signed-in user
  static User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  /// Get the Firebase ID token from the current user
  /// This token can be sent to your backend API for server-side authentication
  static Future<String?> getIdToken() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get ID token: $e');
    }
  }

  /// Refresh the ID token
  static Future<String?> refreshIdToken() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        return await user.getIdToken(true);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to refresh ID token: $e');
    }
  }

  /// Check if user is already signed in
  static bool isUserSignedIn() {
    return _firebaseAuth.currentUser != null;
  }

  /// Stream to listen to authentication state changes
  static Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  /// Sign in with email and password
  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Create account with email and password
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

  /// Sign in with Firebase custom token (from wallet login)
  static Future<UserCredential> signInWithCustomToken(String token) async {
    return await _firebaseAuth.signInWithCustomToken(token);
  }
}
