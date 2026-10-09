import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/world_companion_colors.dart';
import '../theme/world_companion_elevation.dart';
import '../theme/world_companion_motion.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
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
          backgroundColor: WorldCompanionColors.error,
          content: Text('Could not save preferences: $e'),
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

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: WorldCompanionColors.primaryText,
              ),
        ),
        const SizedBox(height: WorldCompanionSpacing.xxs),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _interestChip(String interest) {
    final selected = _selectedInterests.contains(interest);

    return FilterChip(
      label: Text(interest),
      selected: selected,
      onSelected: _saving
          ? null
          : (value) {
              setState(() {
                if (value) {
                  _selectedInterests.add(interest);
                } else {
                  _selectedInterests.remove(interest);
                }
              });
            },
      selectedColor: WorldCompanionColors.infoSurface,
      checkmarkColor: WorldCompanionColors.oceanBlue,
      backgroundColor: WorldCompanionColors.surface,
      side: BorderSide(
        color: selected
            ? WorldCompanionColors.oceanBlue
            : WorldCompanionColors.border,
      ),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected
                ? WorldCompanionColors.oceanBlue
                : WorldCompanionColors.primaryText,
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WorldCompanionRadius.medium),
      ),
      showCheckmark: true,
    );
  }

  Widget _selectionCard({
    required String value,
    required String selectedValue,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final selected = value == selectedValue;

    return Semantics(
      button: true,
      selected: selected,
      label: value,
      child: InkWell(
        onTap: _saving ? null : onTap,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        child: AnimatedContainer(
          duration: WorldCompanionMotion.standard,
          curve: WorldCompanionMotion.standardCurve,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: WorldCompanionSpacing.md,
            horizontal: WorldCompanionSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected
                ? WorldCompanionColors.infoSurface
                : WorldCompanionColors.surface,
            borderRadius:
                BorderRadius.circular(WorldCompanionRadius.large),
            border: Border.all(
              color: selected
                  ? WorldCompanionColors.oceanBlue
                  : WorldCompanionColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : icon,
                color: selected
                    ? WorldCompanionColors.oceanBlue
                    : WorldCompanionColors.mutedText,
                size: 23,
              ),
              const SizedBox(height: WorldCompanionSpacing.xs),
              Text(
                value,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? WorldCompanionColors.oceanBlue
                          : WorldCompanionColors.primaryText,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.md),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.extraLarge),
        border: Border.all(color: WorldCompanionColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B2545),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildOptionRow({
    required List<String> options,
    required String selectedValue,
    required IconData Function(String value) iconFor,
    required ValueChanged<String> onSelected,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < options.length; i++) ...[
          if (i > 0)
            const SizedBox(width: WorldCompanionSpacing.xs),
          Expanded(
            child: _selectionCard(
              value: options[i],
              selectedValue: selectedValue,
              icon: iconFor(options[i]),
              onTap: () => onSelected(options[i]),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorldCompanionColors.mapSurface,
      appBar: AppBar(
        title: Text(
          'Travel preferences',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: WorldCompanionColors.mapSurface,
        foregroundColor: WorldCompanionColors.primaryText,
        elevation: WorldCompanionElevation.none,
        scrolledUnderElevation: WorldCompanionElevation.none,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            WorldCompanionSpacing.mobilePage,
            WorldCompanionSpacing.xs,
            WorldCompanionSpacing.mobilePage,
            WorldCompanionSpacing.xxxl,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    WorldCompanionColors.deepOcean,
                    WorldCompanionColors.oceanBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.circular(WorldCompanionRadius.extraLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(WorldCompanionRadius.medium),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                  const SizedBox(height: WorldCompanionSpacing.lg),
                  Text(
                    'Shape your journey',
                    style: WorldCompanionTypography.editorial.copyWith(
                      color: Colors.white,
                      fontSize: 30,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: WorldCompanionSpacing.xs),
                  Text(
                    'Tell WorldCompanion what you enjoy, '
                    'how you travel, and what fits your budget.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          height: 1.6,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.xl),
            _sectionTitle(
              'Your interests',
              'Choose the experiences you would like to discover.',
            ),
            const SizedBox(height: WorldCompanionSpacing.md),
            _sectionCard(
              child: Wrap(
                spacing: WorldCompanionSpacing.xs,
                runSpacing: WorldCompanionSpacing.xs,
                children: _interestOptions.map(_interestChip).toList(),
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.xl),
            _sectionTitle(
              'Your budget',
              'Choose a spending level that suits your trip.',
            ),
            const SizedBox(height: WorldCompanionSpacing.md),
            _sectionCard(
              child: _buildOptionRow(
                options: _budgetOptions,
                selectedValue: _selectedBudget,
                iconFor: (value) {
                  switch (value) {
                    case 'Budget':
                      return Icons.savings_outlined;
                    case 'Premium':
                      return Icons.diamond_outlined;
                    default:
                      return Icons.account_balance_wallet_outlined;
                  }
                },
                onSelected: (value) {
                  setState(() {
                    _selectedBudget = value;
                  });
                },
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.xl),
            _sectionTitle(
              'Travel style',
              'Choose the pace that feels right for you.',
            ),
            const SizedBox(height: WorldCompanionSpacing.md),
            _sectionCard(
              child: _buildOptionRow(
                options: _travelStyleOptions,
                selectedValue: _selectedTravelStyle,
                iconFor: (value) {
                  switch (value) {
                    case 'Relaxed':
                      return Icons.spa_outlined;
                    case 'Adventure':
                      return Icons.hiking_outlined;
                    default:
                      return Icons.explore_outlined;
                  }
                },
                onSelected: (value) {
                  setState(() {
                    _selectedTravelStyle = value;
                  });
                },
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.xl),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WorldCompanionColors.deepOcean,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      WorldCompanionColors.deepOcean.withOpacity(0.45),
                  disabledForegroundColor: Colors.white70,
                  elevation: WorldCompanionElevation.none,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(WorldCompanionRadius.large),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: WorldCompanionMotion.fast,
                  child: _saving
                      ? const SizedBox(
                          key: ValueKey('saving'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          key: const ValueKey('save'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, size: 20),
                            const SizedBox(width: WorldCompanionSpacing.xs),
                            Text(
                              'Save preferences',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.sm),
            Text(
              'Your choices help personalize your travel suggestions.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
