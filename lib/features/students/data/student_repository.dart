import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/student.dart';

abstract class StudentRepository {
  Stream<List<Student>> watchStudents(String uid);
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
  Stream<List<Student>> watchStudents(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _ref(uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Student.fromFirestore(doc))
          .toList();
    });
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
    await _ref(uid).doc(student.id).set(updatedStudent.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteStudent(String uid, String studentId) async {
    final batch = _firestore.batch();

    // 1. Delete student document
    batch.delete(_ref(uid).doc(studentId));

    // 2. Query and batch delete student's attendance records
    final attendanceSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .get();

    for (final doc in attendanceSnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
