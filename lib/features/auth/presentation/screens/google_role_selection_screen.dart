import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../learner/presentation/screens/learner_home_screen.dart';
import '../../../tutor/presentation/screens/tutor_home_screen.dart';
import '../providers/auth_providers.dart';

/// Screen presented to users who need to choose a role to complete their profile.
class GoogleRoleSelectionScreen extends ConsumerStatefulWidget {
  final User user;

  const GoogleRoleSelectionScreen({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<GoogleRoleSelectionScreen> createState() => _GoogleRoleSelectionScreenState();
}

class _GoogleRoleSelectionScreenState extends ConsumerState<GoogleRoleSelectionScreen> {
  String _selectedRole = 'tutor';
  bool _isSaving = false;

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.repairUserProfile(
        uid: widget.user.uid,
        displayName: widget.user.displayName ?? 'TeachLearn User',
        email: widget.user.email ?? '',
        role: _selectedRole,
      );

      if (!mounted) return;
      final destination = _selectedRole == 'tutor'
          ? const TutorHomeScreen()
          : const LearnerHomeScreen();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => destination),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: BrandMark(size: 56)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Complete profile',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Welcome, ${widget.user.displayName ?? "there"}! Select your role to finish setting up your account.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Role Options
              _RoleOptionTile(
                title: "I'm a Tutor",
                subtitle: 'Manage students, schedules, and attendance.',
                icon: Icons.school_rounded,
                selected: _selectedRole == 'tutor',
                onTap: () => setState(() => _selectedRole = 'tutor'),
              ),
              const SizedBox(height: AppSpacing.md),
              _RoleOptionTile(
                title: "I'm a Student",
                subtitle: 'View your class schedule and learning progress.',
                icon: Icons.person_rounded,
                selected: _selectedRole == 'student',
                onTap: () => setState(() => _selectedRole = 'student'),
              ),
              const SizedBox(height: AppSpacing.md),
              _RoleOptionTile(
                title: "I'm a Parent",
                subtitle: 'Track your child\'s tuition schedule and progress.',
                icon: Icons.family_restroom_rounded,
                selected: _selectedRole == 'parent',
                onTap: () => setState(() => _selectedRole = 'parent'),
              ),

              const SizedBox(height: AppSpacing.xl),
              AppButton.primary(
                label: 'Continue',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: selected
          ? (isDark
              ? AppColors.primaryTealLight.withValues(alpha: 0.2)
              : AppColors.primaryTeal.withValues(alpha: 0.1))
          : theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: selected ? 2.0 : 1.0,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: selected
              ? (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal)
              : theme.colorScheme.surface,
          child: Icon(
            icon,
            color: selected ? Colors.white : theme.iconTheme.color,
          ),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: selected
            ? Icon(
                Icons.check_circle_rounded,
                color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
              )
            : null,
      ),
    );
  }
}
