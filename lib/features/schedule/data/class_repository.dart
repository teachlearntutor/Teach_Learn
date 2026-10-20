import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/weekly_class.dart';

abstract class ClassRepository {
  Stream<List<WeeklyClass>> watchClasses(String uid);
  Future<void> addClass(String uid, WeeklyClass weeklyClass);
  Future<void> updateClass(String uid, WeeklyClass weeklyClass);
  Future<void> deleteClass(String uid, String classId);
}

class FirestoreClassRepository implements ClassRepository {
  final FirebaseFirestore _firestore;

  FirestoreClassRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _classRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('classes');
  }

  @override
  Stream<List<WeeklyClass>> watchClasses(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _classRef(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => WeeklyClass.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> addClass(String uid, WeeklyClass weeklyClass) async {
    final docRef = weeklyClass.id.isNotEmpty
        ? _classRef(uid).doc(weeklyClass.id)
        : _classRef(uid).doc();
    await docRef.set(weeklyClass.copyWith(id: docRef.id).toFirestore());
  }

  @override
  Future<void> updateClass(String uid, WeeklyClass weeklyClass) async {
    await _classRef(uid).doc(weeklyClass.id).update(weeklyClass.toFirestore());
  }

  @override
  Future<void> deleteClass(String uid, String classId) async {
    await _classRef(uid).doc(classId).delete();
  }
}
