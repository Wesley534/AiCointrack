import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'login_page.dart';

/// Home page displayed after successful authentication
/// Shows user information and provides sign-out functionality
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late User? _user;
  String? _idToken;
  bool _isLoading = false;
  Map<String, dynamic>? _backendUserData;
  String? _backendError;

  @override
  void initState() {
    super.initState();
    _user = AuthService.getCurrentUser();
    _registerUserWithBackend();
  }

  /// Register user with backend using Firebase ID token
  /// This creates/updates the user in the database and gets backend user data
  Future<void> _registerUserWithBackend() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getIdToken();
      setState(() => _idToken = token);
      
      if (token != null) {
        print('ID Token obtained: ${token.substring(0, 20)}...');
        print('Sending token to backend...');
        
        // Call backend to register user
        final backendResponse = await ApiService.registerUserWithBackend();
        
        setState(() {
          _backendUserData = backendResponse;
          _backendError = null;
        });
        
        print('✓ Backend registration successful');
        print('Backend response: $backendResponse');
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Welcome ${_backendUserData?['email']}!'),
              backgroundColor: const Color(0xFF00E5A0),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('✗ Backend registration failed: $e');
      setState(() {
        _backendError = e.toString();
        _backendUserData = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note: Backend registration failed. Continue as guest.\nError: $e'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Retry backend registration
  Future<void> _retryBackendRegistration() async {
    await _registerUserWithBackend();
  }

  /// Handle user sign-out
  Future<void> _handleSignOut() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        // Navigate back to login page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D12),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: Color(0xFFE8EDF5),
          ),
        ),
        backgroundColor: const Color(0xFF111620),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Color(0xFF00E5A0),
            ),
            onPressed: _handleSignOut,
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: _user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No user signed in',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Avatar
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _user!.photoURL != null
                              ? NetworkImage(_user!.photoURL!)
                              : null,
                          child: _user!.photoURL == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Backend Registration Status
                  if (_backendError != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        border: Border.all(color: const Color(0xFFEF4444)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Color(0xFFEF4444)),
                              SizedBox(width: 8),
                              Text(
                                'Backend Registration Failed',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _backendError ?? 'Unknown error',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _retryBackendRegistration,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('Retry'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_backendUserData != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5A0).withOpacity(0.1),
                        border: Border.all(
                            color: const Color(0xFF00E5A0).withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF00E5A0)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Synced with Backend',
                                  style: TextStyle(
                                    color: Color(0xFF00E5A0),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'User ID: ${_backendUserData?['userId']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7A90),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C6AFA).withOpacity(0.1),
                        border: Border.all(
                            color: const Color(0xFF7C6AFA).withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                      Color(0xFF7C6AFA)),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Registering with backend...',
                            style: TextStyle(
                              color: Color(0xFF7C6AFA),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  // User Information Section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Display Name', _user?.displayName),
                          _buildInfoRow('Email', _user?.email),
                          _buildInfoRow('Phone', _user?.phoneNumber),
                          _buildInfoRow('User ID', _user?.uid),
                          _buildInfoRow(
                            'Email Verified',
                            _user?.emailVerified == true ? 'Yes' : 'No',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Authentication Token Section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Authentication Token',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!_isLoading)
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: _retryBackendRegistration,
                                  tooltip: 'Refresh token',
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_isLoading)
                            const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            )
                          else if (_idToken != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: SelectableText(
                                    _idToken!.length > 100
                                        ? '${_idToken!.substring(0, 100)}...'
                                        : _idToken!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '✓ This token can be sent to your backend API',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            )
                          else
                            const Text(
                              'Token not loaded',
                              style: TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleSignOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Helper widget to display user information rows
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SelectableText(
              value ?? 'Not provided',
              style: TextStyle(
                color: value == null ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
