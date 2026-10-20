import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/class_session.dart';
import '../domain/models/holiday.dart';

abstract class SessionRepository {
  Stream<List<ClassSession>> watchSessions(String uid);
  Stream<List<Holiday>> watchHolidays(String uid);
  Future<void> saveSessionOverride(String uid, ClassSession session);
  Future<void> deleteSessionOverride(String uid, String sessionId);
  Future<void> addHoliday(String uid, Holiday holiday);
  Future<void> deleteHoliday(String uid, String holidayId);
}

class FirestoreSessionRepository implements SessionRepository {
  final FirebaseFirestore _firestore;

  FirestoreSessionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessionRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('sessions');
  }

  CollectionReference<Map<String, dynamic>> _holidayRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('holidays');
  }

  @override
  Stream<List<ClassSession>> watchSessions(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _sessionRef(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ClassSession.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Stream<List<Holiday>> watchHolidays(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _holidayRef(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Holiday.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> saveSessionOverride(String uid, ClassSession session) async {
    final docRef = session.id.isNotEmpty
        ? _sessionRef(uid).doc(session.id)
        : _sessionRef(uid).doc();
    await docRef.set(session.copyWith(id: docRef.id).toFirestore());
  }

  @override
  Future<void> deleteSessionOverride(String uid, String sessionId) async {
    await _sessionRef(uid).doc(sessionId).delete();
  }

  @override
  Future<void> addHoliday(String uid, Holiday holiday) async {
    final docRef = holiday.id.isNotEmpty
        ? _holidayRef(uid).doc(holiday.id)
        : _holidayRef(uid).doc();
    await docRef.set(Holiday(id: docRef.id, date: holiday.date, reason: holiday.reason).toFirestore());
  }

  @override
  Future<void> deleteHoliday(String uid, String holidayId) async {
    await _holidayRef(uid).doc(holidayId).delete();
  }
}
