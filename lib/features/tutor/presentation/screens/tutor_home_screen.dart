import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_staggered_item.dart';
import '../../../../core/widgets/theme_mode_toggle.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../attendance/presentation/screens/attendance_screen.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../marketplace/domain/models/tutor_profile.dart';
import '../../../marketplace/domain/models/lesson_request.dart';
import '../../../marketplace/presentation/providers/marketplace_providers.dart';
import '../../../marketplace/presentation/screens/public_profile_screen.dart';
import '../../../marketplace/presentation/screens/tutor_requests_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../students/domain/models/academic_test.dart';
import '../../../students/domain/models/student.dart';
import '../../../students/presentation/providers/academic_test_providers.dart';
import '../../../students/presentation/providers/student_providers.dart';
import '../../../students/presentation/screens/student_detail_screen.dart';
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
  final _pageController = PageController();

  static const _titles = ['Dashboard', 'Students', 'Attendance', 'Profile'];

  void _navigateToTab(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    if (MediaQuery.of(context).disableAnimations) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _addStudent() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const StudentFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TutorDashboardView(onNavigateToTab: _navigateToTab),
      const StudentsScreen(),
      const AttendanceScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: const [ThemeModeToggle()],
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            if (_selectedIndex != index) {
              setState(() => _selectedIndex = index);
            }
          },
          children: tabs,
        ),
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
        onDestinationSelected: _navigateToTab,
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
  const _TutorDashboardView({required this.onNavigateToTab});

  final ValueChanged<int> onNavigateToTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAuthUserProvider);

    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Tutor';
    final studentsState = ref.watch(studentsProvider);
    final attendanceState = ref.watch(allAttendanceStreamProvider);
    final allAttendance = attendanceState.valueOrNull ?? [];
    final tutorRequestsState = ref.watch(tutorRequestsStreamProvider);
    final profileState = ref.watch(currentTutorProfileProvider);

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final todayRecords = allAttendance
        .where((r) => r.date == todayStr)
        .toList();

    final students = studentsState.valueOrNull;
    final activeStudents =
        students?.where((s) => s.status == StudentStatus.active).toList() ??
        const <Student>[];
    final activeStudentIds = activeStudents
        .map((student) => student.id)
        .toSet();
    final todayActiveMarkedCount = todayRecords
        .where((record) => activeStudentIds.contains(record.studentId))
        .map((record) => record.studentId)
        .toSet()
        .length;

    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekRecords = allAttendance.where((r) {
      if (!activeStudentIds.contains(r.studentId)) return false;
      final d = DateTime.tryParse(r.date);
      if (d == null) return false;
      return !d.isBefore(
            DateTime(
              thisWeekStart.year,
              thisWeekStart.month,
              thisWeekStart.day,
            ),
          ) &&
          !d.isAfter(DateTime(now.year, now.month, now.day));
    }).toList();
    final weekPct = calculateAttendancePercentage(weekRecords);

    final dateLabel = '${_monthName(now.month)} ${now.day}, ${now.year}';
    final pendingRequests = tutorRequestsState.valueOrNull
        ?.where((request) => request.status == LessonRequestStatus.pending)
        .length;
    final profile = profileState.valueOrNull;

    final attentionStudents = <_AttentionStudent>[];
    final attentionCutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    for (final student in activeStudents) {
      final records = allAttendance
          .where((record) => record.studentId == student.id)
          .toList();
      final dates = records
          .map((record) => DateTime.tryParse(record.date))
          .whereType<DateTime>()
          .toList();
      final lastMarked = dates.isEmpty
          ? null
          : dates.reduce((a, b) => a.isAfter(b) ? a : b);
      final percentage = records.isEmpty
          ? null
          : calculateAttendancePercentage(records);
      if ((percentage != null && percentage < 75) ||
          lastMarked == null ||
          lastMarked.isBefore(attentionCutoff)) {
        attentionStudents.add(
          _AttentionStudent(
            student: student,
            percentage: percentage,
            lastMarked: lastMarked,
          ),
        );
      }
    }

    final testStates = [
      for (final student in students ?? const <Student>[])
        ref.watch(studentAcademicTestsStreamProvider(student.id)),
    ];
    final recentTests = <({Student student, AcademicTest test})>[];
    for (var index = 0; index < testStates.length; index++) {
      final state = testStates[index];
      final student = students![index];
      for (final test in state.valueOrNull ?? const <AcademicTest>[]) {
        recentTests.add((student: student, test: test));
      }
    }
    recentTests.sort((a, b) => _testDate(b.test).compareTo(_testDate(a.test)));
    final hasTestError = testStates.any((state) => state.hasError);

    Future<void> addTestForStudent() async {
      if (students == null || students.isEmpty) return;
      final selected = await showModalBottomSheet<Student>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.6,
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xs,
                  ),
                  child: Text(
                    'Choose a student',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                ),
                for (final student in students)
                  ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        student.name.isNotEmpty
                            ? student.name[0].toUpperCase()
                            : 'S',
                      ),
                    ),
                    title: Text(student.name),
                    subtitle: Text(student.classLevel),
                    onTap: () => Navigator.pop(sheetContext, student),
                  ),
              ],
            ),
          ),
        ),
      );
      if (selected != null && context.mounted) {
        await StudentDetailScreen.showAddTestModal(context, ref, selected);
      }
    }

    Future<void> toggleProfileVisibility(bool visible) async {
      if (profile == null) {
        if (visible) {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const PublicProfileScreen(),
            ),
          );
        }
        return;
      }
      if (visible && !profile.isCompleteForPublish) {
        showAppSnackBar(
          context,
          'Complete your public profile before making it visible.',
          isError: true,
        );
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const PublicProfileScreen()),
        );
        return;
      }
      try {
        await ref
            .read(marketplaceRepositoryProvider)
            .saveTutorProfile(
              profile.copyWith(isPublished: visible, updatedAt: DateTime.now()),
            );
        ref.invalidate(currentTutorProfileProvider);
        if (context.mounted) {
          showAppSnackBar(
            context,
            visible
                ? 'Public profile is visible.'
                : 'Public profile is hidden.',
          );
        }
      } catch (error) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            formatUserFriendlyError(error),
            isError: true,
          );
        }
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(studentsNotifierProvider.notifier).loadInitial(),
          ref.refresh(allAttendanceStreamProvider.future),
          ref.refresh(tutorRequestsStreamProvider.future),
          ref.refresh(currentTutorProfileProvider.future),
        ]);
      },
      child: AnimatedSwitcher(
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        child: ListView(
          key: ValueKey(
            studentsState.isLoading
                ? 'tutor-dashboard-loading'
                : 'tutor-dashboard-content',
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Hi, $displayName',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(dateLabel, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            _TodayAttendanceCard(
              marked: todayActiveMarkedCount,
              total: activeStudents.length,
              isLoading: !attendanceState.hasValue,
              error: attendanceState.hasError,
              onMarkAttendance: () => onNavigateToTab(2),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (studentsState.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Column(
                  children: [
                    for (var index = 0; index < 3; index++) ...[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppLoader.skeleton(width: 170, height: 16),
                            const SizedBox(height: AppSpacing.md),
                            AppLoader.skeleton(
                              width: double.infinity,
                              height: 12,
                            ),
                          ],
                        ),
                      ),
                      if (index < 2) const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              )
            else if (studentsState.hasError)
              _DashboardMessage(
                icon: Icons.error_outline_rounded,
                message: 'Students could not be loaded.',
              )
            else if (students == null || students.isEmpty)
              _EmptyTutorDashboard(
                onAddStudent: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const StudentFormScreen(),
                  ),
                ),
                onOpenProfile: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PublicProfileScreen(),
                  ),
                ),
                profile: profile,
                profileLoading: profileState.isLoading,
                profileError: profileState.hasError,
                onToggleProfile: toggleProfileVisibility,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CompactStatCard(
                          title: 'Total students',
                          value: '${students.length}',
                          icon: Icons.people_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _CompactStatCard(
                          title: 'This week',
                          value:
                              weekRecords.isEmpty || !attendanceState.hasValue
                              ? '—'
                              : '${weekPct.round()}%',
                          icon: Icons.calendar_month_outlined,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _CompactStatCard(
                          title: 'Pending requests',
                          value: pendingRequests == null
                              ? '—'
                              : '$pendingRequests',
                          icon: Icons.mark_email_unread_outlined,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const TutorRequestsScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (tutorRequestsState.hasError)
                    const _DashboardMessage(
                      icon: Icons.error_outline_rounded,
                      message: 'Pending requests could not be loaded.',
                    ),
                  _DashboardSectionTitle(
                    title: 'Needs attention',
                    trailing: attentionStudents.isNotEmpty
                        ? '${attentionStudents.length}'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (attendanceState.hasError)
                    const _DashboardMessage(
                      icon: Icons.error_outline_rounded,
                      message: 'Attendance could not be loaded.',
                    )
                  else if (!attendanceState.hasValue &&
                      attendanceState.isLoading)
                    const _DashboardMessage(
                      icon: Icons.hourglass_empty_rounded,
                      message: 'Loading attendance...',
                    )
                  else if (attentionStudents.isEmpty)
                    const _DashboardMessage(
                      icon: Icons.check_circle_outline_rounded,
                      message: 'All students are up to date.',
                    )
                  else
                    ...List.generate(attentionStudents.length, (index) {
                      final entry = attentionStudents[index];
                      final student = entry.student;
                      final details = <String>[
                        if (entry.percentage != null)
                          'Attendance ${entry.percentage!.round()}%',
                        if (entry.lastMarked == null)
                          'No attendance marked'
                        else if (entry.lastMarked!.isBefore(attentionCutoff))
                          'Last marked ${_shortDate(entry.lastMarked!)}',
                      ].join(' · ');
                      return AppStaggeredItem(
                        key: ValueKey('attention-${student.id}'),
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppCard(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    StudentDetailScreen(studentId: student.id),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                child: Icon(
                                  Icons.priority_high_rounded,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                              ),
                              title: Text(student.name),
                              subtitle: Text(details),
                              trailing: const Icon(Icons.chevron_right_rounded),
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: AppSpacing.lg),
                  const _DashboardSectionTitle(title: 'Recent test results'),
                  const SizedBox(height: AppSpacing.xs),
                  if (hasTestError)
                    const _DashboardMessage(
                      icon: Icons.error_outline_rounded,
                      message: 'Some test results could not be loaded.',
                    )
                  else if (testStates.any((state) => state.isLoading))
                    const _DashboardMessage(
                      icon: Icons.hourglass_empty_rounded,
                      message: 'Loading test results...',
                    )
                  else if (recentTests.isEmpty)
                    const _DashboardMessage(
                      icon: Icons.assessment_outlined,
                      message: 'No test results recorded yet.',
                    )
                  else
                    ...List.generate(recentTests.take(3).length, (index) {
                      final item = recentTests[index];
                      return AppStaggeredItem(
                        key: ValueKey('test-${item.test.id}'),
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Text(
                                  '${item.test.percentage.round()}%',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(item.test.title),
                              subtitle: Text(
                                '${item.student.name} · ${_shortDate(_testDate(item.test))}',
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => StudentDetailScreen(
                                    studentId: item.student.id,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: AppSpacing.lg),
                  const _DashboardSectionTitle(title: 'Quick actions'),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const StudentFormScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Add student'),
                      ),
                      OutlinedButton.icon(
                        onPressed: addTestForStudent,
                        icon: const Icon(Icons.add_chart_rounded),
                        label: const Text('Add test'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => onNavigateToTab(3),
                        icon: const Icon(Icons.person_outline_rounded),
                        label: const Text('Profile'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PublicProfileStatus(
                    profile: profile,
                    isLoading: profileState.isLoading,
                    hasError: profileState.hasError,
                    onToggle: toggleProfileVisibility,
                    onOpenProfile: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const PublicProfileScreen(),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static DateTime _testDate(AcademicTest test) =>
      DateTime.tryParse(test.date) ?? test.createdAt;

  static String _shortDate(DateTime date) =>
      '${_monthName(date.month)} ${date.day}';

  static String _monthName(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}

class _CompactStatCard extends StatelessWidget {
  const _CompactStatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (double.tryParse(value.replaceAll('%', '')) case final number?)
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: number.round()),
                  duration: MediaQuery.of(context).disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 350),
                  builder: (context, animatedValue, _) => Text(
                    '$animatedValue${value.endsWith('%') ? '%' : ''}',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                )
              else
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionStudent {
  const _AttentionStudent({
    required this.student,
    required this.percentage,
    required this.lastMarked,
  });

  final Student student;
  final double? percentage;
  final DateTime? lastMarked;
}

class _TodayAttendanceCard extends StatelessWidget {
  const _TodayAttendanceCard({
    required this.marked,
    required this.total,
    required this.isLoading,
    required this.error,
    required this.onMarkAttendance,
  });

  final int marked;
  final int total;
  final bool isLoading;
  final bool error;
  final VoidCallback onMarkAttendance;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              error
                  ? 'Attendance could not be loaded.'
                  : isLoading
                  ? 'Loading attendance...'
                  : '$marked of $total marked',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: isLoading || error || total == 0 ? 0 : marked / total,
              ),
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 350),
              builder: (context, progress, _) => LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.primary(
              label: 'Mark Attendance',
              icon: Icon(Icons.fact_check_outlined, color: colors.onPrimary),
              isFullWidth: true,
              onPressed: onMarkAttendance,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSectionTitle extends StatelessWidget {
  const _DashboardSectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (trailing != null)
          Text(trailing!, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTutorDashboard extends StatelessWidget {
  const _EmptyTutorDashboard({
    required this.onAddStudent,
    required this.onOpenProfile,
    required this.profile,
    required this.profileLoading,
    required this.profileError,
    required this.onToggleProfile,
  });

  final VoidCallback onAddStudent;
  final VoidCallback onOpenProfile;
  final TutorProfile? profile;
  final bool profileLoading;
  final bool profileError;
  final ValueChanged<bool> onToggleProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Add your first student',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your attendance and learning progress will appear here.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  label: 'Add your first student',
                  onPressed: onAddStudent,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _PublicProfileStatus(
          profile: profile,
          isLoading: profileLoading,
          hasError: profileError,
          onToggle: onToggleProfile,
          onOpenProfile: onOpenProfile,
        ),
      ],
    );
  }
}

class _PublicProfileStatus extends StatelessWidget {
  const _PublicProfileStatus({
    required this.profile,
    required this.isLoading,
    required this.hasError,
    required this.onToggle,
    required this.onOpenProfile,
  });

  final TutorProfile? profile;
  final bool isLoading;
  final bool hasError;
  final ValueChanged<bool> onToggle;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: LinearProgressIndicator(),
        ),
      );
    }
    if (hasError) {
      return Card(
        child: ListTile(
          leading: Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          title: const Text('Public profile status unavailable'),
          subtitle: const Text('Open your profile to check or update it.'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onOpenProfile,
        ),
      );
    }
    if (profile == null) {
      return Card(
        child: ListTile(
          leading: Icon(
            Icons.public_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Public profile'),
          subtitle: const Text('Set up your profile to become visible.'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onOpenProfile,
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            value: profile!.isPublished,
            onChanged: (value) => onToggle(value),
            title: const Text('Public profile'),
            subtitle: Text(profile!.isPublished ? 'Visible' : 'Hidden'),
            secondary: Icon(
              Icons.public_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (!profile!.isCompleteForPublish)
            ListTile(
              dense: true,
              leading: Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              title: Text(
                'Profile ${profile!.completenessPercentage}% complete',
              ),
              subtitle: const Text(
                'Complete the required details to publish your profile.',
              ),
              onTap: onOpenProfile,
            ),
        ],
      ),
    );
  }
}
