import 'package:flutter/material.dart';

enum LegalDocument { terms, privacy }

class LegalScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalScreen({
    super.key,
    required this.document,
  });

  bool get _isTerms => document == LegalDocument.terms;

  @override
  Widget build(BuildContext context) {
    final title = _isTerms ? 'Terms & Conditions' : 'Privacy Policy';
    final sections = _isTerms ? _termsSections : _privacySections;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              'World Companion',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _isTerms
                  ? 'Please read these terms before using the app.'
                  : 'Learn how World Companion may use information when you use the app.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Draft policy — review and confirm the details before public release.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24),
            for (final section in sections) ...[
              Text(
                section.$1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                section.$2,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  static const List<(String, String)> _termsSections = [
    (
      '1. Using World Companion',
      'World Companion provides travel discovery, route planning, nearby-place information, accommodation-related features, and an AI travel companion. Information is provided to help with planning and should be checked before you make travel decisions.'
    ),
    (
      '2. Accounts and security',
      'You are responsible for providing accurate account information and keeping your sign-in credentials secure. Do not use another person’s account without permission. Contact the app operator if you suspect unauthorized account access.'
    ),
    (
      '3. Location and third-party services',
      'Nearby discovery and route-related features may use your device location and external map, place, or other service providers. Availability, accuracy, and coverage may vary. Device permissions can be managed through your device or browser settings.'
    ),
    (
      '4. Travel information and AI responses',
      'Place details, routes, recommendations, availability, and AI-generated responses may be incomplete, outdated, or inaccurate. Independently verify important details, local rules, opening hours, bookings, and safety information.'
    ),
    (
      '5. Acceptable use',
      'Do not misuse the service, interfere with its operation, attempt unauthorized access, or use it for unlawful purposes.'
    ),
    (
      '6. Service availability',
      'Features and third-party integrations may change or become temporarily unavailable. Any limitations of liability or other legal terms must be reviewed and finalized by the app operator before publication.'
    ),
    (
      '7. Contact and updates',
      'The app operator should provide a valid support contact and an effective date for this policy before release. Updated terms should be presented in an appropriate manner.'
    ),
  ];

  static const List<(String, String)> _privacySections = [
    (
      '1. Information you provide',
      'World Companion may process account details such as a username and authentication information that you submit when registering or signing in. Google sign-in may provide an identity token and profile information needed for authentication.'
    ),
    (
      '2. Information stored on your device',
      'The current app implementation stores an authentication token locally and may store a Google profile-photo URL. Protect access to your device and sign out when appropriate.'
    ),
    (
      '3. Location information',
      'When you use nearby-place discovery, the app requests device location permission, obtains coordinates, and sends them to the app backend to request nearby places. You can deny location permission, although location-dependent features may not work.'
    ),
    (
      '4. How information is used',
      'Information may be processed to authenticate your account, provide app features, retrieve nearby places, and support requested travel services. The app operator must confirm the precise purposes and data flows of the deployed backend before this policy is finalized.'
    ),
    (
      '5. Service providers and sharing',
      'Authentication, maps, place discovery, hosting, and other integrations may involve third-party services. The app operator should identify the providers used in production and confirm what information each receives. Do not assume that information is never shared or retained.'
    ),
    (
      '6. Retention and security',
      'The retention period, deletion process, and security controls depend on the deployed backend and service providers. These details, including how to request account or data deletion, must be confirmed and documented by the app operator.'
    ),
    (
      '7. Your choices',
      'You can manage location permission through your device or browser settings. For account-data access, correction, or deletion requests, the app operator should provide a verified contact method.'
    ),
    (
      '8. Policy updates and contact',
      'The app operator should add a valid contact method, applicable effective date, and any required jurisdiction-specific disclosures before making this policy public.'
    ),
  ];
}
