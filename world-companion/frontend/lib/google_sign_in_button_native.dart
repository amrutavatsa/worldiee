import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'services/api_service.dart';
import 'services/auth_service.dart';

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback onSuccess;
  final ValueChanged<Object> onError;

  const GoogleSignInButton({
    super.key,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<GoogleSignInButton> createState() =>
      _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  static const String _webClientId =
      '430750650878-v5vcbqn49lju9s71p64s135tdgqrf43f.apps.googleusercontent.com';

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _webClientId,
    scopes: const ['email', 'profile'],
  );

  bool _loading = false;

  Future<void> _signIn() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      final account = await _googleSignIn.signIn();

      // The user cancelled the Google account picker.
      if (account == null) return;

      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google did not return an ID token. Check your OAuth configuration.',
        );
      }

      final result = await ApiService.googleLogin(idToken);
      final token = result['token'];

      if (token == null || token.toString().isEmpty) {
        throw Exception('WorldCompanion authentication token was not returned.');
      }

      await AuthService.saveToken(token.toString());

      final photoUrl = account.photoUrl;
      if (photoUrl != null && photoUrl.startsWith('https://')) {
        await AuthService.saveGooglePhotoUrl(photoUrl);
      }

      if (!mounted) return;
      widget.onSuccess();
    } catch (error) {
      if (!mounted) return;
      widget.onError(error);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _signIn,
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.g_mobiledata, size: 28),
        label: Text(
          _loading ? 'Signing in...' : 'Continue with Google',
        ),
      ),
    );
  }
}
