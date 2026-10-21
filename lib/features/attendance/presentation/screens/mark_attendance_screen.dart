import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../schedule/domain/models/class_session.dart';
import '../../../students/domain/models/student.dart';
import '../../../students/presentation/providers/student_providers.dart';
import '../../domain/models/attendance_record.dart';
import '../providers/attendance_providers.dart';

/// Screen for marking or editing attendance for a specific class session.
class MarkAttendanceScreen extends ConsumerStatefulWidget {
  const MarkAttendanceScreen({
    super.key,
    required this.session,
  });

  final ClassSession session;

  @override
  ConsumerState<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  final Map<String, AttendanceStatus> _statuses = {};
  final Map<String, TextEditingController> _reasonControllers = {};
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    for (final controller in _reasonControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initRecords(List<Student> enrolledStudents, List<AttendanceRecord> existingRecords) {
    if (_isInitialized) return;

    final existingMap = {for (final r in existingRecords) r.studentId: r};

    for (final student in enrolledStudents) {
      final existing = existingMap[student.id];
      _statuses[student.id] = existing?.status ?? AttendanceStatus.present;
      _reasonControllers[student.id] = TextEditingController(text: existing?.reason ?? '');
    }

    _isInitialized = true;
  }

  void _markAllPresent(List<Student> enrolledStudents) {
    setState(() {
      for (final student in enrolledStudents) {
        _statuses[student.id] = AttendanceStatus.present;
      }
    });
  }

  Future<void> _saveAttendance(List<Student> enrolledStudents) async {
    if (_statuses.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? '';
      final now = DateTime.now();

      final records = enrolledStudents.map((student) {
        final status = _statuses[student.id] ?? AttendanceStatus.present;
        final reasonText = _reasonControllers[student.id]?.text.trim();
        final reason = (status == AttendanceStatus.absent && reasonText != null && reasonText.isNotEmpty)
            ? reasonText
            : null;

        return AttendanceRecord(
          id: '${widget.session.id}_${student.id}',
          sessionId: widget.session.id,
          classId: widget.session.classId,
          studentId: student.id,
          date: widget.session.date,
          startAt: widget.session.startAt,
          status: status,
          reason: reason,
          markedAt: now,
        );
      }).toList();

      final repo = ref.read(attendanceRepositoryProvider);
      await repo.markSessionAttendanceBatch(
        uid: uid,
        sessionId: widget.session.id,
        records: records,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance marked and saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save attendance: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentsProvider);
    final attendanceState = ref.watch(attendanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance • ${widget.session.subject}'),
      ),
      body: studentsState.when(
        data: (allStudents) {
          // Filter enrolled students for this session by studentIds or classLevel
          final enrolled = allStudents.where((s) {
            if (widget.session.studentIds.isNotEmpty) {
              return widget.session.studentIds.contains(s.id);
            }
            return s.status.name == 'active';
          }).toList();

          if (enrolled.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.people_outline_rounded,
              title: 'No students enrolled',
              description: 'Add active students to this class first.',
            );
          }

          final existingRecords = attendanceState.value ?? [];
          final sessionRecords = existingRecords.where((r) => r.sessionId == widget.session.id).toList();

          _initRecords(enrolled, sessionRecords);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Session Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.session.subject,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          StatusChip.present(
                            label: widget.session.attendanceMarked ? 'Already Marked' : 'Pending',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${widget.session.date} • ${widget.session.startsAt.hour}:${widget.session.startsAt.minute.toString().padLeft(2, '0')} (${widget.session.durationMinutes} mins)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Enrolled Students: ${enrolled.length}',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _markAllPresent(enrolled),
                            icon: const Icon(Icons.done_all_rounded, size: 16),
                            label: const Text('Mark All Present'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Text('Students Roll Call', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),

              // Students Roll Call List
              ...enrolled.map((student) {
                final status = _statuses[student.id] ?? AttendanceStatus.present;
                final reasonController = _reasonControllers[student.id];

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    '${student.classLevel} • ID: ${student.code}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Segmented Button: Present / Absent / Late
                        SegmentedButton<AttendanceStatus>(
                          segments: const [
                            ButtonSegment(
                              value: AttendanceStatus.present,
                              label: Text('Present'),
                              icon: Icon(Icons.check_circle_outline, size: 16),
                            ),
                            ButtonSegment(
                              value: AttendanceStatus.absent,
                              label: Text('Absent'),
                              icon: Icon(Icons.cancel_outlined, size: 16),
                            ),
                            ButtonSegment(
                              value: AttendanceStatus.late,
                              label: Text('Late'),
                              icon: Icon(Icons.access_time, size: 16),
                            ),
                          ],
                          selected: {status},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _statuses[student.id] = newSelection.first;
                            });
                          },
                        ),

                        // Absence Reason Input Field
                        if (status == AttendanceStatus.absent && reasonController != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppTextField(
                            label: 'Absence Reason (Optional)',
                            hint: 'e.g., Sick, Out of town, Family event',
                            controller: reasonController,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.lg),

              // Save Attendance Button
              AppButton.primary(
                label: _isSaving
                    ? 'Saving Attendance...'
                    : widget.session.attendanceMarked
                        ? 'Update Attendance Batch'
                        : 'Save Attendance Batch',
                isLoading: _isSaving,
                isFullWidth: true,
                onPressed: _isSaving ? null : () => _saveAttendance(enrolled),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
        loading: () => const AppLoader.inline(),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
