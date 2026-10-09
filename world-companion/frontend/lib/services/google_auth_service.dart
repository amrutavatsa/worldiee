import 'dart:async';

import 'package:google_identity_services_web/id.dart' as gis;
import 'package:web/web.dart' as web;

import 'api_service.dart';
import 'auth_service.dart';

class GoogleAuthService {
  static const String _clientId =
      '430750650878-v5vcbqn49lju9s71p64s135tdgqrf43f.apps.googleusercontent.com';

  static bool _initialized = false;

  static Completer<Map<String, dynamic>>? _signInCompleter;

  /// Initializes Google Identity Services.
  static void initialize() {
    if (_initialized) {
      return;
    }

    final config = gis.IdConfiguration(
      client_id: _clientId,
      callback: _handleCredentialResponse,
      auto_select: false,
    );

    gis.id.initialize(config);

    _initialized = true;
  }

  /// Prepares the Google sign-in future.
  ///
  /// The actual Google popup is triggered by Google's rendered
  /// Sign-In button.
  static Future<Map<String, dynamic>> signIn() {
    initialize();

    if (_signInCompleter == null ||
        _signInCompleter!.isCompleted) {
      _signInCompleter =
          Completer<Map<String, dynamic>>();
    }

    return _signInCompleter!.future;
  }

  /// Renders Google's official Sign-In button into the supplied
  /// DOM element.
  static void renderButton(web.HTMLElement target) {
    initialize();

    // Prepare the Future before the user can click the Google button.
    signIn();

    gis.id.renderButton(
      target,
      gis.GsiButtonConfiguration(
        type: gis.ButtonType.standard,
        theme: gis.ButtonTheme.outline,
        size: gis.ButtonSize.large,
        text: gis.ButtonText.continue_with,
        shape: gis.ButtonShape.rectangular,
        width: 400,
      ),
    );
  }

  /// Handles the credential returned by Google Identity Services.
  static Future<void> _handleCredentialResponse(
    gis.CredentialResponse response,
  ) async {
    try {
      final idToken = response.credential;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google ID token was not received.',
        );
      }

      final result = await ApiService.googleLogin(idToken);

      final token = result['token'];

      if (token == null || token.toString().isEmpty) {
        throw Exception(
          'WorldCompanion token was not received.',
        );
      }

      await AuthService.saveToken(token.toString());

      if (!(_signInCompleter?.isCompleted ?? true)) {
        _signInCompleter!.complete(result);
      }
    } catch (e) {
      if (!(_signInCompleter?.isCompleted ?? true)) {
        _signInCompleter!.completeError(e);
      }
    }
  }

  /// Signs the user out of Google and World Companion.
  static Future<void> signOut() async {
    try {
      gis.id.disableAutoSelect();
    } catch (_) {
      // Ignore Google sign-out errors.
    }

    await AuthService.logout();
  }
}
