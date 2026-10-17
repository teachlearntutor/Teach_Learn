import '../domain/models/attendance_record.dart';

class InMemoryAttendanceRepository {
  InMemoryAttendanceRepository() : _records = _seedRecords();

  final List<AttendanceRecord> _records;

  List<AttendanceRecord> getAll() => List.unmodifiable(_records);

  void save(AttendanceRecord record) {
    final index = _records.indexWhere((item) => item.id == record.id);
    if (index < 0) {
      _records.add(record);
    } else {
      _records[index] = record;
    }
  }

  static List<AttendanceRecord> _seedRecords() {
    final now = DateTime.now();
    return [
      for (var studentIndex = 1; studentIndex <= 8; studentIndex++)
        for (var lessonIndex = 1; lessonIndex <= 6; lessonIndex++)
          _record(now, studentIndex, lessonIndex),
    ];
  }

  static AttendanceRecord _record(
    DateTime now,
    int studentIndex,
    int lessonIndex,
  ) {
    final statusIndex = (studentIndex + lessonIndex) % 7;
    final status = statusIndex == 0
        ? AttendanceStatus.absent
        : statusIndex == 1
        ? AttendanceStatus.late
        : AttendanceStatus.present;
    return AttendanceRecord(
      id: 'attendance_${studentIndex}_$lessonIndex',
      classSessionId: 'history_${studentIndex}_$lessonIndex',
      studentId: 'student_$studentIndex',
      sessionDate: now.subtract(Duration(days: lessonIndex * 3)),
      status: status,
      markedAt: now.subtract(Duration(days: lessonIndex * 3)),
      absenceReason: status == AttendanceStatus.absent && lessonIndex.isEven
          ? 'Family commitment'
          : null,
    );
  }
}
