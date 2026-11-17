import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/features/attendance/domain/models/attendance_record.dart';
import 'package:teach_learn/features/profile/data/profile_cleanup_repository.dart';

void main() {
  test('duplicate cleanup keeps latest attendance and is repeatable', () async {
    final old = AttendanceRecord(
      id: 'old',
      studentId: 'student-1',
      studentName: 'Ayesha',
      date: '2026-11-15',
      status: AttendanceStatus.absent,
      markedAt: DateTime(2026, 11, 15, 8),
    );
    final latest = old.copyWith(
      id: 'latest',
      status: AttendanceStatus.present,
      markedAt: DateTime(2026, 11, 15, 9),
    );
    final otherDay = old.copyWith(id: 'other-day', date: '2026-11-14');
    final malformed = old.copyWith(
      id: 'legacy-without-key',
      studentId: '',
      date: '',
    );
    final repository = FakeProfileCleanupRepository(
      attendance: [old, latest, otherDay, malformed],
    );

    expect(await repository.removeAttendanceDuplicates('tutor-1'), 1);
    expect(repository.attendance.map((record) => record.id).toSet(), {
      'latest',
      'other-day',
      'legacy-without-key',
    });
    expect(await repository.removeAttendanceDuplicates('tutor-1'), 0);
  });

  test('legacy schedule cleanup is idempotent', () async {
    final repository = FakeProfileCleanupRepository(
      classes: ['class-1', 'class-2'],
      sessions: ['session-1'],
    );

    expect(
      await repository.removeLegacyScheduleCollection('tutor-1', 'classes'),
      2,
    );
    expect(
      await repository.removeLegacyScheduleCollection('tutor-1', 'sessions'),
      1,
    );
    expect(
      await repository.removeLegacyScheduleCollection('tutor-1', 'classes'),
      0,
    );
    expect(repository.classes, isEmpty);
    expect(repository.sessions, isEmpty);
  });
}
