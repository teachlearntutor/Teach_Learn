import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/theme_mode_toggle.dart';
import '../providers/auth_providers.dart';
import 'google_role_selection_screen.dart';
import '../../../learner/presentation/screens/learner_home_screen.dart';
import '../../../tutor/presentation/screens/tutor_home_screen.dart';

enum AuthAudience { tutor, learnerOrParent }

enum AuthMode { logIn, signUp }

enum _SeekingRole { student, parent }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    super.key,
    this.onThemeModeChanged,
    this.initialMode = AuthMode.logIn,
  });

  final AuthMode initialMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthMode _mode = AuthMode.logIn;
  AuthAudience _audience = AuthAudience.tutor;
  _SeekingRole _seekingRole = _SeekingRole.student;

  bool _showPassword = false;
  bool _showConfirmation = false;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  bool _isResettingPassword = false;
  bool _showHeader = false;

  bool get _isTutor => _audience == AuthAudience.tutor;
  bool get _isSignUp => _mode == AuthMode.signUp;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showHeader = true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _selectedRoleString {
    if (_isTutor) return 'tutor';
    return _seekingRole == _SeekingRole.student ? 'student' : 'parent';
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'Enter your full name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    if (_isSignUp && value.length < 8) {
      return 'Use at least 8 characters';
    }
    return null;
  }

  void _changeMode(AuthMode mode) {
    setState(() {
      _mode = mode;
      _formKey.currentState?.reset();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
        ),
      );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
        ),
      );
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _showErrorSnackBar('Please enter a valid email address in the field above first.');
      return;
    }

    setState(() => _isResettingPassword = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendPasswordResetEmail(email);
      if (!mounted) return;
      _showSuccessSnackBar('Password reset email sent to $email. Please check your inbox.');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isResettingPassword = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _isGoogleSubmitting = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.signInWithGoogle();

      if (!mounted) return;

      if (result.isNewUser) {
        // New Google user -> show role selection screen
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GoogleRoleSelectionScreen(user: result.user),
          ),
        );
      } else {
        // Existing user -> navigate straight home based on role
        final role = result.existingRole ?? 'tutor';
        final destination = role == 'tutor'
            ? const TutorHomeScreen()
            : const LearnerHomeScreen();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => destination),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('cancelled')) {
        _showErrorSnackBar('Google sign-in was cancelled.');
      } else {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isGoogleSubmitting = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);

      if (_isSignUp) {
        // Handle Email Sign Up
        await authRepo.signUpWithEmail(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRoleString,
        );

        if (!mounted) return;
        final destination = _selectedRoleString == 'tutor'
            ? const TutorHomeScreen()
            : const LearnerHomeScreen();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => destination),
          (route) => false,
        );
      } else {
        // Handle Email Log In
        final user = await authRepo.logInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final role = await authRepo.getUserRole(user.uid);

        if (!mounted) return;
        final destination = (role == 'tutor')
            ? const TutorHomeScreen()
            : const LearnerHomeScreen();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => destination),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final screenSize = MediaQuery.sizeOf(context);

    final headerHeight = isKeyboardOpen
        ? 60.0
        : (screenSize.height * 0.32).clamp(160.0, 240.0);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            RepaintBoundary(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: headerHeight,
                child: _buildBrandHeader(context, isKeyboardOpen),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: ValueKey(_mode),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isSignUp ? 'Create your account' : 'Welcome back',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          if (_isSignUp) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'I am joining as',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outlineVariant,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _AudienceSegment(
                                      label: "I'm a Tutor",
                                      selected: _isTutor,
                                      onTap: () => setState(
                                        () => _audience = AuthAudience.tutor,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _AudienceSegment(
                                      label: "I'm looking for a tutor",
                                      selected: !_isTutor,
                                      onTap: () => setState(
                                        () => _audience = AuthAudience.learnerOrParent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!_isTutor) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'I am a',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SegmentedButton<_SeekingRole>(
                                segments: const [
                                  ButtonSegment<_SeekingRole>(
                                    value: _SeekingRole.student,
                                    label: Text('Student'),
                                    icon: Icon(Icons.person_outline_rounded),
                                  ),
                                  ButtonSegment<_SeekingRole>(
                                    value: _SeekingRole.parent,
                                    label: Text('Parent'),
                                    icon: Icon(Icons.family_restroom_rounded),
                                  ),
                                ],
                                selected: {_seekingRole},
                                onSelectionChanged: (selection) {
                                  setState(
                                    () => _seekingRole = selection.first,
                                  );
                                },
                              ),
                            ],
                          ],
                          SizedBox(
                            height: _isSignUp ? AppSpacing.md : AppSpacing.lg,
                          ),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_isSignUp) ...[
                                  AppTextField(
                                    label: 'Full name',
                                    hint: 'Your full name',
                                    controller: _nameController,
                                    textCapitalization: TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.name],
                                    validator: _validateName,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                                AppTextField(
                                  label: 'Email address',
                                  hint: 'name@example.com',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  label: 'Password',
                                  hint: _isSignUp ? 'At least 8 characters' : null,
                                  controller: _passwordController,
                                  obscureText: !_showPassword,
                                  textInputAction:
                                      _isSignUp ? TextInputAction.next : TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  validator: _validatePassword,
                                  suffixIcon: IconButton(
                                    tooltip: _showPassword ? 'Hide password' : 'Show password',
                                    onPressed: () => setState(
                                      () => _showPassword = !_showPassword,
                                    ),
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                if (_isSignUp) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  AppTextField(
                                    label: 'Confirm password',
                                    hint: 'Re-enter your password',
                                    controller: _confirmPasswordController,
                                    obscureText: !_showConfirmation,
                                    textInputAction: TextInputAction.done,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Confirm your password';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                    suffixIcon: IconButton(
                                      tooltip:
                                          _showConfirmation ? 'Hide password' : 'Show password',
                                      onPressed: () => setState(
                                        () => _showConfirmation = !_showConfirmation,
                                      ),
                                      icon: Icon(
                                        _showConfirmation
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!_isSignUp) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isResettingPassword ? null : _handleForgotPassword,
                                child: _isResettingPassword
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Forgot password?'),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          AppButton.primary(
                            label: _isSubmitting
                                ? 'Please wait'
                                : _isSignUp
                                    ? 'Create account'
                                    : 'Log in',
                            isLoading: _isSubmitting,
                            isFullWidth: true,
                            onPressed: _isSubmitting ? null : _submit,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                child: Text(
                                  'or',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppButton.secondary(
                            label: 'Continue with Google',
                            isLoading: _isGoogleSubmitting,
                            icon: Icon(
                              Icons.g_mobiledata_rounded,
                              size: 26,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            isFullWidth: true,
                            onPressed: _isGoogleSubmitting ? null : _handleGoogleSignIn,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _isSignUp ? 'Already have an account?' : 'New to TeachLearn?',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: () => _changeMode(
                                  _isSignUp ? AuthMode.logIn : AuthMode.signUp,
                                ),
                                child: Text(
                                  _isSignUp ? 'Log in' : 'Create account',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context, bool isKeyboardOpen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark
        ? AppColors.primaryTealLight.withValues(alpha: 0.14)
        : AppColors.primaryTeal.withValues(alpha: 0.08);

    return ColoredBox(
      color: tint,
      child: Stack(
        children: [
          const Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: ThemeModeToggle(),
          ),
          if (!isKeyboardOpen)
            Center(
              child: AnimatedSlide(
                offset: _showHeader ? Offset.zero : const Offset(0, 0.08),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _showHeader ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandMark(size: 44),
                      SizedBox(height: AppSpacing.xs),
                      BrandWordmark(fontSize: 21),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AudienceSegment extends StatelessWidget {
  const _AudienceSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: selected
          ? (isDark
              ? AppColors.primaryTealLight.withValues(alpha: 0.2)
              : AppColors.primaryTeal.withValues(alpha: 0.12))
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected
                  ? (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal)
                  : theme.textTheme.bodyMedium?.color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
