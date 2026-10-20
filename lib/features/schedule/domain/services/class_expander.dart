import '../models/class_session.dart';
import '../models/holiday.dart';
import '../models/weekly_class.dart';

/// Pure function to expand weekly recurring classes into concrete date sessions,
/// merging overrides (rescheduled, cancelled, extra, makeup) and holidays.
List<ClassSession> expandClassesToSessions({
  required List<WeeklyClass> classes,
  required List<ClassSession> sessionOverrides,
  required List<Holiday> holidays,
  required DateTime startDate,
  required DateTime endDate,
}) {
  final List<ClassSession> result = [];
  final Set<String> holidayDates = holidays.map((h) => h.date).toSet();
  final Map<String, ClassSession> overrideMap = {
    for (final s in sessionOverrides) s.id: s
  };

  // Normalize dates to midnight for date arithmetic
  final startDay = DateTime(startDate.year, startDate.month, startDate.day);
  final endDay = DateTime(endDate.year, endDate.month, endDate.day);

  for (var current = startDay;
      !current.isAfter(endDay);
      current = current.add(const Duration(days: 1))) {
    final dateStr = _formatDate(current);
    final isHoliday = holidayDates.contains(dateStr);

    for (final cls in classes) {
      if (!cls.active) continue;

      // Verify class date boundary
      final clsStart = _parseDate(cls.startDate);
      if (clsStart != null && current.isBefore(clsStart)) continue;

      if (cls.endDate != null) {
        final clsEnd = _parseDate(cls.endDate!);
        if (clsEnd != null && current.isAfter(clsEnd)) continue;
      }

      // Verify weekday match (cls.weekdays: 1 = Monday .. 7 = Sunday)
      if (cls.weekdays.contains(current.weekday)) {
        final generatedId = '${cls.id}_${dateStr.replaceAll('-', '')}';

        if (overrideMap.containsKey(generatedId)) {
          // Add the explicit override (e.g., cancelled or rescheduled)
          result.add(overrideMap[generatedId]!);
        } else if (!isHoliday) {
          // Generate regular session if not on a holiday
          final timeParts = cls.startTime.split(':');
          final hour = timeParts.isNotEmpty ? int.parse(timeParts[0]) : 17;
          final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;

          final startAt = DateTime(
            current.year,
            current.month,
            current.day,
            hour,
            minute,
          );
          final endAt = startAt.add(Duration(minutes: cls.durationMin));

          result.add(
            ClassSession(
              id: generatedId,
              classId: cls.id,
              kind: 'regular',
              date: dateStr,
              startAt: startAt,
              endAt: endAt,
              status: 'scheduled',
              subject: cls.subject,
              studentIds: cls.studentIds,
              location: cls.location,
              createdAt: cls.createdAt,
              updatedAt: cls.updatedAt,
            ),
          );
        }
      }
    }
  }

  // Include extra/makeup sessions or standalone overrides not matched in generated loop
  for (final override in sessionOverrides) {
    if (!result.any((s) => s.id == override.id)) {
      final overrideDate = _parseDate(override.date);
      if (overrideDate != null &&
          !overrideDate.isBefore(startDay) &&
          !overrideDate.isAfter(endDay)) {
        result.add(override);
      }
    }
  }

  // Sort sessions chronologically
  result.sort((a, b) => a.startAt.compareTo(b.startAt));
  return result;
}

String _formatDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime? _parseDate(String dateStr) {
  try {
    final parts = dateStr.split('-');
    if (parts.length != 3) return null;
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  } catch (_) {
    return null;
  }
}
