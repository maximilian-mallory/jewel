import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage

class OAuthRedirectScreen extends StatefulWidget {
  @override
  _OAuthRedirectScreenState createState() => _OAuthRedirectScreenState();
}

class _OAuthRedirectScreenState extends State<OAuthRedirectScreen> {
  String? authorizationCode;
  String? accessToken;
  String? state;
  bool isLoading = true;
  String? errorMessage;

  // Create an instance of the secure storage
  final _storage = FlutterSecureStorage();
  
  // Change these with your actual values
  final String clientId = '316f543d-d5e6-4c90-8459-8ac7070ad917';
  final String redirectUri = 'http://localhost:8000/oauth_redirect';
  final String tenantId = '6c18c0d4-9d1c-4722-8d4f-2193f7ec6cbc';

  @override
  void initState() {
    super.initState();
    // Perform the code verifier check early
    _checkCodeVerifier();
  }

  // Separate method to check for code verifier before token exchange
  Future<void> _checkCodeVerifier() async {
    // Retrieve the code verifier from secure storage
    final codeVerifier = await _storage.read(key: 'code_verifier');
    print("[STORED VERIFIER]: $codeVerifier");
    
    if (codeVerifier == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Code verifier is missing.';
      });
    } else {
      // Proceed with the regular OAuth exchange if the verifier is valid
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      if (args != null && args.containsKey('code')) {
        authorizationCode = args['code'];
        state = args['state'];
        _exchangeCodeForToken(codeVerifier);
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Missing authorization code.';
        });
      }
    }
  }

  // Fetch code verifier from secure storage and exchange the authorization code for a token
  Future<void> _exchangeCodeForToken(String codeVerifier) async {
    final url = Uri.parse('https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token');

    final body = {
      'client_id': clientId,
      'scope': 'User.Read Mail.Read offline_access', // Scopes must match what you requested
      'code': authorizationCode!,
      'redirect_uri': redirectUri,
      'grant_type': 'authorization_code',
      'code_verifier': codeVerifier, // Include the code verifier in the request
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          accessToken = jsonResponse['access_token'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = jsonResponse['error_description'] ?? 'Unknown error';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to fetch token: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OAuth Redirect')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: accessToken != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Access Token Retrieved!'),
                          const SizedBox(height: 10),
                          SelectableText(accessToken ?? ''),
                        ],
                      )
                    : Text(errorMessage ?? 'No token or error available'),
              ),
            ),
    );
  }
}
