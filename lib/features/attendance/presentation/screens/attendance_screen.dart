import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../students/domain/models/student.dart';
import '../../../students/presentation/providers/student_providers.dart';
import '../../../students/presentation/screens/student_form_screen.dart';
import '../../domain/models/attendance_record.dart';
import '../providers/attendance_providers.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  late DateTime _selectedDate;
  final Map<String, Map<String, AttendanceStatus>> _statusesByDate = {};
  final Map<String, Map<String, AttendanceRecord>> _locallyMarkedByDate = {};
  String? _savingStudentId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  String get _selectedDateString =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate == DateTime(now.year, now.month, now.day);
  }

  void _changeDate(int days) {
    final nextDate = _selectedDate.add(Duration(days: days));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (nextDate.isAfter(today)) return;
    setState(() => _selectedDate = nextDate);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked != null) {
      setState(
        () => _selectedDate = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _saveStudentAttendance(
    Student student,
    AttendanceStatus status,
  ) async {
    if (_savingStudentId != null) return;
    final uid = ref.read(currentAuthUserProvider)?.uid ?? '';
    if (uid.isEmpty) {
      showAppSnackBar(
        context,
        'Sign in again before saving attendance.',
        isError: true,
      );
      return;
    }

    final date = _selectedDateString;
    setState(() => _savingStudentId = student.id);
    try {
      final now = DateTime.now();
      final record = AttendanceRecord(
        id: '${student.id}_$date',
        studentId: student.id,
        studentName: student.name,
        date: date,
        status: status,
        markedAt: now,
      );

      await ref.read(attendanceRepositoryProvider).saveAttendanceBatch(
        uid,
        date,
        [record],
      );
      if (!mounted) return;

      await HapticFeedback.selectionClick();
      if (!mounted) return;
      _locallyMarkedByDate.putIfAbsent(date, () => {})[student.id] = record;
      ref.invalidate(allAttendanceStreamProvider);
      ref.invalidate(attendanceDateStreamProvider(date));
      showAppSnackBar(
        context,
        'Attendance saved for ${student.name}.',
        isSuccess: true,
      );
    } catch (error) {
      if (!mounted) return;
      final details = formatFirestoreErrorDetails(
        error,
        'users/$uid/attendance/${student.id}_$date',
      );
      showAppSnackBar(
        context,
        formatUserFriendlyError(error),
        isError: true,
        diagnostic: details,
      );
    } finally {
      if (mounted) setState(() => _savingStudentId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(allActiveStudentsStreamProvider);
    final dateString = _selectedDateString;
    final attendanceState = ref.watch(attendanceDateStreamProvider(dateString));

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.refresh(allActiveStudentsStreamProvider.future),
          ref.refresh(attendanceDateStreamProvider(dateString).future),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Attendance',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Previous day',
                  onPressed: _savingStudentId != null
                      ? null
                      : () => _changeDate(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Center(
                    child: TextButton.icon(
                      onPressed: _savingStudentId != null ? null : _pickDate,
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(dateString),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next day',
                  onPressed: _isToday || _savingStudentId != null
                      ? null
                      : () => _changeDate(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          studentsState.when(
            loading: () => const AppLoader.inline(),
            error: (error, _) => EmptyStateWidget(
              icon: Icons.cloud_off_outlined,
              title: 'Students Unavailable',
              description: formatUserFriendlyError(error),
              diagnostic: formatFirestoreErrorDetails(
                error,
                'users/${ref.watch(currentAuthUserProvider)?.uid ?? ''}/students',
              ),
              actionLabel: 'Retry',
              onActionPressed: () =>
                  ref.invalidate(allActiveStudentsStreamProvider),
            ),
            data: (students) {
              if (students.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.person_add_rounded,
                  title: 'Add students first',
                  description: 'Add active students to take attendance.',
                  actionLabel: 'Add student',
                  onActionPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const StudentFormScreen(),
                      ),
                    );
                  },
                );
              }

              return attendanceState.when(
                loading: () => const AppLoader.inline(),
                error: (error, _) => EmptyStateWidget(
                  icon: Icons.cloud_off_outlined,
                  title: 'Attendance Unavailable',
                  description: formatUserFriendlyError(error),
                  diagnostic: formatFirestoreErrorDetails(
                    error,
                    'users/${ref.watch(currentAuthUserProvider)?.uid ?? ''}/attendance',
                  ),
                  actionLabel: 'Retry',
                  onActionPressed: () =>
                      ref.invalidate(attendanceDateStreamProvider(dateString)),
                ),
                data: (records) {
                  final existingByStudent = {
                    for (final record in uniqueAttendanceRecords(records))
                      record.studentId: record,
                  };
                  existingByStudent.addAll(
                    _locallyMarkedByDate[dateString] ?? {},
                  );
                  final statuses = _statusesByDate.putIfAbsent(
                    dateString,
                    () => {},
                  );
                  for (final student in students) {
                    statuses.putIfAbsent(
                      student.id,
                      () =>
                          existingByStudent[student.id]?.status ??
                          AttendanceStatus.present,
                    );
                  }
                  final markedStudents = students
                      .where(
                        (student) => existingByStudent.containsKey(student.id),
                      )
                      .toList();
                  final unmarkedStudents = students
                      .where(
                        (student) => !existingByStudent.containsKey(student.id),
                      )
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'To mark (${unmarkedStudents.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (unmarkedStudents.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'All done for $dateString ✓',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ...unmarkedStudents.map(
                          (student) => _studentAttendanceCard(
                            student: student,
                            status: statuses[student.id]!,
                            isMarked: false,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      ExpansionTile(
                        key: ValueKey('marked-$dateString'),
                        expansionAnimationStyle: AnimationStyle(
                          duration: MediaQuery.of(context).disableAnimations
                              ? Duration.zero
                              : const Duration(milliseconds: 200),
                        ),
                        tilePadding: EdgeInsets.zero,
                        title: Text('Marked (${markedStudents.length})'),
                        children: [
                          ...markedStudents.map(
                            (student) => _studentAttendanceCard(
                              student: student,
                              status: statuses[student.id]!,
                              isMarked: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _studentAttendanceCard({
    required Student student,
    required AttendanceStatus status,
    required bool isMarked,
  }) {
    final isSaving = _savingStudentId == student.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student.name, style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${student.classLevel} · ${student.subjects.join(", ")}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final option in AttendanceStatus.values)
                  ChoiceChip(
                    label: Text(
                      option.name[0].toUpperCase() + option.name.substring(1),
                    ),
                    selected: status == option,
                    onSelected: _savingStudentId != null
                        ? null
                        : (_) => setState(() {
                            _statusesByDate[_selectedDateString]![student.id] =
                                option;
                          }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _savingStudentId != null
                    ? null
                    : () => _saveStudentAttendance(student, status),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isMarked ? 'Save changes' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
