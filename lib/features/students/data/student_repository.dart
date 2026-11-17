import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/student.dart';

abstract class StudentRepository {
  Stream<List<Student>> watchStudents(String uid, {int limit = 50});
  Stream<List<Student>> watchActiveStudents(String uid);
  Future<List<Student>> fetchStudentsPage(
    String uid, {
    int limit = 50,
    String? startAfterId,
  });
  Future<void> addStudent(String uid, Student student);
  Future<void> updateStudent(String uid, Student student);
  Future<void> deleteStudent(String uid, String studentId);
}

class FirestoreStudentRepository implements StudentRepository {
  final FirebaseFirestore _firestore;

  FirestoreStudentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _ref(String uid) {
    return _firestore.collection('users').doc(uid).collection('students');
  }

  @override
  Stream<List<Student>> watchStudents(String uid, {int limit = 50}) {
    if (uid.isEmpty) return Stream.value([]);
    return _ref(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Student.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Stream<List<Student>> watchActiveStudents(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _ref(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Student.fromFirestore(doc))
          .where((student) => student.status == StudentStatus.active)
          .toList();
    });
  }

  @override
  Future<List<Student>> fetchStudentsPage(
    String uid, {
    int limit = 50,
    String? startAfterId,
  }) async {
    if (uid.isEmpty) return [];

    Query<Map<String, dynamic>> query = _ref(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfterId != null && startAfterId.isNotEmpty) {
      final docSnap = await _ref(uid).doc(startAfterId).get();
      if (docSnap.exists) {
        query = query.startAfterDocument(docSnap);
      }
    }

    final snap = await query.get();
    return snap.docs.map((doc) => Student.fromFirestore(doc)).toList();
  }

  @override
  Future<void> addStudent(String uid, Student student) async {
    final docRef = student.id.isNotEmpty
        ? _ref(uid).doc(student.id)
        : _ref(uid).doc();

    final newStudent = student.copyWith(
      id: docRef.id,
      searchName: student.name.toLowerCase().trim(),
    );

    await docRef.set(newStudent.toFirestore());
  }

  @override
  Future<void> updateStudent(String uid, Student student) async {
    final updatedStudent = student.copyWith(
      searchName: student.name.toLowerCase().trim(),
      updatedAt: DateTime.now(),
    );
    await _ref(uid)
        .doc(student.id)
        .set(updatedStudent.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteStudent(String uid, String studentId) async {
    final studentRef = _ref(uid).doc(studentId);

    // Delete nested test documents before deleting the student document.
    final testsSnap = await studentRef.collection('tests').get();
    await _deleteDocumentsInChunks(testsSnap.docs);

    // Fetch all attendance documents for this student.
    final attendanceSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .get();

    await _deleteDocumentsInChunks(attendanceSnap.docs);

    await studentRef.delete();
  }

  Future<void> _deleteDocumentsInChunks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    const chunkSize = 400;
    for (var i = 0; i < docs.length; i += chunkSize) {
      final batch = _firestore.batch();
      final chunk = docs.sublist(i, (i + chunkSize).clamp(0, docs.length));
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
