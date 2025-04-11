import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';  // Add the crypto package
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import for secure storage

class MicrosoftLoginScreen extends StatefulWidget {
  @override
  _MicrosoftLoginScreenState createState() => _MicrosoftLoginScreenState();
}

class _MicrosoftLoginScreenState extends State<MicrosoftLoginScreen> {
  StreamSubscription? _sub;
  Uri? _incomingUri;
  Map<String, String> _queryParameters = {};
  late String _codeVerifier;
  late String _codeChallenge;

  // Create an instance of the secure storage
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initDeepLinking();
    _generatePKCE();  // Generate PKCE code verifier and challenge
  }

  // Generate the PKCE code verifier and code challenge
  void _generatePKCE() {
    _codeVerifier = _generateRandomString(128);  // Code Verifier
    _codeChallenge = _generateCodeChallenge(_codeVerifier);  // Code Challenge
    print("[CODE VERIFIER]: $_codeVerifier");
    print("[CODE CHALLENGE]: $_codeChallenge");
    // Store the code verifier securely
    _storage.write(key: 'code_verifier', value: _codeChallenge);
  }

  // Generate a random string (code verifier)
  String _generateRandomString(int length) {
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Generate code challenge using SHA256 hash of code verifier
  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', ''); // PKCE challenge
  }

  void _initDeepLinking() async {
    await Future.delayed(Duration(milliseconds: 300));

    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        final uri = Uri.parse(initialLink);
        if (uri.path.contains('oauth_redirect') && uri.queryParameters.containsKey('code')) {
          _handleDeepLink(uri);
        }
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }

    _sub = linkStream.listen((String? link) {
      if (link != null) {
        final uri = Uri.parse(link);
        if (uri.path.contains('oauth_redirect') && uri.queryParameters.containsKey('code')) {
          _handleDeepLink(uri);
        }
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    setState(() {
      _incomingUri = uri;
      _queryParameters = uri.queryParameters;
    });

    Navigator.pushNamed(
      context,
      '/oauth_redirect',
      arguments: _queryParameters,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _launchRedirectUrl() async {
  final redirectUrl = 'https://login.microsoftonline.com/6c18c0d4-9d1c-4722-8d4f-2193f7ec6cbc/oauth2/v2.0/authorize'
      '?client_id=316f543d-d5e6-4c90-8459-8ac7070ad917'
      '&response_type=code'
      '&redirect_uri=http%3A%2F%2Flocalhost%3A8000%2Foauth_redirect'
      '&response_mode=query'
      '&scope=offline_access%20User.Read%20Mail.Read'
      '&state=12345'
      '&prompt=login'
      '&code_challenge=$_codeChallenge'
      ; // Add PKCE parameters

  // Save code_verifier to secure storage before launching
  await _storage.write(key: 'code_verifier', value: _codeChallenge);

  final Uri uri = Uri.parse(redirectUrl);

  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    );
  } else {
    throw 'Could not launch $redirectUrl';
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Microsoft Sign In')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _launchRedirectUrl,
              child: const Text('Continue to Sign In to Microsoft'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/oauth_redirect',
                  arguments: _queryParameters,
                );
              },
              child: const Text('Go to OAuth Redirect'),
            ),
          ],
        ),
      ),
    );
  }
}
