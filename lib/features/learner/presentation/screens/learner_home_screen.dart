import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/theme_mode_toggle.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../auth/presentation/widgets/email_verification_banner.dart';
import '../../../schedule/presentation/providers/class_session_providers.dart';

class LearnerHomeScreen extends ConsumerStatefulWidget {
  const LearnerHomeScreen({super.key, this.onThemeModeChanged});

  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  ConsumerState<LearnerHomeScreen> createState() => _LearnerHomeScreenState();
}

class _LearnerHomeScreenState extends ConsumerState<LearnerHomeScreen> {
  int _selectedIndex = 0;

  Future<void> _logout(BuildContext context) async {
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
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
    User? user;
    try {
      user = ref.watch(authRepositoryProvider).currentUser;
    } catch (_) {}

    final uid = user?.uid ?? '';
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';

    final profileState = uid.isNotEmpty ? ref.watch(userProfileProvider(uid)) : null;
    final profileData = profileState?.asData?.value;
    final role = profileData?['role'] as String? ?? 'student';
    final publicId = profileData?['publicId'] as String? ?? '';

    final isParent = role == 'parent';
    final spaceTitle = isParent ? 'TeachLearn Parent Space' : 'TeachLearn Student Space';
    final subtitleText = isParent
        ? 'Parent Account • Tracking Child\'s Tuition'
        : 'Student Account • Your Classes & Schedule';
    final nextClassHeader = isParent ? 'Child\'s Next Scheduled Class' : 'Your Next Scheduled Class';
    final scheduleHeader = isParent ? 'Child\'s Class Schedule' : 'Your Class Schedule';

    final sessionsState = ref.watch(classSessionsProvider);

    final tabs = [
      // Home Tab
      ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      isParent ? Icons.family_restroom_rounded : Icons.person_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $displayName',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (publicId.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ID: $publicId',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Next Class Banner
          Card(
            color: AppColors.primaryTeal,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        nextClassHeader,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const StatusChip.present(label: 'Upcoming'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  sessionsState.when(
                    data: (sessions) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sessions.isNotEmpty ? sessions.first.subject : 'Mathematics',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sessions.isNotEmpty
                              ? 'Today at ${sessions.first.startsAt.hour}:${sessions.first.startsAt.minute.toString().padLeft(2, '0')}'
                              : 'Today at 5:00 PM',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                    loading: () => const AppLoader.inline(color: Colors.white),
                    error: (_, _) => const Text('Mathematics', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(scheduleHeader, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),

          sessionsState.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.calendar_today_rounded,
                  title: 'No classes scheduled',
                  description: 'Upcoming classes will appear here.',
                );
              }
              return Column(
                children: sessions.take(4).map((session) => Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.book_outlined, size: 20),
                    ),
                    title: Text(session.subject),
                    subtitle: Text(
                      '${session.startsAt.hour}:${session.startsAt.minute.toString().padLeft(2, '0')} • ${session.durationMinutes} mins',
                    ),
                  ),
                )).toList(),
              );
            },
            loading: () => const AppLoader.inline(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),

      // Schedule Tab
      ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(scheduleHeader, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          sessionsState.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.calendar_today_rounded,
                  title: 'No schedule found',
                  description: 'Class sessions will appear here.',
                );
              }
              return Column(
                children: sessions.map((session) => Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month_rounded),
                    title: Text(session.subject),
                    subtitle: Text('Duration: ${session.durationMinutes} minutes'),
                    trailing: const StatusChip.present(label: 'Scheduled'),
                  ),
                )).toList(),
              );
            },
            loading: () => const AppLoader.inline(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),

      // Profile Tab
      ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(email, style: Theme.of(context).textTheme.bodyMedium),
                  if (publicId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Public ID: $publicId', style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 4),
                  Text('Account Role: ${role.toUpperCase()}', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.palette_outlined),
                  title: Text('Theme Mode'),
                  trailing: ThemeModeToggle(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text('Log out', style: TextStyle(color: Colors.red)),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(spaceTitle),
        actions: const [
          ThemeModeToggle(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const EmailVerificationBanner(),
            Expanded(child: tabs[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
