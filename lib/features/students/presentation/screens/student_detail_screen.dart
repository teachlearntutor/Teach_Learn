import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../attendance/domain/models/attendance_record.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../domain/models/student.dart';
import '../providers/student_providers.dart';
import 'student_form_screen.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsProvider);
    final student = students.valueOrNull
        ?.where((item) => item.id == studentId)
        .firstOrNull;

    if (student == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student')),
        body: Center(
          child: students.isLoading
              ? const AppLoader.inline(size: 32)
              : const EmptyStateWidget(
                  title: 'Student not found',
                  description: 'This student may have been removed.',
                ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student details'),
        actions: [
          IconButton(
            tooltip: 'Edit student',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StudentFormScreen(student: student),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(_initials(student.name)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${student.classLevel} · ${student.schoolName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    StatusChip(
                      label: _statusLabel(student.status),
                      type: _statusType(student.status),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  student.subjects.join(' · '),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Parent contact',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(
                  student.parentContact,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Attendance', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          _AttendanceSummary(studentId: student.id),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _AttendanceSummary extends ConsumerWidget {
  const _AttendanceSummary({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(attendanceProvider)
        .when(
          loading: () => AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLoader.skeleton(width: 110, height: 15),
                const SizedBox(height: AppSpacing.md),
                AppLoader.skeleton(width: double.infinity, height: 8),
              ],
            ),
          ),
          error: (error, stackTrace) => const EmptyStateWidget(
            title: 'Attendance unavailable',
            description: 'Attendance summary could not be loaded.',
          ),
          data: (records) {
            final studentRecords = records
                .where((record) => record.studentId == studentId)
                .toList();
            if (studentRecords.isEmpty) {
              return const EmptyStateWidget(
                title: 'No attendance yet',
                description: 'Attendance records will appear after lessons.',
              );
            }
            final attended = studentRecords
                .where((record) => record.status != AttendanceStatus.absent)
                .length;
            final percentage = attended / studentRecords.length;
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(percentage * 100).round()}% attendance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LinearProgressIndicator(value: percentage),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$attended of ${studentRecords.length} lessons attended',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          },
        );
  }
}

String _initials(String name) => name
    .split(' ')
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0])
    .join()
    .toUpperCase();

String _statusLabel(StudentStatus status) => switch (status) {
  StudentStatus.active => 'Active',
  StudentStatus.paused => 'Paused',
  StudentStatus.left => 'Left',
};

StatusType _statusType(StudentStatus status) => switch (status) {
  StudentStatus.active => StatusType.active,
  StudentStatus.paused => StatusType.paused,
  StudentStatus.left => StatusType.left,
};
