import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/attendance_record.dart';

abstract class AttendanceRepository {
  Stream<List<AttendanceRecord>> watchAttendanceForDate(String uid, String date);
  Stream<List<AttendanceRecord>> watchAllAttendance(String uid);
  Future<void> saveAttendanceBatch(String uid, String date, List<AttendanceRecord> records);
}

class FirestoreAttendanceRepository implements AttendanceRepository {
  final FirebaseFirestore _firestore;

  FirestoreAttendanceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _ref(String uid) {
    return _firestore.collection('users').doc(uid).collection('attendance');
  }

  @override
  Stream<List<AttendanceRecord>> watchAttendanceForDate(String uid, String date) {
    if (uid.isEmpty || date.isEmpty) return Stream.value([]);
    return _ref(uid)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceRecord.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Stream<List<AttendanceRecord>> watchAllAttendance(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _ref(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceRecord.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> saveAttendanceBatch(String uid, String date, List<AttendanceRecord> records) async {
    if (uid.isEmpty || records.isEmpty) return;

    const chunkSize = 400;
    for (var i = 0; i < records.length; i += chunkSize) {
      final batch = _firestore.batch();
      final chunk = records.sublist(i, (i + chunkSize).clamp(0, records.length));
      for (final record in chunk) {
        final docId = '${record.studentId}_$date';
        final docRef = _ref(uid).doc(docId);
        batch.set(docRef, record.copyWith(id: docId, date: date).toFirestore(), SetOptions(merge: true));
      }
      await batch.commit();
    }
  }
}
