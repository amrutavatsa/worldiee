import 'package:flutter/material.dart';

import '../google_sign_in_button.dart';
import '../services/auth_service.dart';
import '../theme/world_companion_colors.dart';
import '../theme/world_companion_elevation.dart';
import '../theme/world_companion_motion.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';
import 'app_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await AuthService.login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      } else {
        await AuthService.register(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const AppShell(),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleGoogleSuccess() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const AppShell(),
      ),
    );
  }

  void _handleGoogleError(Object error) {
    if (!mounted) return;

    setState(() {
      _errorMessage = _cleanErrorMessage(error);
    });
  }

  String _cleanErrorMessage(Object error) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();

    if (message.isEmpty) {
      return 'Something went wrong. Please try again.';
    }

    return message;
  }

  void _toggleMode() {
    if (_isLoading) return;

    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 760;

    return Scaffold(
      backgroundColor: WorldCompanionColors.aiSurface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide
                  ? WorldCompanionSpacing.xl
                  : WorldCompanionSpacing.md,
              vertical: WorldCompanionSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 1000 : 460,
              ),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: WorldCompanionSpacing.xl,
                            ),
                            child: _buildBrandPanel(context),
                          ),
                        ),
                        const SizedBox(
                          width: WorldCompanionSpacing.md,
                        ),
                        Expanded(
                          child: _buildFormPanel(context),
                        ),
                      ],
                    )
                  : _buildFormPanel(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandPanel(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 560),
      padding: const EdgeInsets.all(WorldCompanionSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WorldCompanionColors.deepOcean,
            WorldCompanionColors.oceanBlue,
            WorldCompanionColors.navyBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const _BrandMark(
                size: 46,
                background: Color(0x22FFFFFF),
                foreground: Colors.white,
              ),
              const SizedBox(width: WorldCompanionSpacing.sm),
              Text(
                'WORLD COMPANION',
                style: WorldCompanionTypography.brand.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: WorldCompanionSpacing.xl),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: WorldCompanionSpacing.sm,
                  vertical: WorldCompanionSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(
                    WorldCompanionRadius.pill,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.16),
                  ),
                ),
                child: Text(
                  'YOUR JOURNEY, CONNECTED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WorldCompanionColors.softWhite,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: WorldCompanionSpacing.lg),
              Text(
                'The world is\nwaiting for you.',
                style: WorldCompanionTypography.editorial.copyWith(
                  fontSize: 42,
                  height: 1.18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: WorldCompanionSpacing.md),
              Text(
                'Discover places, plan meaningful trips, '
                'and travel with a smarter companion by your side.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.78),
                  height: 1.8,
                ),
              ),
              const SizedBox(height: WorldCompanionSpacing.xl),
              const _FeatureRow(
                icon: Icons.explore_outlined,
                title: 'Discover somewhere new',
                subtitle: 'Find places worth exploring.',
              ),
              const SizedBox(height: WorldCompanionSpacing.lg),
              const _FeatureRow(
                icon: Icons.route_rounded,
                title: 'Plan your next journey',
                subtitle: 'Bring your travel ideas together.',
              ),
              const SizedBox(height: WorldCompanionSpacing.lg),
              const _FeatureRow(
                icon: Icons.shield_outlined,
                title: 'Travel with confidence',
                subtitle: 'Keep useful travel tools close.',
              ),
            ],
          ),
          const SizedBox(height: WorldCompanionSpacing.xl),
          Text(
            'YOUR NEXT CHAPTER STARTS HERE.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.60),
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 760;

    return Container(
      padding: EdgeInsets.all(
        isWide
            ? WorldCompanionSpacing.xl
            : WorldCompanionSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
        border: Border.all(
          color: WorldCompanionColors.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0B2545),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isWide) ...[
              const Center(
                child: _BrandMark(
                  size: 60,
                  background: WorldCompanionColors.deepOcean,
                  foreground: Colors.white,
                ),
              ),
              const SizedBox(height: WorldCompanionSpacing.md),
              Text(
                'WORLD COMPANION',
                textAlign: TextAlign.center,
                style: WorldCompanionTypography.brand.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: WorldCompanionSpacing.xl),
            ],
            Text(
              _isLogin ? 'Welcome back' : 'Create your account',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.xs),
            Text(
              _isLogin
                  ? 'Sign in to pick up where your journey left off.'
                  : 'Create an account and start planning your next adventure.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.65,
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.lg),
            _buildModeSelector(),
            const SizedBox(height: WorldCompanionSpacing.lg),
            Text(
              'Username',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: WorldCompanionSpacing.xs),
            TextFormField(
              controller: _usernameController,
              enabled: !_isLoading,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                hintText: 'Enter your username',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username is required';
                }
                return null;
              },
            ),
            const SizedBox(height: WorldCompanionSpacing.md),
            Text(
              'Password',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: WorldCompanionSpacing.xs),
            TextFormField(
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: [
                _isLogin
                    ? AutofillHints.password
                    : AutofillHints.newPassword,
              ],
              onFieldSubmitted: (_) {
                if (!_isLoading) _submit();
              },
              decoration: InputDecoration(
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Show password'
                      : 'Hide password',
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (!_isLogin && value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            if (!_isLogin) ...[
              const SizedBox(height: WorldCompanionSpacing.sm),
              Text(
                'Use at least 8 characters for your password.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: WorldCompanionSpacing.md),
              _ErrorBanner(message: _errorMessage!),
            ],
            const SizedBox(height: WorldCompanionSpacing.lg),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: AnimatedSwitcher(
                  duration: WorldCompanionMotion.fast,
                  child: _isLoading
                      ? const SizedBox(
                          key: ValueKey<String>('loading'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          key: ValueKey<String>(
                            _isLogin ? 'login' : 'register',
                          ),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin ? 'Sign in' : 'Create account',
                            ),
                            const SizedBox(
                              width: WorldCompanionSpacing.xs,
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.lg),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WorldCompanionSpacing.md,
                  ),
                  child: Text(
                    'OR CONTINUE WITH',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: WorldCompanionSpacing.lg),
            Center(
              child: GoogleSignInButton(
                onSuccess: _handleGoogleSuccess,
                onError: _handleGoogleError,
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.md),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _isLogin
                        ? 'New to World Companion? '
                        : 'Already have an account? ',
                    style: theme.textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _toggleMode,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: WorldCompanionSpacing.xs,
                        vertical: WorldCompanionSpacing.xs,
                      ),
                    ),
                    child: Text(
                      _isLogin ? 'Create account' : 'Sign in',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.sm),
            Text(
              'By continuing, you agree to use World Companion as a '
              'travel planning and assistance platform.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: WorldCompanionColors.mutedText,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(WorldCompanionSpacing.xxs),
      decoration: BoxDecoration(
        color: WorldCompanionColors.aiSurface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.medium,
        ),
        border: Border.all(
          color: WorldCompanionColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Sign in',
              selected: _isLogin,
              onPressed: _isLoading
                  ? null
                  : () {
                      if (!_isLogin) _toggleMode();
                    },
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Register',
              selected: !_isLogin,
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_isLogin) _toggleMode();
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final double size;
  final Color background;
  final Color foreground;

  const _BrandMark({
    required this.size,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.large,
        ),
      ),
      child: Icon(
        Icons.explore_rounded,
        color: foreground,
        size: size * 0.52,
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(
              WorldCompanionRadius.medium,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.14),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 21,
          ),
        ),
        const SizedBox(width: WorldCompanionSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: WorldCompanionSpacing.xxs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.70),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WorldCompanionSpacing.md),
      decoration: BoxDecoration(
        color: WorldCompanionColors.errorSurface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.medium,
        ),
        border: Border.all(
          color: WorldCompanionColors.error.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: WorldCompanionColors.error,
          ),
          const SizedBox(width: WorldCompanionSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: WorldCompanionColors.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: WorldCompanionMotion.fast,
      curve: WorldCompanionMotion.standardCurve,
      decoration: BoxDecoration(
        color: selected
            ? WorldCompanionColors.deepOcean
            : Colors.transparent,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.small,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x140B2545),
                  blurRadius: WorldCompanionElevation.medium * 2,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(
            WorldCompanionRadius.small,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: WorldCompanionSpacing.sm,
              horizontal: WorldCompanionSpacing.xs,
            ),
            child: Center(
              child: Text(
                label,
                style: WorldCompanionTypography.textTheme.labelLarge
                    ?.copyWith(
                  color: selected
                      ? Colors.white
                      : WorldCompanionColors.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
