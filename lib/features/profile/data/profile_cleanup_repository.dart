import 'package:cloud_firestore/cloud_firestore.dart';

import '../../attendance/domain/models/attendance_record.dart';

abstract class ProfileCleanupRepository {
  Future<int> removeAttendanceDuplicates(String uid);
  Future<int> removeLegacyScheduleCollection(String uid, String collection);
}

class FirestoreProfileCleanupRepository implements ProfileCleanupRepository {
  FirestoreProfileCleanupRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<int> removeAttendanceDuplicates(String uid) async {
    if (uid.isEmpty) return 0;
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .get();
    final grouped =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final document in snapshot.docs) {
      final record = AttendanceRecord.fromFirestore(document);
      if (record.studentId.isEmpty || record.date.isEmpty) continue;
      final key = '${record.studentId}\u0000${record.date}';
      grouped.putIfAbsent(key, () => []).add(document);
    }

    final duplicates = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final documents in grouped.values) {
      if (documents.length < 2) continue;
      documents.sort((first, second) {
        final firstRecord = AttendanceRecord.fromFirestore(first);
        final secondRecord = AttendanceRecord.fromFirestore(second);
        final timeOrder = secondRecord.markedAt.compareTo(firstRecord.markedAt);
        return timeOrder != 0 ? timeOrder : second.id.compareTo(first.id);
      });
      duplicates.addAll(documents.skip(1));
    }

    await _deleteInChunks(duplicates);
    return duplicates.length;
  }

  @override
  Future<int> removeLegacyScheduleCollection(
    String uid,
    String collection,
  ) async {
    if (uid.isEmpty) return 0;
    if (collection != 'classes' && collection != 'sessions') {
      throw ArgumentError.value(collection, 'collection');
    }
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection(collection)
        .get();
    await _deleteInChunks(snapshot.docs);
    return snapshot.docs.length;
  }

  Future<void> _deleteInChunks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) async {
    const chunkSize = 400;
    for (var start = 0; start < documents.length; start += chunkSize) {
      final end = (start + chunkSize).clamp(0, documents.length);
      final batch = _firestore.batch();
      for (final document in documents.sublist(start, end)) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }
}

class FakeProfileCleanupRepository implements ProfileCleanupRepository {
  FakeProfileCleanupRepository({
    List<AttendanceRecord> attendance = const [],
    List<String> classes = const [],
    List<String> sessions = const [],
  }) : _attendance = List.of(attendance),
       _classes = List.of(classes),
       _sessions = List.of(sessions);

  final List<AttendanceRecord> _attendance;
  final List<String> _classes;
  final List<String> _sessions;

  List<AttendanceRecord> get attendance => List.unmodifiable(_attendance);
  List<String> get classes => List.unmodifiable(_classes);
  List<String> get sessions => List.unmodifiable(_sessions);

  @override
  Future<int> removeAttendanceDuplicates(String uid) async {
    if (uid.isEmpty) return 0;
    final keepIds = <String, AttendanceRecord>{};
    for (final record in _attendance) {
      if (record.studentId.isEmpty || record.date.isEmpty) continue;
      final key = '${record.studentId}\u0000${record.date}';
      final current = keepIds[key];
      if (current == null ||
          record.markedAt.isAfter(current.markedAt) ||
          (record.markedAt.isAtSameMomentAs(current.markedAt) &&
              record.id.compareTo(current.id) > 0)) {
        keepIds[key] = record;
      }
    }
    final retained = <String>{
      ..._attendance
          .where((record) => record.studentId.isEmpty || record.date.isEmpty)
          .map((record) => record.id),
      ...keepIds.values.map((record) => record.id),
    };
    final before = _attendance.length;
    _attendance.removeWhere((record) => !retained.contains(record.id));
    return before - _attendance.length;
  }

  @override
  Future<int> removeLegacyScheduleCollection(
    String uid,
    String collection,
  ) async {
    if (uid.isEmpty) return 0;
    final records = switch (collection) {
      'classes' => _classes,
      'sessions' => _sessions,
      _ => throw ArgumentError.value(collection, 'collection'),
    };
    final count = records.length;
    records.clear();
    return count;
  }
}
