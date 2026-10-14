import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'services/google_auth_service.dart';

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback onSuccess;
  final ValueChanged<Object> onError;

  const GoogleSignInButton({
    super.key,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  static const String _viewType =
      'worldcompanion-google-sign-in-button';

  bool _handled = false;

  @override
  void initState() {
    super.initState();

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final container = web.HTMLDivElement()
          ..style.width = '400px'
          ..style.height = '52px'
          ..style.display = 'flex'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center';

        GoogleAuthService.renderButton(container);

        return container;
      },
    );

    _waitForGoogleResult();
  }

  Future<void> _waitForGoogleResult() async {
    try {
      await GoogleAuthService.signIn();

      if (!mounted || _handled) {
        return;
      }

      _handled = true;
      widget.onSuccess();
    } catch (e) {
      if (!mounted || _handled) {
        return;
      }

      _handled = true;
      widget.onError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 400,
      height: 52,
      child: HtmlElementView(
        viewType: _viewType,
      ),
    );
  }
}
