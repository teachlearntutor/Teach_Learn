import 'dart:async';
import '../domain/models/lesson_request.dart';
import '../domain/models/tutor_profile.dart';
import 'marketplace_repository.dart';

class FakeMarketplaceRepository implements MarketplaceRepository {
  final Map<String, TutorProfile> _profiles = {};
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
  Stream<List<TutorProfile>> watchPublishedTutors({int limit = 20}) {
    scheduleMicrotask(_emitProfiles);
    return _tutorController.stream;
  }

  @override
  Future<void> sendLessonRequest(LessonRequest request) async {
    final docId = '${request.fromUid}_${request.toUid}';
    final updated = request.copyWith(id: docId);
    final index = _requests.indexWhere((r) => r.id == docId);
    if (index != -1) {
      _requests[index] = updated;
    } else {
      _requests.add(updated);
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

  void dispose() {
    _tutorController.close();
    _requestController.close();
  }
}
