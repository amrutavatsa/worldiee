import 'package:flutter/material.dart';

import '../services/api_service.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  static const Color primary = Color(0xFF0E7774);
  static const Color deep = Color(0xFF123B43);
  static const Color aqua = Color(0xFFDFF4F1);
  static const Color background = Color(0xFFF7F9F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF172326);
  static const Color muted = Color(0xFF68777B);
  static const Color line = Color(0xFFDCE5E4);
  static const Color error = Color(0xFFC94B4B);

  final List<String> _interestOptions = [
    'Food',
    'Nature',
    'Landmarks',
    'Shopping',
    'Parks',
    'Restaurants',
  ];

  final List<String> _budgetOptions = [
    'Budget',
    'Moderate',
    'Premium',
  ];

  final List<String> _travelStyleOptions = [
    'Relaxed',
    'Balanced',
    'Adventure',
  ];

  final Set<String> _selectedInterests = {};

  String _selectedBudget = 'Moderate';
  String _selectedTravelStyle = 'Balanced';

  bool _saving = false;

  Future<void> _savePreferences() async {
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one interest.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ApiService.savePreferences(
        interests: _selectedInterests.toList(),
        budget: _selectedBudget,
        travelStyle: _selectedTravelStyle,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Travel preferences saved.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: error,
          content: Text(
            'Could not save preferences: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: muted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _interestChip(String interest) {
    final selected = _selectedInterests.contains(interest);

    return FilterChip(
      label: Text(interest),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (value) {
            _selectedInterests.add(interest);
          } else {
            _selectedInterests.remove(interest);
          }
        });
      },
      selectedColor: aqua,
      checkmarkColor: primary,
      backgroundColor: surface,
      side: BorderSide(
        color: selected ? primary : line,
      ),
      labelStyle: TextStyle(
        color: selected ? primary : ink,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _selectionCard({
    required String value,
    required String selectedValue,
    required VoidCallback onTap,
  }) {
    final selected = value == selectedValue;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: selected ? aqua : surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primary : line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected ? primary : muted,
                size: 22,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? primary : ink,
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08123B43),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Preferences'),
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    deep,
                    primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Shape your journey',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tell WorldCompanion what kind of travel experience you prefer.',
                    style: TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _sectionTitle(
              'Interests',
              'Choose the things you enjoy exploring.',
            ),

            const SizedBox(height: 14),

            _sectionCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _interestOptions
                    .map(_interestChip)
                    .toList(),
              ),
            ),

            const SizedBox(height: 28),

            _sectionTitle(
              'Budget',
              'Choose the spending level that fits your trip.',
            ),

            const SizedBox(height: 14),

            Row(
              children: _budgetOptions.map((option) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: option == _budgetOptions.last ? 0 : 8,
                  ),
                  child: _selectionCard(
                    value: option,
                    selectedValue: _selectedBudget,
                    onTap: () {
                      setState(() {
                        _selectedBudget = option;
                      });
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            _sectionTitle(
              'Travel style',
              'Choose how you like to experience a destination.',
            ),

            const SizedBox(height: 14),

            Row(
              children: _travelStyleOptions.map((option) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: option == _travelStyleOptions.last ? 0 : 8,
                  ),
                  child: _selectionCard(
                    value: option,
                    selectedValue: _selectedTravelStyle,
                    onTap: () {
                      setState(() {
                        _selectedTravelStyle = option;
                      });
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primary.withOpacity(0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Preferences',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}