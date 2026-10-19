import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../auth/presentation/screens/google_role_selection_screen.dart';
import '../../../learner/presentation/screens/learner_home_screen.dart';
import '../../../tutor/presentation/screens/tutor_home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, this.onThemeModeChanged});

  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleAutoLogin();
  }

  Future<void> _handleAutoLogin() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.authStateChanges.first;

      if (user == null) {
        _navigateToAuth();
        return;
      }

      final profile = await authRepo.getUserProfile(user.uid);
      if (!mounted) return;
      final role = profile?['role'];

      if (role is! String ||
          !const {'tutor', 'student', 'parent'}.contains(role.toLowerCase())) {
        _navigateToCompleteProfile(user);
        return;
      }

      final destination = role.toLowerCase() == 'tutor'
          ? const TutorHomeScreen()
          : const LearnerHomeScreen();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => destination),
        (route) => false,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load your account. Please try again. $error';
        });
      }
    }
  }

  void _navigateToCompleteProfile(User user) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => GoogleRoleSelectionScreen(user: user),
      ),
      (route) => false,
    );
  }

  void _navigateToAuth() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const AuthScreen(
          initialMode: AuthMode.logIn,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _errorMessage;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: errorMessage == null
            ? const Column(
          children: [
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandMark(size: 76),
                      SizedBox(height: AppSpacing.md),
                      BrandWordmark(fontSize: 28),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.lg),
              child: RepaintBoundary(
                child: AppLoader.inline(size: 20),
              ),
            ),
          ],
        )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(errorMessage, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: () {
                          setState(() => _errorMessage = null);
                          _handleAutoLogin();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
