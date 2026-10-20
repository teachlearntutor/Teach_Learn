import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/attendance_repository.dart';
import '../../domain/models/attendance_record.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return FirestoreAttendanceRepository();
});

final attendanceStreamProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  try {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? '';
    if (uid.isEmpty) return Stream.value([]);
    return ref.watch(attendanceRepositoryProvider).watchAttendance(uid);
  } catch (_) {
    return Stream.value([]);
  }
});

final attendanceProvider = Provider<AsyncValue<List<AttendanceRecord>>>((ref) {
  return ref.watch(attendanceStreamProvider);
});

final studentAttendanceStreamProvider =
    StreamProvider.family<List<AttendanceRecord>, String>((ref, studentId) {
  try {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? '';
    if (uid.isEmpty || studentId.isEmpty) return Stream.value([]);
    return ref
        .watch(attendanceRepositoryProvider)
        .watchStudentAttendance(uid, studentId);
  } catch (_) {
    return Stream.value([]);
  }
});

/// Pure helper function to calculate attendance percentage
double calculateAttendancePercentage(List<AttendanceRecord> records) {
  if (records.isEmpty) return 100.0;
  final total = records.length;
  final attended = records
      .where((r) => r.status == AttendanceStatus.present || r.status == AttendanceStatus.late)
      .length;
  return (attended / total) * 100;
}

final studentAttendancePercentageProvider =
    Provider.family<double, String>((ref, studentId) {
  final records = ref.watch(studentAttendanceStreamProvider(studentId)).value ?? [];
  return calculateAttendancePercentage(records);
});
