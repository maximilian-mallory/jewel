import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


// Microsoft authentication service
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Microsoft authentication service
class MicrosoftAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Microsoft token storage keys
  static const String _accessTokenKey = 'ms_access_token';
  static const String _refreshTokenKey = 'ms_refresh_token';
  static const String _expirationKey = 'ms_token_expiration';
  
  // Microsoft OAuth settings
  static const String _clientId = 'YOUR_CLIENT_ID'; // Replace with your client ID
  static const String _tenant = '6c18c0d4-9d1c-4722-8d4f-2193f7ec6cbc';
  static const String _tokenEndpoint = 'https://login.microsoftonline.com/$_tenant/oauth2/v2.0/token';
  static const String _redirectUri = 'https://jewel-b2dcd.firebaseapp.com/__/auth/handler';
  
  // Sign in with Microsoft via Firebase
  Future<UserCredential?> signInWithMicrosoft() async {
    try {
      // Create Microsoft OAuth provider
      final microsoftProvider = OAuthProvider('microsoft.com');
      
      // Add required scopes for Microsoft Graph API
      microsoftProvider.addScope('https://graph.microsoft.com/User.Read');
      microsoftProvider.addScope('offline_access');
      microsoftProvider.addScope('openid');
      microsoftProvider.addScope('profile');
      microsoftProvider.addScope('email');
      
      // Request user consent to get refresh token
      microsoftProvider.setCustomParameters({
        'tenant': _tenant,
        'prompt': 'consent' // Force consent to get refresh token
      });
      
      // Sign in with popup for web or redirect for mobile platforms
      UserCredential credential;
      if (isWeb()) {
        credential = await _auth.signInWithPopup(microsoftProvider);
      } else {
        credential = await _auth.signInWithProvider(microsoftProvider);
      }
      
      // Extract and store tokens
      await _extractAndStoreTokens(credential);
      
      return credential;
    } catch (e) {
      print('Microsoft sign-in error: $e');
      return null;
    }
  }
  
  // Extract and store tokens from credential
  Future<void> _extractAndStoreTokens(UserCredential credential) async {
    try {
      // Get Microsoft OAuth credential
      final oauthCredential = credential.credential as OAuthCredential;
      
      // Store access token
      if (oauthCredential.accessToken != null) {
        await _secureStorage.write(
          key: _accessTokenKey,
          value: oauthCredential.accessToken
        );
        
        // Access token typically expires in 1 hour
        final expiration = DateTime.now().add(const Duration(hours: 1));
        await _secureStorage.write(
          key: _expirationKey,
          value: expiration.toIso8601String()
        );
      }
      
      // Store refresh token if available
      if (oauthCredential.idToken != null) {
        // The ID token can be used to identify the user
        // Store it if needed for future operations
        
        // Try to extract claims from ID token
        final parts = oauthCredential.idToken!.split('.');
        if (parts.length > 1) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          final claims = json.decode(decoded);
          
          // Extract and store user info if needed
          print('ID Token claims: $claims');
        }
      }
      
      // Store additional provider data if available
      final additionalUserInfo = credential.additionalUserInfo;
      if (additionalUserInfo != null && additionalUserInfo.profile != null) {
        // This might contain refresh token or other useful data
        print('Additional user info: ${additionalUserInfo.profile}');
      }
    } catch (e) {
      print('Error extracting tokens: $e');
    }
  }
  
  // Request a new Graph API token using authorization code
  Future<bool> requestGraphToken(String authCode) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'scope': 'https://graph.microsoft.com/User.Read offline_access',
          'code': authCode,
          'redirect_uri': _redirectUri, // Replace with your redirect URI
          'grant_type': 'authorization_code'
        },
      );
      
      if (response.statusCode == 200) {
        final tokenData = json.decode(response.body);
        await _secureStorage.write(
          key: _accessTokenKey,
          value: tokenData['access_token']
        );
        
        if (tokenData.containsKey('refresh_token')) {
          await _secureStorage.write(
            key: _refreshTokenKey,
            value: tokenData['refresh_token']
          );
        }
        
        if (tokenData.containsKey('expires_in')) {
          final expiration = DateTime.now().add(
            Duration(seconds: tokenData['expires_in'])
          );
          await _secureStorage.write(
            key: _expirationKey,
            value: expiration.toIso8601String()
          );
        }
        
        return true;
      } else {
        print('Token request failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Token request error: $e');
      return false;
    }
  }
  
  // Refresh Microsoft access token
  Future<bool> refreshMicrosoftToken() async {
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (refreshToken == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
          'scope': 'https://graph.microsoft.com/User.Read offline_access'
        },
      );
      
      if (response.statusCode == 200) {
        final tokenData = json.decode(response.body);
        await _secureStorage.write(
          key: _accessTokenKey,
          value: tokenData['access_token']
        );
        
        if (tokenData.containsKey('refresh_token')) {
          await _secureStorage.write(
            key: _refreshTokenKey,
            value: tokenData['refresh_token']
          );
        }
        
        if (tokenData.containsKey('expires_in')) {
          final expiration = DateTime.now().add(
            Duration(seconds: tokenData['expires_in'])
          );
          await _secureStorage.write(
            key: _expirationKey,
            value: expiration.toIso8601String()
          );
        }
        
        return true;
      } else {
        print('Token refresh failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }
  
  // Check if running on web
  bool isWeb() {
    return identical(0, 0.0);
  }
  
  // Get the current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  // Check if user is signed in
  bool isSignedIn() {
    return _auth.currentUser != null;
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _expirationKey);
  }
  
  // Get Microsoft access token with automatic refresh if needed
  Future<String?> getMicrosoftAccessToken() async {
    // First try to get from secure storage
    final token = await _secureStorage.read(key: _accessTokenKey);
    final expiry = await _secureStorage.read(key: _expirationKey);
    
    // Check if token exists and is valid
    if (token != null && expiry != null) {
      final expiryDate = DateTime.parse(expiry);
      
      // Return token if it's still valid (with 5-minute buffer)
      if (expiryDate.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
        return token;
      }
    }
    
    // If token is expired or close to expiry, try to refresh it
    final refreshSuccess = await refreshMicrosoftToken();
    if (refreshSuccess) {
      return await _secureStorage.read(key: _accessTokenKey);
    }
    
    // If refresh fails, return null (will need to sign in again)
    return null;
  }
  
  // Call Microsoft Graph API
  Future<Map<String, dynamic>?> getUserProfile() async {
    final accessToken = await getMicrosoftAccessToken();
    if (accessToken == null) return null;
    
    try {
      final response = await http.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Graph API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Graph API request error: $e');
      return null;
    }
  }
}

// Auth screen widget
class MsLoginScreen extends StatefulWidget {
  const MsLoginScreen({Key? key}) : super(key: key);

  @override
  _MsLoginScreenState createState() => _MsLoginScreenState();
}

class _MsLoginScreenState extends State<MsLoginScreen> {
  final MicrosoftAuthService _authService = MicrosoftAuthService();
  bool _isLoading = false;
  String _userInfo = 'Not signed in';
  String _tokenStatus = 'No token';
  
  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }
  
  Future<void> _checkSignInStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    if (_authService.isSignedIn()) {
      await _checkGraphToken();
      await _fetchUserProfile();
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _authService.signInWithMicrosoft();
      if (result != null) {
        // Check if we have valid Graph tokens after sign in
        await _checkGraphToken();
        await _fetchUserProfile();
      }
    } catch (e) {
      print('Authentication error: $e');
      setState(() {
        _userInfo = 'Error signing in: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _checkGraphToken() async {
    final token = await _authService.getMicrosoftAccessToken();
    setState(() {
      _tokenStatus = token != null 
        ? 'Graph token available (${token.substring(0, 10)}...)'
        : 'No Graph token';
    });
  }
  
  Future<void> _refreshGraphToken() async {
    setState(() {
      _isLoading = true;
    });
    
    final success = await _authService.refreshMicrosoftToken();
    
    setState(() {
      _isLoading = false;
      _tokenStatus = success 
        ? 'Token refreshed successfully' 
        : 'Failed to refresh token';
    });
    
    if (success) {
      await _fetchUserProfile();
    }
  }
  
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    
    await _authService.signOut();
    
    setState(() {
      _isLoading = false;
      _userInfo = 'Not signed in';
      _tokenStatus = 'No token';
    });
  }
  
  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    final userProfile = await _authService.getUserProfile();
    
    setState(() {
      _isLoading = false;
      if (userProfile != null) {
        final prettyJson = const JsonEncoder.withIndent('  ').convert(userProfile);
        _userInfo = prettyJson;
      } else {
        _userInfo = 'Failed to fetch user profile';
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isSignedIn = _authService.isSignedIn();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Microsoft Authentication'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isSignedIn) ...[
                      ElevatedButton.icon(
                        onPressed: _signIn,
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in with Microsoft'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        _tokenStatus,
                        style: TextStyle(
                          fontSize: 16,
                          color: _tokenStatus.contains('No') ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'User Profile:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          maxWidth: 400,
                          maxHeight: 300,
                        ),
                        child: SingleChildScrollView(
                          child: Text(_userInfo),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _fetchUserProfile,
                            child: const Text('Refresh Profile'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _refreshGraphToken,
                            child: const Text('Refresh Token'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _signOut,
                        child: const Text('Sign Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}