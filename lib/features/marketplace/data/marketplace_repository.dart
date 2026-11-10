import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/lesson_request.dart';
import '../domain/models/tutor_profile.dart';

abstract class MarketplaceRepository {
  Stream<TutorProfile?> watchTutorProfile(String uid);
  Future<void> saveTutorProfile(TutorProfile profile);

  Stream<String?> watchTutorPrivateContact(String tutorUid);
  Future<void> saveTutorPrivateContact({required String uid, required String phone});

  Future<List<TutorProfile>> fetchPublishedTutorsPageProfiles({
    int limit = 20,
    String? startAfterUid,
  });

  Stream<List<TutorProfile>> watchPublishedTutors({int limit = 20});

  Future<void> createLessonRequest(LessonRequest request);
  Future<void> resendLessonRequestAfterCancel(LessonRequest request);

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
    final docRef = _tutorsRef.doc(profile.uid);
    final docSnap = await docRef.get();

    final data = profile.toFirestore();
    if (docSnap.exists) {
      data.remove('createdAt'); // Preserve original createdAt timestamp
    }

    await docRef.set(data, SetOptions(merge: true));
  }

  @override
  Stream<String?> watchTutorPrivateContact(String tutorUid) {
    if (tutorUid.isEmpty) return Stream.value(null);
    return _tutorsRef
        .doc(tutorUid)
        .collection('private')
        .doc('contact')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return doc.data()!['phone'] as String?;
    });
  }

  @override
  Future<void> saveTutorPrivateContact({required String uid, required String phone}) async {
    await _tutorsRef
        .doc(uid)
        .collection('private')
        .doc('contact')
        .set({'phone': phone.trim(), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  @override
  Future<List<TutorProfile>> fetchPublishedTutorsPageProfiles({
    int limit = 20,
    String? startAfterUid,
  }) async {
    Query<Map<String, dynamic>> query = _tutorsRef
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfterUid != null && startAfterUid.isNotEmpty) {
      final docSnap = await _tutorsRef.doc(startAfterUid).get();
      if (docSnap.exists) {
        query = query.startAfterDocument(docSnap);
      }
    }

    final snap = await query.get();
    return snap.docs.map((doc) => TutorProfile.fromFirestore(doc)).toList();
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
  Future<void> createLessonRequest(LessonRequest request) async {
    final docId = '${request.fromUid}_${request.toUid}';
    await _requestsRef.doc(docId).set(
          request.copyWith(id: docId, status: LessonRequestStatus.pending).toFirestore(),
        );
  }

  @override
  Future<void> resendLessonRequestAfterCancel(LessonRequest request) async {
    final docId = '${request.fromUid}_${request.toUid}';
    await _requestsRef.doc(docId).set(
      {
        'subject': request.subject,
        'message': request.message,
        'status': LessonRequestStatus.pending.name,
        'updatedAt': FieldValue.serverTimestamp(),
      },
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
