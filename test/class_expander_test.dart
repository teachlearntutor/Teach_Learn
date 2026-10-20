import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/features/schedule/domain/models/class_session.dart';
import 'package:teach_learn/features/schedule/domain/models/holiday.dart';
import 'package:teach_learn/features/schedule/domain/models/weekly_class.dart';
import 'package:teach_learn/features/schedule/domain/services/class_expander.dart';

void main() {
  group('class_expander tests', () {
    final now = DateTime.now();

    final testClass = WeeklyClass(
      id: 'cls_1',
      title: 'Maths Class 9',
      subject: 'Mathematics',
      classLevel: 'Class 9',
      studentIds: ['s1', 's2'],
      weekdays: [1, 3, 5], // Mon, Wed, Fri
      startTime: '17:00',
      durationMin: 60,
      startDate: '2026-01-01',
      location: const ClassLocation(type: 'home', place: 'DHA Phase 5'),
      createdAt: now,
      updatedAt: now,
    );

    test('expands active weekly class into date range correctly', () {
      final start = DateTime(2026, 10, 19); // Monday
      final end = DateTime(2026, 10, 25); // Sunday

      final sessions = expandClassesToSessions(
        classes: [testClass],
        sessionOverrides: [],
        holidays: [],
        startDate: start,
        endDate: end,
      );

      // Mon (19), Wed (21), Fri (23) -> 3 sessions
      expect(sessions.length, equals(3));
      expect(sessions[0].date, equals('2026-10-19'));
      expect(sessions[1].date, equals('2026-10-21'));
      expect(sessions[2].date, equals('2026-10-23'));
    });

    test('holiday cancels regular class session for that day', () {
      final start = DateTime(2026, 10, 19); // Monday
      final end = DateTime(2026, 10, 25); // Sunday

      final holidays = [
        const Holiday(id: 'h1', date: '2026-10-21', reason: 'Public Holiday'),
      ];

      final sessions = expandClassesToSessions(
        classes: [testClass],
        sessionOverrides: [],
        holidays: holidays,
        startDate: start,
        endDate: end,
      );

      // Wednesday session skipped due to holiday
      expect(sessions.length, equals(2));
      expect(sessions[0].date, equals('2026-10-19'));
      expect(sessions[1].date, equals('2026-10-23'));
    });

    test('explicit session override replaces generated session status', () {
      final start = DateTime(2026, 10, 19);
      final end = DateTime(2026, 10, 25);

      final override = ClassSession(
        id: 'cls_1_20261021',
        classId: 'cls_1',
        date: '2026-10-21',
        startAt: DateTime(2026, 10, 21, 17, 0),
        endAt: DateTime(2026, 10, 21, 18, 0),
        status: 'cancelled',
        cancelReason: 'Tutor unwell',
        subject: 'Mathematics',
        studentIds: ['s1'],
        location: const ClassLocation(type: 'home'),
        createdAt: now,
        updatedAt: now,
      );

      final sessions = expandClassesToSessions(
        classes: [testClass],
        sessionOverrides: [override],
        holidays: [],
        startDate: start,
        endDate: end,
      );

      expect(sessions.length, equals(3));
      final wedSession = sessions.firstWhere((s) => s.date == '2026-10-21');
      expect(wedSession.status, equals('cancelled'));
      expect(wedSession.cancelReason, equals('Tutor unwell'));
    });

    test('handles month boundary dates cleanly', () {
      final start = DateTime(2026, 10, 30); // Friday
      final end = DateTime(2026, 11, 2); // Monday

      final sessions = expandClassesToSessions(
        classes: [testClass],
        sessionOverrides: [],
        holidays: [],
        startDate: start,
        endDate: end,
      );

      expect(sessions.length, equals(2));
      expect(sessions[0].date, equals('2026-10-30')); // Fri
      expect(sessions[1].date, equals('2026-11-02')); // Mon
    });
  });
}
