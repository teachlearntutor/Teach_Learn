import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/lesson_request.dart';
import '../domain/models/tutor_profile.dart';

abstract class MarketplaceRepository {
  Stream<TutorProfile?> watchTutorProfile(String uid);
  Future<void> saveTutorProfile(TutorProfile profile);
  Stream<List<TutorProfile>> watchPublishedTutors({int limit = 20});
  Future<void> sendLessonRequest(LessonRequest request);
  Stream<List<LessonRequest>> watchTutorRequests(String tutorUid);
  Stream<List<LessonRequest>> watchLearnerRequests(String learnerUid);
  Future<void> updateRequestStatus({
    required String requestId,
    required LessonRequestStatus status,
  });
}

class FirestoreMarketplaceRepository implements MarketplaceRepository {
  final FirebaseFirestore _firestore;

  FirestoreMarketplaceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tutorsRef =>
      _firestore.collection('tutorProfiles');

  CollectionReference<Map<String, dynamic>> get _requestsRef =>
      _firestore.collection('lessonRequests');

  @override
  Stream<TutorProfile?> watchTutorProfile(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _tutorsRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TutorProfile.fromFirestore(doc);
    });
  }

  @override
  Future<void> saveTutorProfile(TutorProfile profile) async {
    await _tutorsRef.doc(profile.uid).set(
          profile.toFirestore(),
          SetOptions(merge: true),
        );
  }

  @override
  Stream<List<TutorProfile>> watchPublishedTutors({int limit = 20}) {
    return _tutorsRef
        .where('isPublished', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TutorProfile.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> sendLessonRequest(LessonRequest request) async {
    final docId = '${request.fromUid}_${request.toUid}';
    await _requestsRef.doc(docId).set(
          request.copyWith(id: docId).toFirestore(),
          SetOptions(merge: true),
        );
  }

  @override
  Stream<List<LessonRequest>> watchTutorRequests(String tutorUid) {
    if (tutorUid.isEmpty) return Stream.value([]);
    return _requestsRef
        .where('toUid', isEqualTo: tutorUid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LessonRequest.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Stream<List<LessonRequest>> watchLearnerRequests(String learnerUid) {
    if (learnerUid.isEmpty) return Stream.value([]);
    return _requestsRef
        .where('fromUid', isEqualTo: learnerUid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LessonRequest.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> updateRequestStatus({
    required String requestId,
    required LessonRequestStatus status,
  }) async {
    await _requestsRef.doc(requestId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
