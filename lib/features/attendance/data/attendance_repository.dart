import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/attendance_record.dart';

abstract class AttendanceRepository {
  Stream<List<AttendanceRecord>> watchAttendance(String uid);
  Stream<List<AttendanceRecord>> watchStudentAttendance(String uid, String studentId);
  Future<void> markSessionAttendanceBatch({
    required String uid,
    required String sessionId,
    required List<AttendanceRecord> records,
  });
  Future<void> updateAttendanceRecord(String uid, AttendanceRecord record);
}

class FirestoreAttendanceRepository implements AttendanceRepository {
  final FirebaseFirestore _firestore;

  FirestoreAttendanceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _ref(String uid) {
    return _firestore.collection('users').doc(uid).collection('attendance');
  }

  @override
  Stream<List<AttendanceRecord>> watchAttendance(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _ref(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceRecord.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Stream<List<AttendanceRecord>> watchStudentAttendance(String uid, String studentId) {
    if (uid.isEmpty || studentId.isEmpty) return Stream.value([]);
    return _ref(uid)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceRecord.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> markSessionAttendanceBatch({
    required String uid,
    required String sessionId,
    required List<AttendanceRecord> records,
  }) async {
    final batch = _firestore.batch();

    // 1. Add/Update each attendance record document
    for (final record in records) {
      final docId = '${sessionId}_${record.studentId}';
      final docRef = _ref(uid).doc(docId);
      batch.set(docRef, record.copyWith(id: docId).toFirestore());
    }

    // 2. Update session attendanceMarked flag in sessions/{sessionId}
    final sessionRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId);

    batch.set(
      sessionRef,
      {
        'attendanceMarked': true,
        'markedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  @override
  Future<void> updateAttendanceRecord(String uid, AttendanceRecord record) async {
    final docId = record.id.isNotEmpty
        ? record.id
        : '${record.sessionId}_${record.studentId}';
    await _ref(uid).doc(docId).set(record.copyWith(id: docId).toFirestore());
  }
}
