import 'package:flutter/material.dart';

import '../services/api_service.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  static const Color primary = Color(0xFF0E7774);
  static const Color deep = Color(0xFF123B43);
  static const Color aqua = Color(0xFFDFF4F1);
  static const Color background = Color(0xFFF7F9F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF172326);
  static const Color muted = Color(0xFF68777B);
  static const Color line = Color(0xFFDCE5E4);

  List<Map<String, dynamic>> _contacts = [];
  bool _loadingContacts = true;
  String? _contactsError;

  bool _sosLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

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

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Add emergency contact',
            style: TextStyle(
              color: deep,
              fontWeight: FontWeight.w800,
            ),
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
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: 'Phone number',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: relationshipController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      hintText: 'e.g. Parent, Friend',
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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  await ApiService.createEmergencyContact(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    relationship: relationshipController.text.trim(),
                  );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                } catch (e) {
                  if (!dialogContext.mounted) return;

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                    ),
                  );
                }
              },
              child: const Text('Save contact'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    relationshipController.dispose();

    if (result == true) {
      await _loadContacts();
    }
  }

  Future<void> _triggerSos() async {
    if (_sosLoading) return;

    setState(() {
      _sosLoading = true;
    });

    try {
      final result = await ApiService.triggerSos();

      if (!mounted) return;

      final eventId = result['id']?.toString();

      if (eventId == null || eventId.isEmpty) {
        throw Exception('SOS event ID was not returned by the server.');
      }

      await _showSosDialog(eventId);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: deep,
          content: Text(
            'Unable to trigger SOS: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sosLoading = false;
        });
      }
    }
  }

  Future<void> _showSosDialog(String eventId) async {
    bool activating = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              icon: Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE6E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sos_rounded,
                  color: Color(0xFFC94B4B),
                  size: 32,
                ),
              ),
              title: const Text(
                'SOS triggered',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: deep,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: const Text(
                'The project currently simulates the SOS flow. '
                'No real emergency service is being contacted.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  height: 1.45,
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: activating
                      ? null
                      : () async {
                          try {
                            await ApiService.resolveSos(eventId);

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                              ),
                            );
                          }
                        },
                  child: const Text('Resolve'),
                ),
                FilledButton(
                  onPressed: activating
                      ? null
                      : () async {
                          setDialogState(() {
                            activating = true;
                          });

                          try {
                            await ApiService.activateSos(eventId);

                            if (!dialogContext.mounted) return;

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'SOS activated in the project simulation.',
                                ),
                              ),
                            );

                            Navigator.pop(dialogContext);
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            setDialogState(() {
                              activating = false;
                            });

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                              ),
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC94B4B),
                  ),
                  child: activating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Activate SOS'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Safety',
          style: TextStyle(
            color: deep,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(
          color: deep,
        ),
      ),
      body: RefreshIndicator(
        color: primary,
        onRefresh: _loadContacts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _buildSafetyIntro(),
            const SizedBox(height: 18),
            _buildSosCard(),
            const SizedBox(height: 28),
            _buildContactsHeader(),
            const SizedBox(height: 12),
            _buildContacts(),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: aqua,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFCBE9E5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Travel safety',
                  style: TextStyle(
                    color: deep,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Keep trusted contacts available while you travel.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: line,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A123B43),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE6E6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sos_rounded,
              color: Color(0xFFC94B4B),
              size: 40,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Emergency SOS',
            style: TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Trigger the existing project SOS flow when you need assistance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _sosLoading ? null : _triggerSos,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC94B4B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _sosLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Trigger SOS',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Simulation only • no real emergency dispatch',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Emergency contacts',
            style: TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _showAddContactDialog,
          icon: const Icon(
            Icons.add_rounded,
            size: 18,
          ),
          label: const Text('Add'),
          style: TextButton.styleFrom(
            foregroundColor: primary,
          ),
        ),
      ],
    );
  }

  Widget _buildContacts() {
    if (_loadingContacts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: CircularProgressIndicator(
            color: primary,
          ),
        ),
      );
    }

    if (_contactsError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: line,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFC94B4B),
              size: 28,
            ),
            const SizedBox(height: 8),
            const Text(
              'Unable to load emergency contacts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _contactsError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadContacts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_contacts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: line,
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.contact_emergency_outlined,
              color: muted,
              size: 32,
            ),
            SizedBox(height: 10),
            Text(
              'No emergency contacts yet.',
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Add someone you trust before your next trip.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: muted,
                fontSize: 12,
              ),
            ),
          ],
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: aqua,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  relationship,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  phone,
                  style: const TextStyle(
                    color: deep,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_user_outlined,
            color: primary,
            size: 20,
          ),
        ],
      ),
    );
  }
}