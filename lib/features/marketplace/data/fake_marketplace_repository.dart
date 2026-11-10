import 'dart:async';
import '../domain/models/lesson_request.dart';
import '../domain/models/tutor_profile.dart';
import 'marketplace_repository.dart';

class FakeMarketplaceRepository implements MarketplaceRepository {
  final Map<String, TutorProfile> _profiles = {};
  final Map<String, String> _privateContacts = {};
  final List<LessonRequest> _requests = [];

  final _tutorController = StreamController<List<TutorProfile>>.broadcast();
  final _requestController = StreamController<List<LessonRequest>>.broadcast();

  FakeMarketplaceRepository({
    List<TutorProfile>? initialProfiles,
    List<LessonRequest>? initialRequests,
  }) {
    if (initialProfiles != null) {
      for (final p in initialProfiles) {
        _profiles[p.uid] = p;
      }
    }
    if (initialRequests != null) _requests.addAll(initialRequests);
  }

  void _emitProfiles() {
    final published = _profiles.values.where((p) => p.isPublished).toList();
    _tutorController.add(List.unmodifiable(published));
  }

  void _emitRequests() {
    _requestController.add(List.unmodifiable(_requests));
  }

  @override
  Stream<TutorProfile?> watchTutorProfile(String uid) {
    scheduleMicrotask(() => _tutorController.add(List.unmodifiable(_profiles.values.toList())));
    return Stream.value(_profiles[uid]);
  }

  @override
  Future<void> saveTutorProfile(TutorProfile profile) async {
    _profiles[profile.uid] = profile;
    _emitProfiles();
  }

  @override
  Stream<String?> watchTutorPrivateContact(String tutorUid) {
    return Stream.value(_privateContacts[tutorUid]);
  }

  @override
  Future<void> saveTutorPrivateContact({required String uid, required String phone}) async {
    _privateContacts[uid] = phone;
  }

  @override
  Future<List<TutorProfile>> fetchPublishedTutorsPageProfiles({
    int limit = 20,
    String? startAfterUid,
  }) async {
    final published = _profiles.values.where((p) => p.isPublished).toList();
    published.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int startIndex = 0;
    if (startAfterUid != null && startAfterUid.isNotEmpty) {
      final index = published.indexWhere((p) => p.uid == startAfterUid);
      if (index != -1) {
        startIndex = index + 1;
      }
    }

    if (startIndex >= published.length) return [];
    final endIndex = (startIndex + limit).clamp(0, published.length);
    return published.sublist(startIndex, endIndex);
  }

  @override
  Stream<List<TutorProfile>> watchPublishedTutors({int limit = 20}) {
    scheduleMicrotask(_emitProfiles);
    return _tutorController.stream;
  }

  @override
  Future<void> createLessonRequest(LessonRequest request) async {
    final docId = request.id.isNotEmpty ? request.id : '${request.fromUid}_${request.toUid}';
    final updated = request.copyWith(id: docId, status: LessonRequestStatus.pending);
    final index = _requests.indexWhere((r) => r.id == docId);
    if (index != -1) {
      _requests[index] = updated;
    } else {
      _requests.add(updated);
    }
    _emitRequests();
  }

  @override
  Future<void> resendLessonRequestAfterCancel(LessonRequest request) async {
    final docId = request.id.isNotEmpty ? request.id : '${request.fromUid}_${request.toUid}';
    final index = _requests.indexWhere((r) => r.id == docId);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(
        subject: request.subject,
        message: request.message,
        status: LessonRequestStatus.pending,
        updatedAt: DateTime.now(),
      );
    } else {
      _requests.add(request.copyWith(id: docId, status: LessonRequestStatus.pending));
    }
    _emitRequests();
  }

  @override
  Stream<List<LessonRequest>> watchTutorRequests(String tutorUid) {
    scheduleMicrotask(() {
      final filtered = _requests.where((r) => r.toUid == tutorUid).toList();
      _requestController.add(List.unmodifiable(filtered));
    });
    return _requestController.stream;
  }

  @override
  Stream<List<LessonRequest>> watchLearnerRequests(String learnerUid) {
    scheduleMicrotask(() {
      final filtered = _requests.where((r) => r.fromUid == learnerUid).toList();
      _requestController.add(List.unmodifiable(filtered));
    });
    return _requestController.stream;
  }

  @override
  Future<void> updateRequestStatus({
    required String requestId,
    required LessonRequestStatus status,
  }) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(status: status, updatedAt: DateTime.now());
      _emitRequests();
    }
  }

  List<LessonRequest> getLearnerRequestsSync(String learnerUid) {
    return _requests.where((r) => r.fromUid == learnerUid).toList();
  }

  void dispose() {
    _tutorController.close();
    _requestController.close();
  }
}
