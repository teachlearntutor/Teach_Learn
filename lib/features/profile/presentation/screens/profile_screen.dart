import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/contact_utils.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/utils/name_initials.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../learner/domain/models/learner_preferences.dart';
import '../../../learner/presentation/widgets/learner_preferences_modal.dart';
import '../../../marketplace/presentation/screens/public_profile_screen.dart';
import '../../../marketplace/presentation/screens/tutor_requests_screen.dart';
import '../../domain/profile_logic.dart';
import '../providers/profile_providers.dart';

const String kSupportEmail = 'teachlearntutor@gmail.com';

/// Redesigned, production-quality Profile Screen for Teach Learn.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoggingOut = false;
  bool _isDeletingAccount = false;
  bool _isCleaningData = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('Log out of Teach Learn?'),
          content: const Text(
            'Are you sure you want to sign out of your account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      clearActiveAppToast();
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signOut();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const AuthScreen(initialMode: AuthMode.logIn),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, formatUserFriendlyError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _handleDeleteAccount(bool isPasswordUser) async {
    String? password;

    if (isPasswordUser) {
      var enteredPassword = '';
      final confirmPassword = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          final colors = Theme.of(dialogContext).colorScheme;
          return AlertDialog(
            title: const Text('Re-authenticate to Delete Account'),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter your password to confirm account deletion.'),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  onChanged: (value) => enteredPassword = value,
                ),
              ],
            ),
            actions: [
              _deleteConfirmationActions(
                onCancel: () => Navigator.pop(dialogContext),
                onDelete: () => Navigator.pop(dialogContext, enteredPassword),
                foregroundColor: colors.onError,
                deleteColor: colors.error,
              ),
            ],
          );
        },
      );

      if (confirmPassword == null || confirmPassword.isEmpty || !mounted) {
        return;
      }
      password = confirmPassword;
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final colors = Theme.of(dialogContext).colorScheme;
          return AlertDialog(
            title: const Text('Delete Account Permanently?'),
            content: const Text(
              'Your profile, students, attendance and tests are deleted. Past lesson requests may remain for the other person; your reserved ID stays reserved.',
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            actions: [
              _deleteConfirmationActions(
                onCancel: () => Navigator.of(dialogContext).pop(false),
                onDelete: () => Navigator.of(dialogContext).pop(true),
                foregroundColor: colors.onError,
                deleteColor: colors.error,
              ),
            ],
          );
        },
      );

      if (confirm != true || !mounted) return;
    }

    setState(() => _isDeletingAccount = true);
    final navigator = Navigator.of(context, rootNavigator: true);
    unawaited(
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: Dialog.fullscreen(
            backgroundColor: Theme.of(dialogContext).colorScheme.surface,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Deleting your account...',
                        style: Theme.of(dialogContext).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Removing your profile and saved records.\nRemoving your sign-in account.',
                        style: Theme.of(dialogContext).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Object? deletionError;
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.deleteUserAccount(password: password);
    } catch (e) {
      deletionError = e;
    }

    if (!mounted) return;
    setState(() => _isDeletingAccount = false);
    if (deletionError != null) {
      navigator.pop();
      showAppSnackBar(
        context,
        formatUserFriendlyError(deletionError),
        isError: true,
      );
      return;
    }

    navigator.pop();
    unawaited(
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: Dialog.fullscreen(
            backgroundColor: Theme.of(dialogContext).colorScheme.surface,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 56,
                      color: Theme.of(dialogContext).colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Account deleted',
                      style: Theme.of(dialogContext).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Taking you to Login...',
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const AuthScreen(initialMode: AuthMode.logIn),
      ),
      (route) => false,
    );
  }

  Widget _deleteConfirmationActions({
    required VoidCallback onCancel,
    required VoidCallback onDelete,
    required Color foregroundColor,
    required Color deleteColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: deleteColor,
              foregroundColor: foregroundColor,
            ),
            onPressed: onDelete,
            child: const Text('Delete'),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    showAppSnackBar(
      context,
      'Copied $label "$text" to clipboard!',
      isSuccess: true,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _showEditNameDialog(String currentName) async {
    final pageContext = context;
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
                  'Edit Profile Name',
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
                          final navigator = Navigator.of(sheetContext);
                          setSheetState(() => isSaving = true);
                          try {
                            final user = ref.read(currentAuthUserProvider);
                            if (user != null) {
                              await user.updateDisplayName(
                                controller.text.trim(),
                              );
                            }
                            if (!pageContext.mounted) return;
                            setState(() {});
                            navigator.pop();
                            showAppSnackBar(
                              pageContext,
                              'Name updated successfully!',
                              isSuccess: true,
                            );
                          } catch (e) {
                            if (!pageContext.mounted) return;
                            setSheetState(() => isSaving = false);
                            showAppSnackBar(
                              pageContext,
                              formatUserFriendlyError(e),
                              isError: true,
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
      showAppSnackBar(
        context,
        'Password reset link sent to $email. Check your inbox and spam folder.',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, formatUserFriendlyError(e), isError: true);
    }
  }

  void _showTextModal(String title, String content) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.sheetBorderRadius,
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(height: 1.5),
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

  Future<bool> _confirmCleanup(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _cleanAttendanceDuplicates() async {
    if (_isCleaningData) return;
    final confirmed = await _confirmCleanup(
      'Clean up old duplicates?',
      'For each student and date, keep the latest attendance mark and remove older duplicate records.',
    );
    if (!confirmed || !mounted) return;

    final uid = ref.read(currentAuthUserProvider)?.uid ?? '';
    setState(() => _isCleaningData = true);
    try {
      final removed = await ref
          .read(profileCleanupRepositoryProvider)
          .removeAttendanceDuplicates(uid);
      if (!mounted) return;
      showAppSnackBar(context, '$removed duplicates removed');
    } catch (error) {
      if (!mounted) return;
      final details = formatFirestoreErrorDetails(
        error,
        'users/$uid/attendance',
      );
      showAppSnackBar(
        context,
        formatUserFriendlyError(error),
        isError: true,
        diagnostic: details,
      );
    } finally {
      if (mounted) setState(() => _isCleaningData = false);
    }
  }

  Future<void> _removeOldScheduleData() async {
    if (_isCleaningData) return;
    final confirmed = await _confirmCleanup(
      'Remove old schedule data?',
      'Delete legacy classes and sessions records. This does not affect current attendance, students, or tests.',
    );
    if (!confirmed || !mounted) return;

    final uid = ref.read(currentAuthUserProvider)?.uid ?? '';
    setState(() => _isCleaningData = true);
    var removed = 0;
    var collection = 'classes';
    try {
      final repository = ref.read(profileCleanupRepositoryProvider);
      removed += await repository.removeLegacyScheduleCollection(
        uid,
        collection,
      );
      collection = 'sessions';
      removed += await repository.removeLegacyScheduleCollection(
        uid,
        collection,
      );
      if (!mounted) return;
      showAppSnackBar(context, '$removed old schedule records removed');
    } catch (error) {
      if (!mounted) return;
      final details = formatFirestoreErrorDetails(
        error,
        'users/$uid/$collection',
      );
      showAppSnackBar(
        context,
        formatUserFriendlyError(error),
        isError: true,
        diagnostic: details,
      );
    } finally {
      if (mounted) setState(() => _isCleaningData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = ref.watch(currentAuthUserProvider);

    final uid = user?.uid ?? '';
    final displayName = user?.displayName ?? 'Teach Learn User';
    final email = user?.email ?? 'No email associated';

    final providerData = user?.providerData ?? [];
    final isGoogleUser = providerData.any((p) => p.providerId == 'google.com');
    final isPasswordUser = providerData.any((p) => p.providerId == 'password');

    final showPasswordOption = shouldShowChangePassword(
      isGoogleUser: isGoogleUser,
      isPasswordUser: isPasswordUser,
    );

    final profileState = uid.isNotEmpty
        ? ref.watch(userProfileProvider(uid))
        : null;
    final profileData = profileState?.asData?.value;
    final role = (profileData?['role'] as String? ?? 'tutor').toUpperCase();
    final publicId = profileData?['publicId'] as String? ?? '';
    final isTutor = role == 'TUTOR';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Centered Header Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    nameInitials(displayName),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Name Aligned Centered
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),

                // Email Directly Below Name
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),

                // Role Badge & Public ID Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StatusChip.present(label: role),
                    if (publicId.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      InkWell(
                        onTap: () => _copyToClipboard(publicId, 'Public ID'),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
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
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        // Tutor Finder Marketplace Tools (Only for Tutors)
        if (isTutor) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tutor Finder Marketplace',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.storefront_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Public Tutor Profile'),
                  subtitle: const Text(
                    'Set bio, subjects, city, and visibility',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const PublicProfileScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.mail_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Lesson Requests'),
                  subtitle: const Text(
                    'View and accept requests from students/parents',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const TutorRequestsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.md),
        Text('Account Settings', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),

        // Account Group
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.person_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Edit Profile'),
                subtitle: const Text('Change your display name'),
                onTap: () => _showEditNameDialog(displayName),
              ),
              if (!isTutor) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.tune_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Tuition preferences'),
                  subtitle: const Text('Change class, subjects, or city'),
                  onTap: () {
                    showModalBottomSheet<LearnerPreferences>(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.sheetBorderRadius,
                      ),
                      builder: (_) => LearnerPreferencesModal(
                        initialPreferences: LearnerPreferences.fromMap(
                          profileData,
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (showPasswordOption) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.lock_reset_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Change Password'),
                  subtitle: const Text(
                    'Send password reset link to your email',
                  ),
                  onTap: () => _sendPasswordResetEmail(email),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),
        Text(
          'Support & Feedback',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),

        // Support Group (mailto integration)
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.support_agent_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Contact Support'),
                subtitle: const Text(kSupportEmail),
                onTap: () => openEmailApp(
                  email: kSupportEmail,
                  subject: 'Support Inquiry - Teach Learn App',
                  context: context,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.bug_report_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Report a Problem'),
                subtitle: const Text('Report issues directly to support team'),
                onTap: () => openEmailApp(
                  email: kSupportEmail,
                  subject: 'Report Problem - Teach Learn App',
                  context: context,
                ),
              ),
            ],
          ),
        ),

        if (isTutor) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Advanced', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.cleaning_services_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Clean up old duplicates'),
                  subtitle: const Text(
                    'Keep only the latest attendance mark per student and date',
                  ),
                  onTap: _isCleaningData ? null : _cleanAttendanceDuplicates,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.calendar_month_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Remove old schedule data'),
                  subtitle: const Text('Delete legacy classes and sessions'),
                  onTap: _isCleaningData ? null : _removeOldScheduleData,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.md),
        Text('Legal & Privacy', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Terms & Conditions'),
                subtitle: const Text('Read terms of service'),
                onTap: () => _showTextModal(
                  'Terms & Conditions',
                  'Information and use\n'
                      'We collect your name, email and role; students’ names, attendance and tests entered by tutors; and optional approximate location and tutor phone number. We use this data to provide tuition, profile and lesson-request features.\n\n'
                      'Storage and visibility\n'
                      'Account access uses Firebase Authentication and app records are stored in Cloud Firestore. We do not sell personal data. Published tutor profiles are visible to signed-in users. Profile location is approximate only. If a tutor provided private contact details, the learner can access them after request acceptance.\n\n'
                      'Your responsibilities\n'
                      'Keep information you enter accurate. Tutors must have parents’ consent before entering student data.\n\n'
                      'Account deletion\n'
                      'Your profile, students, attendance and tests are deleted. Past lesson requests may remain for the other person; your reserved ID stays reserved.\n\n'
                      'Contact: teachlearntutor@gmail.com\n'
                      'Last updated: 16 November 2026.',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.privacy_tip_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Privacy Policy'),
                subtitle: const Text('Learn about data protection'),
                onTap: () => _showTextModal(
                  'Privacy Policy',
                  'What we collect\n'
                      'Your name, email and role; students’ names, attendance and tests entered by tutors; and optional approximate location and tutor phone number.\n\n'
                      'How we use and store it\n'
                      'We use this data to provide the app’s tuition, tutor-profile and request features. Account access uses Firebase Authentication; app records are stored in Cloud Firestore. We do not sell personal data.\n\n'
                      'Who can see it\n'
                      'Published tutor profiles are visible to signed-in users. Profile location is approximate only. If a tutor provided private contact details, the learner can access them after request acceptance.\n\n'
                      'Your responsibilities and choices\n'
                      'Tutors must have parents’ consent before entering student data. You may optionally provide approximate location or phone.\n\n'
                      'Account deletion\n'
                      'Your profile, students, attendance and tests are deleted. Past lesson requests may remain for the other person; your reserved ID stays reserved.\n\n'
                      'Contact: teachlearntutor@gmail.com\n'
                      'Last updated: 16 November 2026.',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Danger Zone Card
        Card(
          child: ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete Account',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text('Permanently remove your account and data'),
            onTap: _isDeletingAccount
                ? null
                : () => _handleDeleteAccount(isPasswordUser),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Log Out Button
        AppButton.secondary(
          label: _isLoggingOut ? 'Logging out...' : 'Log Out',
          isLoading: _isLoggingOut,
          icon: Icon(
            Icons.logout_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          isFullWidth: true,
          onPressed: _isLoggingOut ? null : _handleLogout,
        ),

        const SizedBox(height: AppSpacing.md),

        // App Version
        Center(
          child: Text(
            'Teach Learn v1.0.0 (Build 1)',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
