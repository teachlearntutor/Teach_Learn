import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/features/attendance/data/fake_attendance_repository.dart';
import 'package:teach_learn/features/attendance/domain/models/attendance_record.dart';
import 'package:teach_learn/features/attendance/presentation/providers/attendance_providers.dart';

void main() {
  group('Attendance F5 Step 1 Tests', () {
    final now = DateTime.now();

    test('calculates attendance percentage correctly', () {
      final records = [
        AttendanceRecord(
          id: 's1_st1',
          sessionId: 's1',
          studentId: 'st1',
          date: '2026-10-19',
          startAt: now,
          status: AttendanceStatus.present,
          markedAt: now,
        ),
        AttendanceRecord(
          id: 's2_st1',
          sessionId: 's2',
          studentId: 'st1',
          date: '2026-10-20',
          startAt: now,
          status: AttendanceStatus.absent,
          markedAt: now,
        ),
        AttendanceRecord(
          id: 's3_st1',
          sessionId: 's3',
          studentId: 'st1',
          date: '2026-10-21',
          startAt: now,
          status: AttendanceStatus.late,
          markedAt: now,
        ),
        AttendanceRecord(
          id: 's4_st1',
          sessionId: 's4',
          studentId: 'st1',
          date: '2026-10-22',
          startAt: now,
          status: AttendanceStatus.absent,
          markedAt: now,
        ),
      ];

      // 2 present/late out of 4 = 50.0%
      final percentage = calculateAttendancePercentage(records);
      expect(percentage, equals(50.0));
    });

    test('FakeAttendanceRepository batch marks attendance atomically', () async {
      final repo = FakeAttendanceRepository();

      final records = [
        AttendanceRecord(
          id: 'sess1_st1',
          sessionId: 'sess1',
          studentId: 'st1',
          date: '2026-10-20',
          startAt: now,
          status: AttendanceStatus.present,
          markedAt: now,
        ),
        AttendanceRecord(
          id: 'sess1_st2',
          sessionId: 'sess1',
          studentId: 'st2',
          date: '2026-10-20',
          startAt: now,
          status: AttendanceStatus.absent,
          reason: 'Sick',
          markedAt: now,
        ),
      ];

      await repo.markSessionAttendanceBatch(
        uid: 'user_123',
        sessionId: 'sess1',
        records: records,
      );

      final streamRecords = await repo.watchAttendance('user_123').first;
      expect(streamRecords.length, equals(2));
      expect(streamRecords.firstWhere((r) => r.studentId == 'st2').status, equals(AttendanceStatus.absent));
      expect(streamRecords.firstWhere((r) => r.studentId == 'st2').reason, equals('Sick'));
    });
  });
}
