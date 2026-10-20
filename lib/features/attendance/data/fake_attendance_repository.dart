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
  Stream<List<AttendanceRecord>> watchAttendance(String uid) {
    scheduleMicrotask(_emit);
    return _controller.stream;
  }

  @override
  Stream<List<AttendanceRecord>> watchStudentAttendance(String uid, String studentId) {
    scheduleMicrotask(() {
      final filtered = _records.where((r) => r.studentId == studentId).toList();
      _controller.add(List.unmodifiable(filtered));
    });
    return _controller.stream;
  }

  @override
  Future<void> markSessionAttendanceBatch({
    required String uid,
    required String sessionId,
    required List<AttendanceRecord> records,
  }) async {
    for (final record in records) {
      final docId = '${sessionId}_${record.studentId}';
      final index = _records.indexWhere((r) => r.id == docId);
      final updated = record.copyWith(id: docId);
      if (index != -1) {
        _records[index] = updated;
      } else {
        _records.add(updated);
      }
    }
    _emit();
  }

  @override
  Future<void> updateAttendanceRecord(String uid, AttendanceRecord record) async {
    final docId = record.id.isNotEmpty
        ? record.id
        : '${record.sessionId}_${record.studentId}';
    final index = _records.indexWhere((r) => r.id == docId);
    if (index != -1) {
      _records[index] = record.copyWith(id: docId);
    } else {
      _records.add(record.copyWith(id: docId));
    }
    _emit();
  }

  void dispose() {
    _controller.close();
  }
}
