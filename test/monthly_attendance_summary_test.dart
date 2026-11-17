import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/features/attendance/domain/models/attendance_record.dart';
import 'package:teach_learn/features/attendance/presentation/widgets/student_attendance_calendar.dart';

void main() {
  test('monthly share summary filters dates and counts the latest mark', () {
    final summary = buildMonthlyAttendanceSummary(
      studentName: 'Ali Khan',
      month: DateTime(2026, 11),
      records: [
        AttendanceRecord(
          id: 'student_2026-11-01-old',
          studentId: 'student',
          studentName: 'Ali Khan',
          date: '2026-11-01',
          status: AttendanceStatus.present,
          markedAt: DateTime(2026, 11, 1, 8),
        ),
        AttendanceRecord(
          id: 'student_2026-11-01-new',
          studentId: 'student',
          studentName: 'Ali Khan',
          date: '2026-11-01',
          status: AttendanceStatus.absent,
          markedAt: DateTime(2026, 11, 1, 18),
        ),
        AttendanceRecord(
          id: 'student_2026-11-02',
          studentId: 'student',
          studentName: 'Ali Khan',
          date: '2026-11-02',
          status: AttendanceStatus.leave,
          markedAt: DateTime(2026, 11, 2),
        ),
        AttendanceRecord(
          id: 'student_2026-10-31',
          studentId: 'student',
          studentName: 'Ali Khan',
          date: '2026-10-31',
          status: AttendanceStatus.present,
          markedAt: DateTime(2026, 10, 31),
        ),
      ],
    );

    expect(
      summary,
      'Ali Khan — November 2026 attendance\n'
      'Attendance: 50%\n'
      'Days marked: 2\n'
      'Present: 0 · Leave: 1 · Absent: 1',
    );
  });
}
