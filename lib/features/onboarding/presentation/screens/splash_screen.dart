import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../learner/presentation/screens/learner_home_screen.dart';
import '../../../tutor/presentation/screens/tutor_home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, this.onThemeModeChanged});

  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
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
      final user = authRepo.currentUser;

      if (user == null) {
        _navigateToAuth();
        return;
      }

      final role = await authRepo.getUserRole(user.uid);
      if (!mounted) return;

      final destination = role == 'tutor'
          ? const TutorHomeScreen()
          : const LearnerHomeScreen();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => destination),
        (route) => false,
      );
    } catch (_) {
      // If profile fails or is missing, sign out and go to AuthScreen
      if (mounted) {
        try {
          await ref.read(authRepositoryProvider).signOut();
        } catch (_) {}
        _navigateToAuth();
      }
    }
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const SafeArea(
        child: Column(
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
        ),
      ),
    );
  }
}
