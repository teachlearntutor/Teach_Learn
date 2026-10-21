import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/models/attendance_record.dart';
import '../providers/attendance_providers.dart';

/// Reusable per-student monthly attendance calendar widget with colored dots,
/// percentage, counts, month picker, and class-wise breakdown.
class StudentMonthlyAttendanceCalendar extends ConsumerStatefulWidget {
  const StudentMonthlyAttendanceCalendar({
    super.key,
    required this.studentId,
  });

  final String studentId;

  @override
  ConsumerState<StudentMonthlyAttendanceCalendar> createState() =>
      _StudentMonthlyAttendanceCalendarState();
}

class _StudentMonthlyAttendanceCalendarState
    extends ConsumerState<StudentMonthlyAttendanceCalendar> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(studentAttendanceStreamProvider(widget.studentId));

    return attendanceState.when(
      data: (records) {
        // Filter records for selected month & year
        final monthlyRecords = records.where((r) {
          return r.sessionDate.year == _selectedMonth.year &&
              r.sessionDate.month == _selectedMonth.month;
        }).toList();

        final total = monthlyRecords.length;
        final presentCount = monthlyRecords.where((r) => r.status == AttendanceStatus.present).length;
        final lateCount = monthlyRecords.where((r) => r.status == AttendanceStatus.late).length;
        final absentCount = monthlyRecords.where((r) => r.status == AttendanceStatus.absent).length;

        final percentage = calculateAttendancePercentage(monthlyRecords);

        // Group records by day number
        final Map<int, AttendanceRecord> dayRecordMap = {
          for (final r in monthlyRecords) r.sessionDate.day: r
        };

        // Group records by subject for class-wise summary
        final Map<String, List<AttendanceRecord>> subjectMap = {};
        for (final r in monthlyRecords) {
          final subjectKey = r.classId != null && r.classId!.isNotEmpty ? r.classId! : 'General Tuition';
          subjectMap.putIfAbsent(subjectKey, () => []).add(r);
        }

        final monthName = _getMonthName(_selectedMonth.month);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Picker Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$monthName ${_selectedMonth.year}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      tooltip: 'Previous Month',
                      onPressed: _previousMonth,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      tooltip: 'Next Month',
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Percentage & Counts Summary Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${percentage.round()}% attendance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${percentage.round()}%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: percentage >= 75 ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LinearProgressIndicator(
                    value: total > 0 ? (percentage / 100.0) : 1.0,
                    backgroundColor: AppColors.borderLight,
                    color: percentage >= 75 ? AppColors.success : AppColors.danger,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Stat Badges
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      StatusChip.present(label: '$presentCount Present'),
                      StatusChip.late(label: '$lateCount Late'),
                      StatusChip.absent(label: '$absentCount Absent'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Monthly Calendar Grid
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calendar Roll Call',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Weekday Header Row (Mon..Sun)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _DayHeader('M'),
                      _DayHeader('T'),
                      _DayHeader('W'),
                      _DayHeader('T'),
                      _DayHeader('F'),
                      _DayHeader('S'),
                      _DayHeader('S'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Days Grid
                  _buildMonthGrid(context, _selectedMonth, dayRecordMap),
                ],
              ),
            ),

            if (subjectMap.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Class-wise Attendance Summary',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),

              ...subjectMap.entries.map((entry) {
                final subjectRecords = entry.value;
                final subTotal = subjectRecords.length;
                final subAttended = subjectRecords.where((r) => r.status != AttendanceStatus.absent).length;
                final subPct = (subAttended / subTotal) * 100;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.key),
                      subtitle: Text('$subAttended of $subTotal sessions attended'),
                      trailing: Text(
                        '${subPct.round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: subPct >= 75 ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        );
      },
      loading: () => const AppLoader.inline(),
      error: (_, _) => const EmptyStateWidget(
        title: 'Attendance Unavailable',
        description: 'Unable to load monthly attendance.',
      ),
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    DateTime month,
    Map<int, AttendanceRecord> dayRecordMap,
  ) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    // Adjust weekday: Monday = 0 .. Sunday = 6
    final leadingPadding = (firstDayOfMonth.weekday - 1) % 7;

    final totalCells = leadingPadding + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rowCount, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNum = cellIndex - leadingPadding + 1;

              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox(width: 32, height: 32);
              }

              final record = dayRecordMap[dayNum];
              Color? dotColor;
              if (record != null) {
                if (record.status == AttendanceStatus.present) {
                  dotColor = AppColors.success;
                } else if (record.status == AttendanceStatus.late) {
                  dotColor = AppColors.warning;
                } else {
                  dotColor = AppColors.danger;
                }
              }

              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor != null ? dotColor.withValues(alpha: 0.15) : Colors.transparent,
                  border: Border.all(
                    color: dotColor ?? AppColors.borderLight,
                    width: dotColor != null ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: dotColor != null ? FontWeight.bold : FontWeight.normal,
                        color: dotColor ?? Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    if (dotColor != null)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }
}
