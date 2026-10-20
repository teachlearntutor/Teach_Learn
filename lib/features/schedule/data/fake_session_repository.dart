import 'dart:async';
import '../domain/models/class_session.dart';
import '../domain/models/holiday.dart';
import 'session_repository.dart';

class FakeSessionRepository implements SessionRepository {
  final List<ClassSession> _sessions = [];
  final List<Holiday> _holidays = [];

  final _sessionController = StreamController<List<ClassSession>>.broadcast();
  final _holidayController = StreamController<List<Holiday>>.broadcast();

  FakeSessionRepository({
    List<ClassSession>? initialSessions,
    List<Holiday>? initialHolidays,
  }) {
    if (initialSessions != null) _sessions.addAll(initialSessions);
    if (initialHolidays != null) _holidays.addAll(initialHolidays);
  }

  void _emitSessions() => _sessionController.add(List.unmodifiable(_sessions));
  void _emitHolidays() => _holidayController.add(List.unmodifiable(_holidays));

  @override
  Stream<List<ClassSession>> watchSessions(String uid) {
    scheduleMicrotask(_emitSessions);
    return _sessionController.stream;
  }

  @override
  Stream<List<Holiday>> watchHolidays(String uid) {
    scheduleMicrotask(_emitHolidays);
    return _holidayController.stream;
  }

  @override
  Future<void> saveSessionOverride(String uid, ClassSession session) async {
    final newId = session.id.isEmpty
        ? 'session_${DateTime.now().millisecondsSinceEpoch}'
        : session.id;
    final index = _sessions.indexWhere((s) => s.id == newId);
    if (index != -1) {
      _sessions[index] = session.copyWith(id: newId);
    } else {
      _sessions.add(session.copyWith(id: newId));
    }
    _emitSessions();
  }

  @override
  Future<void> deleteSessionOverride(String uid, String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    _emitSessions();
  }

  @override
  Future<void> addHoliday(String uid, Holiday holiday) async {
    final newId = holiday.id.isEmpty
        ? 'holiday_${DateTime.now().millisecondsSinceEpoch}'
        : holiday.id;
    _holidays.add(Holiday(id: newId, date: holiday.date, reason: holiday.reason));
    _emitHolidays();
  }

  @override
  Future<void> deleteHoliday(String uid, String holidayId) async {
    _holidays.removeWhere((h) => h.id == holidayId);
    _emitHolidays();
  }

  void dispose() {
    _sessionController.close();
    _holidayController.close();
  }
}
