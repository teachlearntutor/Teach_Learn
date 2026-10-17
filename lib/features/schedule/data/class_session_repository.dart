import '../domain/models/class_session.dart';

class InMemoryClassSessionRepository {
  InMemoryClassSessionRepository() : _sessions = _seedSessions();

  final List<ClassSession> _sessions;

  List<ClassSession> getAll() => List.unmodifiable(_sessions);

  void add(ClassSession session) {
    _sessions.add(session);
  }

  void update(ClassSession updatedSession) {
    final index = _sessions.indexWhere(
      (session) => session.id == updatedSession.id,
    );
    if (index >= 0) _sessions[index] = updatedSession;
  }

  void delete(String sessionId) {
    _sessions.removeWhere((session) => session.id == sessionId);
  }

  static List<ClassSession> _seedSessions() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    const subjects = ['Mathematics', 'Physics', 'Chemistry', 'English'];
    final sessions = <ClassSession>[];

    for (var day = 0; day < 7; day++) {
      final date = monday.add(Duration(days: day));
      final weekdaySlots = day == 6 ? 1 : 2;
      for (var slot = 0; slot < weekdaySlots; slot++) {
        final startsAt = DateTime(
          date.year,
          date.month,
          date.day,
          slot == 0 ? 16 : 18,
        );
        final firstStudent = ((day * 2 + slot) % 8) + 1;
        final secondStudent = (firstStudent % 8) + 1;
        sessions.add(
          ClassSession(
            id: 'class_${date.year}_${date.month}_${date.day}_$slot',
            subject: subjects[(day + slot) % subjects.length],
            startsAt: startsAt,
            durationMinutes: 60,
            studentIds: ['student_$firstStudent', 'student_$secondStudent'],
          ),
        );
      }
    }
    return sessions;
  }
}
