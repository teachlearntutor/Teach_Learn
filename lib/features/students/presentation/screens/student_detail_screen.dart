import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../attendance/presentation/widgets/student_attendance_calendar.dart';
import '../../domain/models/student.dart';
import '../providers/student_providers.dart';
import 'student_form_screen.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({
    super.key,
    required this.studentId,
  });

  final String studentId;

  Future<void> _deleteStudent(BuildContext context, WidgetRef ref, Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student?'),
        content: Text('Are you sure you want to permanently delete ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    ref.read(studentsProvider.notifier).delete(student.id);

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${student.name} deleted.'),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsState = ref.watch(studentsProvider);

    return studentsState.when(
      data: (allStudents) {
        final student = allStudents.firstWhere(
          (s) => s.id == studentId,
          orElse: () => Student(
            id: studentId,
            name: 'Unknown Student',
            classLevel: 'Class',
            schoolName: '',
            subjects: [],
            parentContact: '',
            status: StudentStatus.active,
            joinedAt: DateTime.now(),
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(student.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Student',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => StudentFormScreen(student: student),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                tooltip: 'Delete Student',
                onPressed: () => _deleteStudent(context, ref, student),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Student Profile Card
              AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.name, style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 2),
                          Text(
                            '${student.classLevel} ${student.schoolName.isNotEmpty ? "• ${student.schoolName}" : ""}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          StatusChip.present(label: student.status.name.toUpperCase()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Contact & Subjects Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Parent contact'),
                      subtitle: Text(student.parentContact.isNotEmpty ? student.parentContact : 'Not provided'),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.menu_book_rounded),
                      title: const Text('Enrolled Subjects'),
                      subtitle: Text(student.subjects.isNotEmpty ? student.subjects.join(', ') : 'All Subjects'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Real Monthly Attendance Calendar & Breakdown
              StudentMonthlyAttendanceCalendar(studentId: student.id),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const Scaffold(
        body: EmptyStateWidget(
          title: 'Student unavailable',
          description: 'Could not load student profile.',
        ),
      ),
    );
  }
}
