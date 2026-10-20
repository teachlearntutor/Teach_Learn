import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/class_repository.dart';
import '../../data/session_repository.dart';
import '../../domain/models/class_session.dart';
import '../../domain/models/holiday.dart';
import '../../domain/models/weekly_class.dart';
import '../../domain/services/class_expander.dart';

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return FirestoreClassRepository();
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return FirestoreSessionRepository();
});

final weeklyClassesStreamProvider = StreamProvider<List<WeeklyClass>>((ref) {
  try {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? '';
    if (uid.isEmpty) return Stream.value([]);
    return ref.watch(classRepositoryProvider).watchClasses(uid);
  } catch (_) {
    return Stream.value([]);
  }
});

final sessionOverridesStreamProvider = StreamProvider<List<ClassSession>>((ref) {
  try {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? '';
    if (uid.isEmpty) return Stream.value([]);
    return ref.watch(sessionRepositoryProvider).watchSessions(uid);
  } catch (_) {
    return Stream.value([]);
  }
});

final holidaysStreamProvider = StreamProvider<List<Holiday>>((ref) {
  try {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? '';
    if (uid.isEmpty) return Stream.value([]);
    return ref.watch(sessionRepositoryProvider).watchHolidays(uid);
  } catch (_) {
    return Stream.value([]);
  }
});

class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  const DateRange({required this.startDate, required this.endDate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}

final expandedSessionsProvider =
    Provider.family<List<ClassSession>, DateRange>((ref, range) {
  final classes = ref.watch(weeklyClassesStreamProvider).value ?? [];
  final overrides = ref.watch(sessionOverridesStreamProvider).value ?? [];
  final holidays = ref.watch(holidaysStreamProvider).value ?? [];

  return expandClassesToSessions(
    classes: classes,
    sessionOverrides: overrides,
    holidays: holidays,
    startDate: range.startDate,
    endDate: range.endDate,
  );
});
