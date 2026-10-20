import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/class_session.dart';
import 'schedule_providers.dart';

final classSessionsProvider = Provider<AsyncValue<List<ClassSession>>>((ref) {
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, now.day - 7);
  final endDate = DateTime(now.year, now.month, now.day + 14);

  final range = DateRange(startDate: startDate, endDate: endDate);
  final sessions = ref.watch(expandedSessionsProvider(range));

  return AsyncData(sessions);
});
