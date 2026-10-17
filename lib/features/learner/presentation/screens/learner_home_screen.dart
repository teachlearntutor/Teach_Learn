import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/theme_mode_toggle.dart';
import '../../../auth/presentation/screens/auth_screen.dart';

class LearnerHomeScreen extends StatelessWidget {
  const LearnerHomeScreen({super.key, this.onThemeModeChanged});

  final ValueChanged<ThemeMode>? onThemeModeChanged;

  void _logout(BuildContext context) {
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
      appBar: AppBar(
        title: const Text('TeachLearn'),
        actions: [
          const ThemeModeToggle(),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: EmptyStateWidget(
              icon: Icons.search_rounded,
              title: 'Your learning space',
              description:
                  'Tutor discovery and lesson requests will appear here.',
            ),
          ),
        ),
      ),
    );
  }
}
