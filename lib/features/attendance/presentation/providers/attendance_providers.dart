import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/attendance_repository.dart';
import '../../domain/models/attendance_record.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return FirestoreAttendanceRepository();
});

final allAttendanceStreamProvider = StreamProvider<List<AttendanceRecord>>((
  ref,
) {
  final user = ref.watch(currentAuthUserProvider);
  final uid = user?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return ref
      .watch(attendanceRepositoryProvider)
      .watchAllAttendance(uid)
      .map(uniqueAttendanceRecords);
});

final attendanceDateStreamProvider =
    StreamProvider.family<List<AttendanceRecord>, String>((ref, dateStr) {
      final user = ref.watch(currentAuthUserProvider);
      final uid = user?.uid ?? '';
      if (uid.isEmpty || dateStr.isEmpty) return Stream.value([]);
      return ref
          .watch(attendanceRepositoryProvider)
          .watchAttendanceForDate(uid, dateStr)
          .map(uniqueAttendanceRecords);
    });

List<AttendanceRecord> uniqueAttendanceRecords(
  Iterable<AttendanceRecord> records,
) {
  final latestByStudentAndDate = <String, AttendanceRecord>{};
  for (final record in records) {
    final key = '${record.studentId}\u0000${record.date}';
    final current = latestByStudentAndDate[key];
    if (current == null ||
        record.markedAt.isAfter(current.markedAt) ||
        (record.markedAt.isAtSameMomentAs(current.markedAt) &&
            record.id.compareTo(current.id) > 0)) {
      latestByStudentAndDate[key] = record;
    }
  }
  return latestByStudentAndDate.values.toList();
}

/// Attendance is counted once per student and date; the latest mark wins.
double calculateAttendancePercentage(List<AttendanceRecord> records) {
  if (records.isEmpty) return 100.0;
  final uniqueRecords = uniqueAttendanceRecords(records);
  final total = uniqueRecords.length;
  final attended = uniqueRecords
      .where(
        (r) =>
            r.status == AttendanceStatus.present ||
            r.status == AttendanceStatus.leave,
      )
      .length;
  return (attended / total) * 100;
}

final studentAttendancePercentageProvider = Provider.family<double, String>((
  ref,
  studentId,
) {
  final allRecords = ref.watch(allAttendanceStreamProvider).valueOrNull ?? [];
  final studentRecords = allRecords
      .where((r) => r.studentId == studentId)
      .toList();
  return calculateAttendancePercentage(studentRecords);
});
