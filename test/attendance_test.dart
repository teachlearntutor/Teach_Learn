import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/features/attendance/data/fake_attendance_repository.dart';
import 'package:teach_learn/features/attendance/domain/models/attendance_record.dart';
import 'package:teach_learn/features/attendance/presentation/providers/attendance_providers.dart';

void main() {
  group('Attendance Date-Based Roll Call & Percentage Tests', () {
    final now = DateTime.now();

    test('calculates attendance percentage correctly with present, leave, and absent', () {
      final records = [
        AttendanceRecord(
          id: 'st1_2026-10-19',
          studentId: 'st1',
          studentName: 'Ayesha Khan',
          date: '2026-10-19',
          status: AttendanceStatus.present,
          markedAt: now,
        ),
        AttendanceRecord(
          id: 'st1_2026-10-20',
          studentId: 'st1',
          studentName: 'Ayesha Khan',
          date: '2026-10-20',
          status: AttendanceStatus.absent,
          markedAt: now,
        ),
        AttendanceRecord(
          id: 'st1_2026-10-21',
          studentId: 'st1',
          studentName: 'Ayesha Khan',
          date: '2026-10-21',
          status: AttendanceStatus.leave,
          markedAt: now,
        ),
        AttendanceRecord(
          id: 'st1_2026-10-22',
          studentId: 'st1',
          studentName: 'Ayesha Khan',
          date: '2026-10-22',
          status: AttendanceStatus.absent,
          markedAt: now,
        ),
      ];

      // 2 present/leave out of 4 = 50.0%
      final percentage = calculateAttendancePercentage(records);
      expect(percentage, equals(50.0));
    });

    test('duplicate student-date records count once and latest mark wins', () {
      final records = [
        AttendanceRecord(
          id: 'legacy_duplicate_1',
          studentId: 'st1',
          studentName: 'Ayesha Khan',
          date: '2026-10-19',
          status: AttendanceStatus.present,
          markedAt: DateTime(2026, 10, 19, 8),
        ),
        AttendanceRecord(
          id: 'st1_2026-10-19',
          studentId: 'st1',
          studentName: 'Ayesha Khan',
          date: '2026-10-19',
          status: AttendanceStatus.absent,
          markedAt: DateTime(2026, 10, 19, 9),
        ),
        AttendanceRecord(
          id: 'st1_2026-10-20',
          studentId: 'st1',
          studentName: 'Ayesha Khan',
          date: '2026-10-20',
          status: AttendanceStatus.present,
          markedAt: DateTime(2026, 10, 20, 8),
        ),
      ];

      expect(uniqueAttendanceRecords(records), hasLength(2));
      expect(calculateAttendancePercentage(records), equals(50));
    });

    test(
      'FakeAttendanceRepository saves date-based attendance batch',
      () async {
        final repo = FakeAttendanceRepository();

        final records = [
          AttendanceRecord(
            id: 'legacy_wrong_id',
            studentId: 'st1',
            studentName: 'Ayesha Khan',
            date: '2026-10-20',
            status: AttendanceStatus.present,
            markedAt: now,
          ),
          AttendanceRecord(
            id: 'st2_2026-10-20',
            studentId: 'st2',
            studentName: 'Hamza Raza',
            date: '2026-10-20',
            status: AttendanceStatus.absent,
            note: 'Sick leave',
            markedAt: now,
          ),
        ];

        await repo.saveAttendanceBatch('user_123', '2026-10-20', records);

        final streamRecords = await repo
            .watchAttendanceForDate('user_123', '2026-10-20')
            .first;
        expect(streamRecords.length, equals(2));
        expect(
          streamRecords.map((record) => record.id),
          contains('st1_2026-10-20'),
        );
        expect(
          streamRecords.firstWhere((r) => r.studentId == 'st2').status,
          equals(AttendanceStatus.absent),
        );
        expect(
          streamRecords.firstWhere((r) => r.studentId == 'st2').note,
          equals('Sick leave'),
        );
      },
    );
  });
}
