import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

class MicrosoftLoginScreen extends StatefulWidget {
  @override
  _MicrosoftLoginScreenState createState() => _MicrosoftLoginScreenState();
}

class _MicrosoftLoginScreenState extends State<MicrosoftLoginScreen> {
  StreamSubscription? _sub;
  Uri? _incomingUri;
  Map<String, String> _queryParameters = {};

  @override
  void initState() {
    super.initState();
    _initDeepLinking();
  }

  void _initDeepLinking() async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(Uri.parse(initialLink));
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }

    _sub = linkStream.listen((String? link) {
      if (link != null) {
        _handleDeepLink(Uri.parse(link));
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
   
    final redirectUrl = 'https://login.microsoftonline.com/6c18c0d4-9d1c-4722-8d4f-2193f7ec6cbc/oauth2/v2.0/authorize?client_id=316f543d-d5e6-4c90-8459-8ac7070ad917&response_type=code&redirect_uri=http%3A%2F%2Flocalhost%3A8000%2Foauth_redirect&response_mode=query&scope=offline_access%20User.Read%20Mail.Read&state=12345&prompt=login';
    final Uri uri = Uri.parse(redirectUrl);
 
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault, // Opens in same tab on web, browser/app on mobile
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
