import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../schedule/presentation/providers/class_session_providers.dart';
import '../../domain/models/attendance_record.dart';
import '../providers/attendance_providers.dart';
import 'mark_attendance_screen.dart';

/// Attendance Tab View showing today's classes, pending highlights, and marking history.
class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsState = ref.watch(classSessionsProvider);
    final attendanceState = ref.watch(attendanceProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          "Today's Classes & Attendance Call",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tap any class below to mark or edit roll call attendance.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),

        // Classes list for today / recent
        sessionsState.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.fact_check_outlined,
                title: 'No classes found',
                description: 'Scheduled classes will appear here for roll call.',
              );
            }

            final pendingCount = sessions.where((s) => !s.attendanceMarked).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pendingCount > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.warning),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '$pendingCount class session(s) pending attendance marking today!',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                ...sessions.take(6).map((session) {
                  final isPending = !session.attendanceMarked;

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isPending ? AppColors.warning : AppColors.borderLight,
                        width: isPending ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                      leading: CircleAvatar(
                        backgroundColor: isPending ? AppColors.warningSurface : AppColors.successSurface,
                        child: Icon(
                          isPending ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
                          color: isPending ? AppColors.warning : AppColors.success,
                        ),
                      ),
                      title: Text(
                        session.subject,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        'Date: ${session.date} • ${session.startsAt.hour}:${session.startsAt.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: StatusChip.present(
                        label: isPending ? 'Pending' : 'Marked',
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MarkAttendanceScreen(session: session),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => const AppLoader.inline(),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),

        const SizedBox(height: AppSpacing.lg),
        Text(
          'Marked Attendance History',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),

        attendanceState.when(
          data: (records) {
            if (records.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.fact_check_outlined,
                title: 'No attendance records yet',
                description: 'Marked roll calls will appear in history.',
              );
            }

            return Column(
              children: records.take(10).map((record) {
                final isPresent = record.status == AttendanceStatus.present;
                final isAbsent = record.status == AttendanceStatus.absent;

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: Icon(
                      isPresent
                          ? Icons.check_circle_rounded
                          : (isAbsent ? Icons.cancel_rounded : Icons.access_time_filled_rounded),
                      color: isPresent
                          ? AppColors.success
                          : (isAbsent ? AppColors.danger : AppColors.warning),
                    ),
                    title: Text('Student ID: ${record.studentId}'),
                    subtitle: Text(
                      'Date: ${record.date}${record.reason != null ? " • Reason: ${record.reason}" : ""}',
                    ),
                    trailing: StatusChip.present(
                      label: record.status.name.toUpperCase(),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const AppLoader.inline(),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ],
    );
  }
}
