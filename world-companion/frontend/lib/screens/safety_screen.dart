
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/world_companion_colors.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _loadingContacts = true;
  String? _contactsError;

  bool _sosLoading = false;

  String? _activeSosId;
  String? _activeSosStatus;
  bool _loadingActiveSos = true;
  String? _activeSosError;

  bool get _hasActiveSos =>
      _activeSosId != null &&
      _activeSosId!.isNotEmpty &&
      (_activeSosStatus == 'countdown' ||
          _activeSosStatus == 'active');

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadActiveSos();
  }

  // ---------------------------------------------------------------------------
  // Emergency contacts
  // ---------------------------------------------------------------------------

  Future<void> _loadContacts() async {
    try {
      final data = await ApiService.getEmergencyContacts();

      if (!mounted) return;

      setState(() {
        _contacts = data
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
        _loadingContacts = false;
        _contactsError = null;
      });
    } catch (e) {
      debugPrint('EMERGENCY CONTACT ERROR: $e');

      if (!mounted) return;

      setState(() {
        _loadingContacts = false;
        _contactsError = e.toString();
      });
    }
  }

  Future<void> _showAddContactDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          bool saving = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  'Add emergency contact',
                  style: WorldCompanionTypography.textTheme.titleLarge,
                ),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            hintText: 'Contact name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: WorldCompanionSpacing.md,
                        ),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            hintText: 'Phone number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: WorldCompanionSpacing.md,
                        ),
                        TextFormField(
                          controller: relationshipController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Relationship',
                            hintText: 'e.g. Parent, Friend',
                            prefixIcon: Icon(Icons.people_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a relationship';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            setDialogState(() => saving = true);

                            try {
                              await ApiService.createEmergencyContact(
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                relationship:
                                    relationshipController.text.trim(),
                              );

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext, true);
                              }
                            } catch (e) {
                              if (!dialogContext.mounted) return;

                              setDialogState(() => saving = false);

                              ScaffoldMessenger.of(dialogContext)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    content: Text(
                                      'Unable to save contact: $e',
                                    ),
                                  ),
                                );
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save contact'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == true) {
        await _loadContacts();
      }
    } finally {
      nameController.dispose();
      phoneController.dispose();
      relationshipController.dispose();
    }
  }

  // ---------------------------------------------------------------------------
  // Persistent SOS state
  // ---------------------------------------------------------------------------

  Future<void> _loadActiveSos() async {
    if (mounted) {
      setState(() {
        _loadingActiveSos = true;
        _activeSosError = null;
      });
    }

    try {
      final result = await ApiService.getActiveSos();

      debugPrint('SOS ACTIVE RESPONSE: $result');

      if (!mounted) return;

      final rawData = result['data'];

      if (rawData == null) {
        setState(() {
          _activeSosId = null;
          _activeSosStatus = null;
          _activeSosError = null;
          _loadingActiveSos = false;
        });
        return;
      }

      if (rawData is! Map) {
        setState(() {
          _activeSosId = null;
          _activeSosStatus = null;
          _activeSosError = 'Invalid SOS state returned by the server.';
          _loadingActiveSos = false;
        });
        return;
      }

      final activeData = Map<String, dynamic>.from(rawData);
      final eventId = activeData['id']?.toString();
      final status = activeData['status']?.toString();

      if (eventId == null || eventId.isEmpty) {
        setState(() {
          _activeSosId = null;
          _activeSosStatus = null;
          _activeSosError =
              'Active SOS was returned without an event ID.';
          _loadingActiveSos = false;
        });
        return;
      }

      if (status != 'countdown' && status != 'active') {
        setState(() {
          _activeSosId = null;
          _activeSosStatus = null;
          _activeSosError = null;
          _loadingActiveSos = false;
        });
        return;
      }

      setState(() {
        _activeSosId = eventId;
        _activeSosStatus = status;
        _activeSosError = null;
        _loadingActiveSos = false;
      });

      debugPrint('SOS STATE RESTORED: id=$eventId status=$status');
    } catch (e) {
      debugPrint('SOS ACTIVE ERROR: $e');

      if (!mounted) return;

      setState(() {
        _loadingActiveSos = false;
        _activeSosError = e.toString();
      });
    }
  }

  void _setActiveSos({
    required String eventId,
    required String status,
  }) {
    if (!mounted) return;

    setState(() {
      _activeSosId = eventId;
      _activeSosStatus = status;
      _activeSosError = null;
      _loadingActiveSos = false;
    });
  }

  void _clearActiveSos() {
    if (!mounted) return;

    setState(() {
      _activeSosId = null;
      _activeSosStatus = null;
      _activeSosError = null;
      _loadingActiveSos = false;
    });
  }

  // ---------------------------------------------------------------------------
  // SOS actions
  // ---------------------------------------------------------------------------

  Future<void> _triggerSos() async {
    if (_sosLoading || _hasActiveSos) return;

    setState(() => _sosLoading = true);

    try {
      final result = await ApiService.triggerSos();
      debugPrint('SOS TRIGGER RESPONSE: $result');

      if (!mounted) return;

      final eventId = result['id']?.toString();

      if (eventId == null || eventId.isEmpty) {
        throw Exception('SOS event ID was not returned by the server.');
      }

      final status = result['status']?.toString() ?? 'countdown';

      _setActiveSos(eventId: eventId, status: status);
      await _showSosDialog(eventId);
    } catch (e) {
      debugPrint('SOS TRIGGER ERROR: $e');

      if (!mounted) return;

      _showMessage('Unable to trigger SOS: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _sosLoading = false);
      }
    }
  }

  Future<void> _showSosDialog(String eventId) async {
    bool activating = false;
    bool resolving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final busy = activating || resolving;

            return AlertDialog(
              icon: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: WorldCompanionColors.errorSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sos_rounded,
                  color: WorldCompanionColors.error,
                  size: 34,
                ),
              ),
              title: Text(
                'SOS triggered',
                textAlign: TextAlign.center,
                style: WorldCompanionTypography.textTheme.headlineSmall,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'The project currently simulates the SOS flow. '
                    'No real emergency service is being contacted.',
                    textAlign: TextAlign.center,
                    style: WorldCompanionTypography.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: WorldCompanionSpacing.md),
                  const _SimulationNotice(compact: true),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actionsOverflowButtonSpacing: WorldCompanionSpacing.sm,
              actions: [
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          setDialogState(() => resolving = true);

                          try {
                            await ApiService.resolveSos(eventId);
                            _clearActiveSos();

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            debugPrint('SOS RESOLVE ERROR: $e');

                            if (!dialogContext.mounted) return;

                            setDialogState(() => resolving = false);
                            _showMessage(
                              'Unable to resolve SOS: $e',
                              isError: true,
                            );
                          }
                        },
                  child: resolving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Resolve'),
                ),
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          setDialogState(() => activating = true);

                          try {
                            final result = await ApiService.activateSos(
                              eventId,
                            );

                            debugPrint('SOS ACTIVATE RESPONSE: $result');

                            _setActiveSos(
                              eventId: eventId,
                              status: 'active',
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);
                            _showMessage(
                              'SOS activated in the project simulation.',
                            );
                          } catch (e) {
                            debugPrint('SOS ACTIVATE ERROR: $e');

                            if (!dialogContext.mounted) return;

                            setDialogState(() => activating = false);
                            _showMessage(
                              'Unable to activate SOS: $e',
                              isError: true,
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: WorldCompanionColors.error,
                    foregroundColor: Colors.white,
                  ),
                  icon: activating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.warning_amber_rounded),
                  label: Text(activating ? 'Activating…' : 'Activate SOS'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _resolveActiveSos() async {
    final eventId = _activeSosId;

    if (eventId == null || eventId.isEmpty || _sosLoading) return;

    setState(() => _sosLoading = true);

    try {
      final result = await ApiService.resolveSos(eventId);
      debugPrint('SOS RESOLVE RESPONSE: $result');

      _clearActiveSos();

      if (!mounted) return;
      _showMessage('SOS resolved.');
    } catch (e) {
      debugPrint('SOS RESOLVE ACTIVE ERROR: $e');

      if (!mounted) return;
      _showMessage('Unable to resolve SOS: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _sosLoading = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? WorldCompanionColors.error
              : WorldCompanionColors.deepOcean,
          content: Text(message),
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // Screen
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Safety',
          style: WorldCompanionTypography.textTheme.titleLarge,
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: RefreshIndicator(
        color: WorldCompanionColors.oceanBlue,
        onRefresh: () async {
          await Future.wait([
            _loadContacts(),
            _loadActiveSos(),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            WorldCompanionSpacing.mobilePage,
            WorldCompanionSpacing.sm,
            WorldCompanionSpacing.mobilePage,
            WorldCompanionSpacing.xxxl,
          ),
          children: [
            _buildSafetyIntro(),
            const SizedBox(height: WorldCompanionSpacing.lg),
            _buildSectionHeading(
              'Emergency assistance',
              'Manage your SOS state.',
            ),
            const SizedBox(height: WorldCompanionSpacing.md),
            _buildSosCard(),
            const SizedBox(height: WorldCompanionSpacing.xl),
            _buildContactsHeader(),
            const SizedBox(height: WorldCompanionSpacing.md),
            _buildContacts(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Intro
  // ---------------------------------------------------------------------------

  Widget _buildSafetyIntro() {
    return Container(
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      decoration: BoxDecoration(
        color: WorldCompanionColors.infoSurface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
        border: Border.all(color: WorldCompanionColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: WorldCompanionColors.deepOcean,
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.medium,
              ),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: WorldCompanionSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Travel with confidence',
                  style: WorldCompanionTypography.textTheme.titleMedium,
                ),
                const SizedBox(height: WorldCompanionSpacing.xs),
                Text(
                  'Keep trusted contacts close and review your safety status '
                  'whenever you need it.',
                  style: WorldCompanionTypography.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: WorldCompanionTypography.textTheme.headlineSmall,
        ),
        const SizedBox(height: WorldCompanionSpacing.xxs),
        Text(
          subtitle,
          style: WorldCompanionTypography.textTheme.bodyMedium,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SOS cards
  // ---------------------------------------------------------------------------

  Widget _buildSosCard() {
    if (_loadingActiveSos) {
      return _surfaceCard(
        child: const Padding(
          padding: EdgeInsets.symmetric(
            vertical: WorldCompanionSpacing.xl,
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: WorldCompanionColors.oceanBlue,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_activeSosError != null) ...[
          _buildActiveSosError(),
          const SizedBox(height: WorldCompanionSpacing.md),
        ],
        if (_hasActiveSos)
          _buildActiveSosCard()
        else
          _buildInactiveSosCard(),
      ],
    );
  }

  Widget _buildActiveSosError() {
    return Container(
      padding: const EdgeInsets.all(WorldCompanionSpacing.md),
      decoration: BoxDecoration(
        color: WorldCompanionColors.warningSurface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        border: Border.all(color: WorldCompanionColors.warning),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: WorldCompanionColors.warning,
          ),
          const SizedBox(width: WorldCompanionSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not verify SOS status',
                  style: WorldCompanionTypography.textTheme.titleSmall,
                ),
                const SizedBox(height: WorldCompanionSpacing.xxs),
                Text(
                  'Your saved SOS status could not be verified. '
                  'Retry before assuming there is no active event.',
                  style: WorldCompanionTypography.textTheme.bodySmall,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _loadingActiveSos ? null : _loadActiveSos,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveSosCard() {
    return _surfaceCard(
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: WorldCompanionColors.errorSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sos_rounded,
              color: WorldCompanionColors.error,
              size: 42,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          Text(
            'Emergency SOS',
            style: WorldCompanionTypography.textTheme.headlineSmall,
          ),
          const SizedBox(height: WorldCompanionSpacing.xs),
          Text(
            'Start the SOS workflow to test the emergency state and '
            'available actions.',
            textAlign: TextAlign.center,
            style: WorldCompanionTypography.textTheme.bodyMedium,
          ),
          const SizedBox(height: WorldCompanionSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _sosLoading ? null : _triggerSos,
              style: FilledButton.styleFrom(
                backgroundColor: WorldCompanionColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    WorldCompanionRadius.medium,
                  ),
                ),
              ),
              icon: _sosLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.warning_amber_rounded),
              label: Text(
                _sosLoading ? 'Starting SOS…' : 'Trigger SOS',
                style: WorldCompanionTypography.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          const _SimulationNotice(),
        ],
      ),
    );
  }

  Widget _buildActiveSosCard() {
    final isActive = _activeSosStatus == 'active';

    return Container(
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      decoration: BoxDecoration(
        color: WorldCompanionColors.errorSurface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
        border: Border.all(
          color: WorldCompanionColors.error.withOpacity(0.4),
          width: 1.3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0B2545),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFFFDADA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sos_rounded,
              color: WorldCompanionColors.error,
              size: 42,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          Text(
            isActive ? 'SOS ACTIVE' : 'SOS COUNTDOWN',
            style: WorldCompanionTypography.textTheme.headlineSmall?.copyWith(
              color: WorldCompanionColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WorldCompanionSpacing.xs),
          Text(
            isActive
                ? 'This SOS event is active in the project simulation.'
                : 'An SOS event is waiting for activation in the simulation.',
            textAlign: TextAlign.center,
            style: WorldCompanionTypography.textTheme.bodyMedium,
          ),
          const SizedBox(height: WorldCompanionSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _sosLoading || _activeSosId == null
                  ? null
                  : _resolveActiveSos,
              style: FilledButton.styleFrom(
                backgroundColor: WorldCompanionColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    WorldCompanionRadius.medium,
                  ),
                ),
              ),
              icon: _sosLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                _sosLoading ? 'Resolving…' : 'Resolve SOS',
                style: WorldCompanionTypography.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          const _SimulationNotice(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Emergency contacts
  // ---------------------------------------------------------------------------

  Widget _buildContactsHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trusted contacts',
                style: WorldCompanionTypography.textTheme.headlineSmall,
              ),
              const SizedBox(height: WorldCompanionSpacing.xxs),
              Text(
                'People you can rely on while travelling.',
                style: WorldCompanionTypography.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: WorldCompanionSpacing.xs),
        FilledButton.tonalIcon(
          onPressed: _showAddContactDialog,
          icon: const Icon(Icons.add_rounded, size: 19),
          label: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildContacts() {
    if (_loadingContacts) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: WorldCompanionSpacing.xl,
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: WorldCompanionColors.oceanBlue,
          ),
        ),
      );
    }

    if (_contactsError != null) {
      return _surfaceCard(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: WorldCompanionColors.error,
              size: 32,
            ),
            const SizedBox(height: WorldCompanionSpacing.sm),
            Text(
              'Unable to load emergency contacts.',
              textAlign: TextAlign.center,
              style: WorldCompanionTypography.textTheme.titleMedium,
            ),
            const SizedBox(height: WorldCompanionSpacing.xs),
            Text(
              _contactsError!,
              textAlign: TextAlign.center,
              style: WorldCompanionTypography.textTheme.bodySmall,
            ),
            const SizedBox(height: WorldCompanionSpacing.md),
            OutlinedButton.icon(
              onPressed: _loadContacts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_contacts.isEmpty) {
      return _surfaceCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: WorldCompanionSpacing.lg,
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: WorldCompanionColors.infoSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.contact_emergency_outlined,
                  color: WorldCompanionColors.oceanBlue,
                  size: 30,
                ),
              ),
              const SizedBox(height: WorldCompanionSpacing.md),
              Text(
                'No emergency contacts yet',
                style: WorldCompanionTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: WorldCompanionSpacing.xs),
              Text(
                'Add someone you trust before your next trip.',
                textAlign: TextAlign.center,
                style: WorldCompanionTypography.textTheme.bodyMedium,
              ),
              const SizedBox(height: WorldCompanionSpacing.md),
              OutlinedButton.icon(
                onPressed: _showAddContactDialog,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add a contact'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _contacts.map(_contactCard).toList(),
    );
  }

  Widget _contactCard(Map<String, dynamic> contact) {
    final name = contact['name']?.toString() ?? 'Unknown';
    final phone = contact['phone']?.toString() ?? 'No phone';
    final relationship =
        contact['relationship']?.toString() ?? 'Emergency contact';

    return Padding(
      padding: const EdgeInsets.only(bottom: WorldCompanionSpacing.sm),
      child: _surfaceCard(
        padding: const EdgeInsets.all(WorldCompanionSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: WorldCompanionColors.infoSurface,
                borderRadius: BorderRadius.circular(
                  WorldCompanionRadius.medium,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: WorldCompanionColors.oceanBlue,
                size: 25,
              ),
            ),
            const SizedBox(width: WorldCompanionSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: WorldCompanionTypography.textTheme.titleMedium,
                  ),
                  const SizedBox(height: WorldCompanionSpacing.xxs),
                  Text(
                    relationship,
                    style: WorldCompanionTypography.textTheme.bodySmall,
                  ),
                  const SizedBox(height: WorldCompanionSpacing.xxs),
                  SelectableText(
                    phone,
                    style: WorldCompanionTypography.textTheme.bodyMedium?.copyWith(
                      color: WorldCompanionColors.deepOcean,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: WorldCompanionSpacing.xs),
            const Tooltip(
              message: 'Saved contact',
              child: Icon(
                Icons.verified_user_outlined,
                color: WorldCompanionColors.success,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared surface
  // ---------------------------------------------------------------------------

  Widget _surfaceCard({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(WorldCompanionSpacing.md),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
        border: Border.all(color: WorldCompanionColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B2545),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SimulationNotice extends StatelessWidget {
  const _SimulationNotice({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: WorldCompanionSpacing.sm,
        vertical: compact
            ? WorldCompanionSpacing.xs
            : WorldCompanionSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: WorldCompanionColors.warningSurface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.medium),
        border: Border.all(
          color: WorldCompanionColors.warning.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: WorldCompanionColors.warning,
            size: 17,
          ),
          const SizedBox(width: WorldCompanionSpacing.xs),
          Flexible(
            child: Text(
              'Simulation only — no real emergency dispatch',
              textAlign: TextAlign.center,
              style: WorldCompanionTypography.textTheme.labelMedium?.copyWith(
                color: WorldCompanionColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
