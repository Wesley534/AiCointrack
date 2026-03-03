import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../config/constants.dart';

/// API service for backend communication
/// Handles sending Firebase ID token to backend for user registration/authentication
class ApiService {
  // Backend URL is configured in lib/config/constants.dart
  static const String baseUrl = AppConstants.BACKEND_URL;

  /// Register or authenticate user on the backend using Firebase ID token
  /// 
  /// This method retrieves the Firebase ID token from the current user
  /// and sends it to your backend API. Your backend should verify the token
  /// with Firebase Admin SDK and create/update the user in your database.
  /// 
  /// Example backend endpoint: POST /api/v1/auth/firebase/register
  /// 
  /// Request body:
  /// {
  ///   "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjE..."
  /// }
  /// 
  /// Response example:
  /// {
  ///   "success": true,
  ///   "userId": 123,
  ///   "email": "user@example.com",
  ///   "accessToken": "jwt_token_here"
  /// }
  static Future<Map<String, dynamic>> registerUserWithBackend() async {
    try {
      // Get the Firebase ID token
      final idToken = await AuthService.getIdToken();
      
      if (idToken == null) {
        throw Exception('No user signed in');
      }

      // Send token to backend
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/firebase/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idToken': idToken,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Backend registration failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to register user: $e');
    }
  }

  /// Refresh the ID token and send to backend
  /// Call this periodically to ensure token freshness
  static Future<String?> refreshAndSendToken() async {
    try {
      // Refresh the ID token
      final newToken = await AuthService.refreshIdToken();
      
      if (newToken == null) {
        throw Exception('Failed to refresh token');
      }

      // Optionally notify backend of token refresh
      await http.post(
        Uri.parse('$baseUrl/api/v1/auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $newToken',
        },
        body: jsonEncode({
          'idToken': newToken,
        }),
      );

      return newToken;
    } catch (e) {
      print('Failed to refresh token: $e');
      return null;
    }
  }

  /// Fetch user data from backend
  /// The backend should verify the ID token and return user profile data
  static Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      final idToken = await AuthService.getIdToken();
      
      if (idToken == null) {
        throw Exception('No user signed in');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/users/profile'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        // Token invalid or expired, user should re-authenticate
        await AuthService.signOut();
        throw Exception('Unauthorized - please sign in again');
      } else {
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }
}
