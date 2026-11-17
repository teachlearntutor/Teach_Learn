import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/models/attendance_record.dart';
import '../providers/attendance_providers.dart';

/// Reusable per-student monthly attendance calendar widget with colored dots,
/// percentage, counts, and month picker.
class StudentMonthlyAttendanceCalendar extends ConsumerStatefulWidget {
  const StudentMonthlyAttendanceCalendar({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  final String studentId;
  final String studentName;

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
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attendanceState = ref.watch(allAttendanceStreamProvider);
    final allRecords = attendanceState.valueOrNull ?? [];
    final studentRecords = uniqueAttendanceRecords(
      allRecords.where((r) => r.studentId == widget.studentId),
    );

    final monthlyRecords = studentRecords.where((r) {
      final parsed = DateTime.tryParse(r.date);
      if (parsed == null) return false;
      return parsed.year == _selectedMonth.year &&
          parsed.month == _selectedMonth.month;
    }).toList();

    final total = monthlyRecords.length;
    final presentCount = monthlyRecords
        .where((r) => r.status == AttendanceStatus.present)
        .length;
    final leaveCount = monthlyRecords
        .where((r) => r.status == AttendanceStatus.leave)
        .length;
    final absentCount = monthlyRecords
        .where((r) => r.status == AttendanceStatus.absent)
        .length;

    final percentage = calculateAttendancePercentage(monthlyRecords);

    // Group records by day number
    final Map<int, AttendanceRecord> dayRecordMap = {};
    for (final r in monthlyRecords) {
      final parsed = DateTime.tryParse(r.date);
      if (parsed != null) {
        dayRecordMap[parsed.day] = r;
      }
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
                  icon: const Icon(Icons.ios_share_rounded),
                  tooltip: 'Share monthly attendance',
                  onPressed: attendanceState.hasValue
                      ? () => SharePlus.instance.share(
                          ShareParams(
                            text: buildMonthlyAttendanceSummary(
                              studentName: widget.studentName,
                              month: _selectedMonth,
                              records: monthlyRecords,
                            ),
                          ),
                        )
                      : null,
                ),
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
                    '${percentage.round()}% Attendance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${percentage.round()}%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: percentage >= 75
                          ? (isDark
                                ? AppColors.darkSuccessText
                                : AppColors.success)
                          : colors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: total > 0 ? (percentage / 100.0) : 1.0,
                backgroundColor: colors.surfaceContainerHighest,
                color: percentage >= 75
                    ? (isDark ? AppColors.darkSuccessText : AppColors.success)
                    : colors.error,
              ),
              const SizedBox(height: AppSpacing.md),

              // Stat Badges
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  StatusChip.present(label: '$presentCount Present'),
                  StatusChip.present(label: '$leaveCount Leave'),
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

              _buildMonthGrid(context, _selectedMonth, dayRecordMap),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    DateTime month,
    Map<int, AttendanceRecord> dayRecordMap,
  ) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
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
                  dotColor = isDark
                      ? AppColors.darkSuccessText
                      : AppColors.success;
                } else if (record.status == AttendanceStatus.leave) {
                  dotColor = isDark
                      ? AppColors.darkWarningText
                      : AppColors.warning;
                } else {
                  dotColor = colors.error;
                }
              }

              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor != null
                      ? dotColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: dotColor ?? colors.outlineVariant,
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
                        fontWeight: dotColor != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: dotColor ?? colors.onSurface,
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
      'December',
    ];
    return months[month - 1];
  }
}

String buildMonthlyAttendanceSummary({
  required String studentName,
  required DateTime month,
  required Iterable<AttendanceRecord> records,
}) {
  final monthlyRecords = uniqueAttendanceRecords(
    records.where((record) {
      final date = DateTime.tryParse(record.date);
      return date != null &&
          date.year == month.year &&
          date.month == month.month;
    }),
  );
  final present = monthlyRecords
      .where((record) => record.status == AttendanceStatus.present)
      .length;
  final leave = monthlyRecords
      .where((record) => record.status == AttendanceStatus.leave)
      .length;
  final absent = monthlyRecords
      .where((record) => record.status == AttendanceStatus.absent)
      .length;
  final monthLabel = const [
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
    'December',
  ][month.month - 1];

  return [
    '$studentName — $monthLabel ${month.year} attendance',
    'Attendance: ${calculateAttendancePercentage(monthlyRecords).round()}%',
    'Days marked: ${monthlyRecords.length}',
    'Present: $present · Leave: $leave · Absent: $absent',
  ].join('\n');
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
