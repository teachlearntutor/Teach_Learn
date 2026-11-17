import 'dart:async';
import '../domain/models/attendance_record.dart';
import 'attendance_repository.dart';

class FakeAttendanceRepository implements AttendanceRepository {
  final List<AttendanceRecord> _records = [];
  final _controller = StreamController<List<AttendanceRecord>>.broadcast();

  FakeAttendanceRepository([List<AttendanceRecord>? initial]) {
    if (initial != null) _records.addAll(initial);
  }

  void _emit() {
    _controller.add(List.unmodifiable(_records));
  }

  @override
  Stream<List<AttendanceRecord>> watchAttendanceForDate(String uid, String date) {
    scheduleMicrotask(() {
      final filtered = _records.where((r) => r.date == date).toList();
      _controller.add(List.unmodifiable(filtered));
    });
    return _controller.stream;
  }

  @override
  Stream<List<AttendanceRecord>> watchAllAttendance(String uid) {
    scheduleMicrotask(() {
      _controller.add(List.unmodifiable(_records));
    });
    return _controller.stream;
  }

  @override
  Future<void> saveAttendanceBatch(String uid, String date, List<AttendanceRecord> records) async {
    for (final r in records) {
      final docId = '${r.studentId}_$date';
      final idx = _records.indexWhere((existing) => existing.id == docId);
      final recordWithId = r.copyWith(id: docId, date: date);

      if (idx != -1) {
        _records[idx] = recordWithId;
      } else {
        _records.add(recordWithId);
      }
    }
    _emit();
  }

  void dispose() {
    _controller.close();
  }
}
