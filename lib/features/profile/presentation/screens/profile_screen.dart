import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/theme_mode_toggle.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../providers/profile_providers.dart';

const String _kAvatarColorKey = 'pref_avatar_color_index';

final List<Color> _kAvatarColors = const [
  AppColors.primaryTeal,
  AppColors.accentTeal,
  AppColors.success,
  AppColors.warning,
  AppColors.danger,
  Color(0xFF3F51B5), // Deep Indigo
  Color(0xFF8E24AA), // Purple Accent
  Color(0xFF00897B), // Deep Teal
];

/// Feature-rich, production-ready Profile & Settings Screen.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoggingOut = false;
  int _selectedAvatarColorIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAvatarColor();
  }

  Future<void> _loadAvatarColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_kAvatarColorKey) ?? 0;
      if (index >= 0 && index < _kAvatarColors.length) {
        setState(() => _selectedAvatarColorIndex = index);
      }
    } catch (_) {}
  }

  Future<void> _setAvatarColor(int index) async {
    setState(() => _selectedAvatarColorIndex = index);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kAvatarColorKey, index);
    } catch (_) {}
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out of TeachLearn?'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signOut();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const AuthScreen(
            initialMode: AuthMode.logIn,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign out error: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Copied $label "$text" to clipboard!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _showAvatarColorPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.sheetBorderRadius,
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose Avatar Color',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Select your preferred background accent color.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: List.generate(_kAvatarColors.length, (index) {
                final color = _kAvatarColors[index];
                final isSelected = index == _selectedAvatarColorIndex;
                return GestureDetector(
                  onTap: () {
                    _setAvatarColor(index);
                    Navigator.pop(sheetContext);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditNameDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.sheetBorderRadius,
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Display Name',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Full Name',
                  controller: controller,
                  textCapitalization: TextCapitalization.words,
                  validator: (val) {
                    if (val == null || val.trim().length < 2) {
                      return 'Enter a valid name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton.primary(
                  label: 'Save Changes',
                  isLoading: isSaving,
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(sheetContext);
                          setSheetState(() => isSaving = true);
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              await user.updateDisplayName(controller.text.trim());
                            }
                            navigator.pop();
                            if (mounted) setState(() {});
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Display name updated successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } catch (e) {
                            setSheetState(() => isSaving = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    if (email.isEmpty) return;
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $email.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showHelpSupportModal() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.sheetBorderRadius,
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Help & Support', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Need assistance with your TeachLearn account or classes? Contact our support team directly.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: AppColors.primaryTeal),
              title: const Text('Email Support'),
              subtitle: const Text('support@teachlearn.app'),
              onTap: () => _copyToClipboard('support@teachlearn.app', 'Support Email'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded, color: AppColors.primaryTeal),
              title: const Text('User Guide & FAQ'),
              subtitle: const Text('Learn how to manage students & schedules'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('User Guide will be available in next update.')),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicyModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.sheetBorderRadius,
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Privacy & Safety', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'TeachLearn respects your personal data privacy.\n\n'
                  '1. Account Data:\n'
                  'Your profile and class details are stored securely on Cloud Firestore and protected by strict owner-only Security Rules.\n\n'
                  '2. \$0 Cost & Spark Plan:\n'
                  'No third-party trackers, advertisements, or paid analytics are embedded in this application.\n\n'
                  '3. Data Protection:\n'
                  'Only authorized users linked to your classes can view shared session records.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.primary(
              label: 'Close',
              isFullWidth: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      user = ref.watch(authRepositoryProvider).currentUser;
    } catch (_) {}

    final uid = user?.uid ?? '';
    final displayName = user?.displayName ?? 'TeachLearn User';
    final email = user?.email ?? 'No email associated';

    final profileState = uid.isNotEmpty ? ref.watch(userProfileProvider(uid)) : null;
    final profileData = profileState?.asData?.value;
    final role = (profileData?['role'] as String? ?? 'tutor').toUpperCase();
    final publicId = profileData?['publicId'] as String? ?? '';

    final notificationSettings = ref.watch(notificationSettingsProvider);
    final currentLanguage = ref.watch(appLanguageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final avatarColor = _kAvatarColors[_selectedAvatarColorIndex];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // User Profile Header Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: avatarColor,
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showAvatarColorPicker,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.color_lens_outlined,
                            size: 16,
                            color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Name',
                      onPressed: () => _showEditNameDialog(displayName),
                    ),
                  ],
                ),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),

                // Role & Public ID Row
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    StatusChip.present(label: role),
                    if (publicId.isNotEmpty)
                      InkWell(
                        onTap: () => _copyToClipboard(publicId, 'Public ID'),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primaryTealLight.withValues(alpha: 0.2)
                                : AppColors.primaryTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ID: $publicId',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),
        Text('App Preferences', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),

        // Preferences Card
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.palette_outlined),
                title: Text('Appearance Theme'),
                subtitle: Text('Switch between Light and Dark mode'),
                trailing: ThemeModeToggle(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('App Language'),
                subtitle: Text(currentLanguage),
                trailing: DropdownButton<String>(
                  value: currentLanguage,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Urdu', child: Text('Urdu (اردو)')),
                  ],
                  onChanged: (newLang) {
                    if (newLang != null) {
                      ref.read(appLanguageProvider.notifier).setLanguage(newLang);
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: const Text('Class Reminders'),
                subtitle: const Text('Receive notifications for upcoming classes'),
                value: notificationSettings['classReminders'] ?? true,
                activeThumbColor: AppColors.primaryTeal,
                onChanged: (_) {
                  ref.read(notificationSettingsProvider.notifier).toggleSetting('classReminders');
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.fact_check_outlined),
                title: const Text('Attendance Alerts'),
                subtitle: const Text('Get notified on attendance updates'),
                value: notificationSettings['attendanceAlerts'] ?? true,
                activeThumbColor: AppColors.primaryTeal,
                onChanged: (_) {
                  ref.read(notificationSettingsProvider.notifier).toggleSetting('attendanceAlerts');
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),
        Text('Security & Support', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_reset_outlined),
                title: const Text('Change Password'),
                subtitle: const Text('Send password reset email to your address'),
                onTap: () => _sendPasswordResetEmail(email),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('Help & Support'),
                subtitle: const Text('Contact support or view guide'),
                onTap: _showHelpSupportModal,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy & Data Safety'),
                subtitle: const Text('Learn about Cloud Firestore security'),
                onTap: _showPrivacyPolicyModal,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),
        Text('About TeachLearn', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),

        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('Application Version'),
                trailing: Text('v1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (publicId.isNotEmpty) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Share Public ID'),
                  subtitle: const Text('Allow students or parents to connect'),
                  onTap: () => _copyToClipboard(publicId, 'Public ID'),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Log Out Button
        AppButton.secondary(
          label: _isLoggingOut ? 'Logging out...' : 'Log Out',
          isLoading: _isLoggingOut,
          icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
          isFullWidth: true,
          onPressed: _isLoggingOut ? null : _handleLogout,
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
