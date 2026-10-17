import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/attendance_repository.dart';
import '../../domain/models/attendance_record.dart';

final attendanceRepositoryProvider = Provider<InMemoryAttendanceRepository>(
  (ref) => InMemoryAttendanceRepository(),
);

final attendanceProvider =
    StateNotifierProvider<
      AttendanceController,
      AsyncValue<List<AttendanceRecord>>
    >((ref) => AttendanceController(ref.watch(attendanceRepositoryProvider)));

class AttendanceController
    extends StateNotifier<AsyncValue<List<AttendanceRecord>>> {
  AttendanceController(this._repository) : super(const AsyncLoading()) {
    _load();
  }

  final InMemoryAttendanceRepository _repository;

  Future<void> _load() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) state = AsyncData(_repository.getAll());
  }

  void save(AttendanceRecord record) {
    _repository.save(record);
    state = AsyncData(_repository.getAll());
  }
}
