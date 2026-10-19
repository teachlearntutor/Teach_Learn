import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/theme_mode_toggle.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../schedule/presentation/providers/class_session_providers.dart';
import '../../../students/presentation/providers/student_providers.dart';
import '../../../students/presentation/screens/student_form_screen.dart';
import '../../../students/presentation/screens/students_screen.dart';

class TutorHomeScreen extends ConsumerStatefulWidget {
  const TutorHomeScreen({super.key, this.onThemeModeChanged});

  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  ConsumerState<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends ConsumerState<TutorHomeScreen> {
  int _selectedIndex = 0;

  static const _titles = [
    'Dashboard',
    'Students',
    'Schedule',
    'Attendance',
    'Profile',
  ];

  void _addStudent() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const StudentFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TutorDashboardView(onNavigateToStudents: () {
        setState(() => _selectedIndex = 1);
      }),
      const StudentsScreen(),
      const _TutorScheduleTab(),
      const _TutorAttendanceTab(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          if (_selectedIndex != 4)
            const ThemeModeToggle(),
        ],
      ),
      body: SafeArea(
        child: tabs[_selectedIndex],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: _addStudent,
              tooltip: 'Add student',
              child: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Attendance',
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

class _TutorDashboardView extends ConsumerWidget {
  const _TutorDashboardView({required this.onNavigateToStudents});

  final VoidCallback onNavigateToStudents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    dynamic user;
    try {
      user = ref.watch(authRepositoryProvider).currentUser;
    } catch (_) {}

    final uid = user?.uid ?? '';
    final displayName = user?.displayName ?? 'Tutor';
    final profileState = uid.isNotEmpty ? ref.watch(userProfileProvider(uid)) : null;
    final publicId = profileState?.asData?.value?['publicId'] as String? ?? '';

    final studentsState = ref.watch(studentsProvider);
    final sessionsState = ref.watch(classSessionsProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Welcome Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $displayName',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tutor Account • Teaching Overview',
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

        // Stat Cards
        studentsState.when(
          data: (students) {
            final activeCount = students.where((s) => s.status.name == 'active').length;
            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Students',
                    value: '${students.length}',
                    subtitle: '$activeCount Active',
                    icon: Icons.people_outline_rounded,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: sessionsState.when(
                    data: (sessions) => _StatCard(
                      title: 'Classes Today',
                      value: '${sessions.length}',
                      subtitle: 'Scheduled',
                      icon: Icons.calendar_today_rounded,
                      color: AppColors.accentTeal,
                    ),
                    loading: () => const _StatCard(
                      title: 'Classes Today',
                      value: '...',
                      subtitle: 'Loading',
                      icon: Icons.calendar_today_rounded,
                      color: AppColors.accentTeal,
                    ),
                    error: (_, _) => const _StatCard(
                      title: 'Classes Today',
                      value: '0',
                      subtitle: 'Scheduled',
                      icon: Icons.calendar_today_rounded,
                      color: AppColors.accentTeal,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: AppLoader.inline()),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Quick Actions & Today's Classes Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Classes",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: onNavigateToStudents,
              child: const Text('Manage Students'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        sessionsState.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.event_available_rounded,
                title: 'No classes today',
                description: 'Enjoy your free day or schedule a new class.',
              );
            }
            return Column(
              children: sessions.take(3).map((session) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.book_outlined, size: 20),
                    ),
                    title: Text(session.subject),
                    subtitle: Text(
                      '${session.startsAt.hour}:${session.startsAt.minute.toString().padLeft(2, '0')} • ${session.durationMinutes} mins',
                    ),
                    trailing: const StatusChip.present(label: 'Upcoming'),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const AppLoader.inline(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                Icon(icon, size: 20, color: color),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _TutorScheduleTab extends ConsumerWidget {
  const _TutorScheduleTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsState = ref.watch(classSessionsProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Weekly Class Schedule', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        sessionsState.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.calendar_today_rounded,
                title: 'No classes scheduled',
                description: 'Your class sessions will appear here.',
              );
            }
            return Column(
              children: sessions.map((session) => Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.access_time_rounded),
                  ),
                  title: Text(session.subject),
                  subtitle: Text(
                    'Time: ${session.startsAt.hour}:${session.startsAt.minute.toString().padLeft(2, '0')} (${session.durationMinutes} mins)',
                  ),
                  trailing: const StatusChip.present(label: 'Scheduled'),
                ),
              )).toList(),
            );
          },
          loading: () => const AppLoader.inline(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _TutorAttendanceTab extends ConsumerWidget {
  const _TutorAttendanceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceState = ref.watch(attendanceProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Class Attendance History', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        attendanceState.when(
          data: (records) {
            if (records.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.fact_check_outlined,
                title: 'No attendance records',
                description: 'Marked attendance history will appear here.',
              );
            }
            return Column(
              children: records.take(10).map((record) {
                final isPresent = record.status.name == 'present';
                final isAbsent = record.status.name == 'absent';
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: Icon(
                      isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: isPresent ? AppColors.success : (isAbsent ? AppColors.danger : AppColors.warning),
                    ),
                    title: Text('Student ID: ${record.studentId}'),
                    subtitle: Text('Date: ${record.sessionDate.day}/${record.sessionDate.month}/${record.sessionDate.year}'),
                    trailing: isPresent
                        ? const StatusChip.present()
                        : (isAbsent ? const StatusChip.absent() : const StatusChip.late()),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const AppLoader.inline(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
