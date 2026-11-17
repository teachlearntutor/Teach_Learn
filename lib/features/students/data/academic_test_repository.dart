import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/academic_test.dart';

abstract class AcademicTestRepository {
  Stream<List<AcademicTest>> watchAcademicTests(String uid, String studentId);
  Future<void> saveAcademicTest(String uid, String studentId, AcademicTest test);
  Future<void> deleteAcademicTest(String uid, String studentId, String testId);
}

class FirestoreAcademicTestRepository implements AcademicTestRepository {
  final FirebaseFirestore _firestore;

  FirestoreAcademicTestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _testsRef(String uid, String studentId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('students')
        .doc(studentId)
        .collection('tests');
  }

  @override
  Stream<List<AcademicTest>> watchAcademicTests(String uid, String studentId) {
    if (uid.isEmpty || studentId.isEmpty) return Stream.value([]);
    return _testsRef(uid, studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AcademicTest.fromFirestore(doc)).toList());
  }

  @override
  Future<void> saveAcademicTest(String uid, String studentId, AcademicTest test) async {
    if (uid.isEmpty || studentId.isEmpty) return;
    final docRef = test.id.isNotEmpty
        ? _testsRef(uid, studentId).doc(test.id)
        : _testsRef(uid, studentId).doc();

    final testWithId = test.copyWith(id: docRef.id);
    await docRef.set(testWithId.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteAcademicTest(String uid, String studentId, String testId) async {
    if (uid.isEmpty || studentId.isEmpty || testId.isEmpty) return;
    await _testsRef(uid, studentId).doc(testId).delete();
  }
}
