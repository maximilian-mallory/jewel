import 'package:flutter/material.dart';

class OAuthRedirectScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;

    final authorizationCode = args?['code'] ?? 'No code found';
    final state = args?['state'] ?? 'No state found';

    return Scaffold(
      appBar: AppBar(title: const Text('OAuth Redirect')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Authorization Code: $authorizationCode'),
            const SizedBox(height: 10),
            Text('State: $state'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // You can now use the authorization code to exchange for an access token
              },
              child: const Text('Complete OAuth Flow'),
            ),
          ],
        ),
      ),
    );
  }
}
