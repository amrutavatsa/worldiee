import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/world_companion_colors.dart';
import '../theme/world_companion_motion.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';
import 'safety_screen.dart';
import 'bookings_screen.dart';
import 'preferences_screen.dart';
import 'recommendations_screen.dart';
import 'auth_screen.dart';
import 'app_shell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadGooglePhoto();
  }
  Future<void> _loadGooglePhoto() async {
    final url = await AuthService.getGooglePhotoUrl();
    if (!mounted) return;
    setState(() => _photoUrl = url);
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final token = await AuthService.getToken();

      if (token == null) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _error = 'Your session has expired. Please log in again.';
        });
        return;
      }

      final response = await ApiService.getProfile();

      if (!mounted) return;

      setState(() {
        _profile = response;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Unable to load your profile right now.';
      });
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: WorldCompanionColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              WorldCompanionRadius.extraLarge,
            ),
          ),
          title: Text(
            'Log out?',
            style: Theme.of(dialogContext).textTheme.titleLarge,
          ),
          content: Text(
            'You can log back in anytime to continue using WorldCompanion.',
            style: Theme.of(dialogContext).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: WorldCompanionColors.deepOcean,
                foregroundColor: Colors.white,
              ),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await AuthService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AuthScreen(),
      ),
      (route) => false,
    );
  }

  String get _name {
    final name = _profile?['name']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    final firstName = _profile?['first_name']?.toString().trim() ?? '';
    final lastName = _profile?['last_name']?.toString().trim() ?? '';
    final fallbackName = '$firstName $lastName'.trim();

    return fallbackName.isNotEmpty ? fallbackName : 'Traveler';
  }

  String get _email => _profile?['username']?.toString() ?? '—';

  String get _userId => _profile?['id']?.toString() ?? '—';

  String get _initial {
    final name = _name.trim();
    return name.isEmpty ? 'W' : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorldCompanionColors.mapSurface,
      body: SafeArea(
        child: RefreshIndicator(
          color: WorldCompanionColors.oceanBlue,
          onRefresh: _loadProfile,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    WorldCompanionSpacing.mobilePage,
                    WorldCompanionSpacing.md,
                    WorldCompanionSpacing.mobilePage,
                    0,
                  ),
                  child: _buildHeader(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    WorldCompanionSpacing.mobilePage,
                    WorldCompanionSpacing.lg,
                    WorldCompanionSpacing.mobilePage,
                    0,
                  ),
                  child: _buildProfileCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    WorldCompanionSpacing.mobilePage,
                    WorldCompanionSpacing.xl,
                    WorldCompanionSpacing.mobilePage,
                    0,
                  ),
                  child: _buildTravelHubHeader(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    WorldCompanionSpacing.mobilePage,
                    WorldCompanionSpacing.md,
                    WorldCompanionSpacing.mobilePage,
                    0,
                  ),
                  child: _buildModuleGrid(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    WorldCompanionSpacing.mobilePage,
                    WorldCompanionSpacing.xl,
                    WorldCompanionSpacing.mobilePage,
                    0,
                  ),
                  child: _buildAccountSection(),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: WorldCompanionSpacing.xxxl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back to home',
          onPressed: () => AppShellNavigation.of(context).goHome(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: WorldCompanionSpacing.xs),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: WorldCompanionColors.deepOcean,
            borderRadius: BorderRadius.circular(
              WorldCompanionRadius.medium,
            ),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: WorldCompanionSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WORLD COMPANION',
                style: WorldCompanionTypography.brand,
              ),
              const SizedBox(height: WorldCompanionSpacing.xxs),
              Text(
                'Your profile',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh profile',
          onPressed: _loading ? null : _loadProfile,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    if (_loading) {
      return Container(
        height: 174,
        decoration: _cardDecoration(),
        child: const Center(
          child: CircularProgressIndicator(
            color: WorldCompanionColors.oceanBlue,
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.person_off_outlined,
              color: WorldCompanionColors.mutedText,
              size: 30,
            ),
            const SizedBox(height: WorldCompanionSpacing.md),
            Text(
              'Profile unavailable',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: WorldCompanionSpacing.xs),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: WorldCompanionSpacing.md),
            OutlinedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    return Container(
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
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180B2545),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
            ),
            alignment: Alignment.center,
            child: _photoUrl != null && _photoUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      _photoUrl!,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        _initial,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                      ),
                    ),
                  )
                : Text(
                    _initial,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
          ),
          const SizedBox(width: WorldCompanionSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR WORLD COMPANION',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 1,
                      ),
                ),
                const SizedBox(height: WorldCompanionSpacing.xs),
                Text(
                  _name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WorldCompanionTypography.editorial.copyWith(
                    color: Colors.white,
                    fontSize: 27,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: WorldCompanionSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WorldCompanionSpacing.sm,
                    vertical: WorldCompanionSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(
                      WorldCompanionRadius.pill,
                    ),
                  ),
                  child: Text(
                    'Traveler ID  $_userId',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelHubHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your travel hub',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: WorldCompanionSpacing.xs),
        Text(
          'Your journey, preferences, safety and stays in one place.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildModuleGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 650;
        final crossAxisCount = isWide ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: WorldCompanionSpacing.sm,
          mainAxisSpacing: WorldCompanionSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isWide ? 0.92 : 1.05,
          children: [
            _moduleCard(
              icon: Icons.shield_outlined,
              title: 'Safety',
              subtitle: 'Emergency contacts and SOS',
              iconBackground: WorldCompanionColors.successSurface,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SafetyScreen(),
                  ),
                );
              },
            ),
            _moduleCard(
              icon: Icons.tune_rounded,
              title: 'Preferences',
              subtitle: 'Your travel style',
              iconBackground: WorldCompanionColors.warningSurface,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PreferencesScreen(),
                  ),
                );
              },
            ),
            _moduleCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Recommendations',
              subtitle: 'Ideas for your journey',
              iconBackground: WorldCompanionColors.infoSurface,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecommendationsScreen(),
                  ),
                );
              },
            ),
            _moduleCard(
              icon: Icons.receipt_long_outlined,
              title: 'Bookings',
              subtitle: 'Your booking history',
              iconBackground: WorldCompanionColors.aiSurface,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookingsScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _moduleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBackground,
    required VoidCallback onTap,
  }) {
    return Material(
      color: WorldCompanionColors.surface,
      borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        child: AnimatedContainer(
          duration: WorldCompanionMotion.standard,
          curve: WorldCompanionMotion.standardCurve,
          padding: const EdgeInsets.all(WorldCompanionSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              WorldCompanionRadius.large,
            ),
            border: Border.all(color: WorldCompanionColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080B2545),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(
                    WorldCompanionRadius.medium,
                  ),
                ),
                child: Icon(
                  icon,
                  color: WorldCompanionColors.oceanBlue,
                  size: 23,
                ),
              ),
              const SizedBox(height: WorldCompanionSpacing.md),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: WorldCompanionSpacing.xxs),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_outward_rounded,
                  color: WorldCompanionColors.mutedText,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: WorldCompanionSpacing.md),
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _accountTile(
                icon: Icons.person_outline_rounded,
                title: 'Name',
                value: _name,
              ),
              _accountDivider(),
              _accountTile(
                icon: Icons.email_outlined,
                title: 'Email / username',
                value: _email,
              ),
              _accountDivider(),
              _accountTile(
                icon: Icons.badge_outlined,
                title: 'Traveler ID',
                value: _userId,
              ),
              _accountDivider(),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: WorldCompanionSpacing.md,
                  vertical: WorldCompanionSpacing.xs,
                ),
                leading: _accountIcon(
                  Icons.logout_rounded,
                  WorldCompanionColors.errorSurface,
                  WorldCompanionColors.error,
                ),
                title: Text(
                  'Log out',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: WorldCompanionColors.error,
                      ),
                ),
                subtitle: Text(
                  'Sign out of this account',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: WorldCompanionColors.mutedText,
                ),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _accountDivider() {
    return const Divider(
      height: 1,
      indent: 68,
      color: WorldCompanionColors.border,
    );
  }

  Widget _accountIcon(
    IconData icon,
    Color background,
    Color foreground,
  ) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.medium),
      ),
      child: Icon(
        icon,
        color: foreground,
        size: 21,
      ),
    );
  }

  Widget _accountTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: WorldCompanionSpacing.md,
        vertical: WorldCompanionSpacing.xs,
      ),
      leading: _accountIcon(
        icon,
        WorldCompanionColors.infoSurface,
        WorldCompanionColors.oceanBlue,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      subtitle: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: WorldCompanionColors.surface,
      borderRadius: BorderRadius.circular(WorldCompanionRadius.extraLarge),
      border: Border.all(color: WorldCompanionColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080B2545),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    );
  }
}
