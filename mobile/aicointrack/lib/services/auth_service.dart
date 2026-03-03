import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Authentication service that handles Firebase Auth operations
/// including Google Sign-In and token management.
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

  /// Sign out from Firebase and Google
  static Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
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
}
