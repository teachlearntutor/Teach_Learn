import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/models/lesson_request.dart';
import '../../domain/models/tutor_profile.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return FirestoreMarketplaceRepository();
});

final currentTutorProfileProvider = StreamProvider<TutorProfile?>((ref) {
  final user = ref.watch(currentAuthUserProvider);
  final uid = user?.uid ?? '';
  if (uid.isEmpty) return Stream.value(null);
  return ref.watch(marketplaceRepositoryProvider).watchTutorProfile(uid);
});

final tutorProfileByUidProvider = StreamProvider.family<TutorProfile?, String>((
  ref,
  uid,
) {
  ref.watch(currentAuthUserProvider);
  if (uid.isEmpty) return Stream.value(null);
  return ref.watch(marketplaceRepositoryProvider).watchTutorProfile(uid);
});

final tutorPrivateContactStreamProvider =
    StreamProvider.family<String?, String>((ref, tutorUid) {
      ref.watch(currentAuthUserProvider);
      try {
        return ref
            .watch(marketplaceRepositoryProvider)
            .watchTutorPrivateContact(tutorUid);
      } catch (_) {
        return Stream.value(null);
      }
    });

class PublishedTutorsState {
  final List<TutorProfile> tutors;
  final bool hasMore;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? error;
  final int totalFetched;

  const PublishedTutorsState({
    required this.tutors,
    required this.hasMore,
    required this.isLoadingInitial,
    required this.isLoadingMore,
    this.error,
    this.totalFetched = 0,
  });

  PublishedTutorsState copyWith({
    List<TutorProfile>? tutors,
    bool? hasMore,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    String? error,
    int? totalFetched,
  }) {
    return PublishedTutorsState(
      tutors: tutors ?? this.tutors,
      hasMore: hasMore ?? this.hasMore,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      totalFetched: totalFetched ?? this.totalFetched,
    );
  }
}

class PublishedTutorsNotifier extends StateNotifier<PublishedTutorsState> {
  final MarketplaceRepository _repository;
  List<TutorProfile> _allTutors = [];
  int _visibleCount = 0;

  PublishedTutorsNotifier(this._repository)
    : super(
        const PublishedTutorsState(
          tutors: [],
          hasMore: true,
          isLoadingInitial: true,
          isLoadingMore: false,
        ),
      ) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoadingInitial: true, error: null);
    try {
      _allTutors = await _repository.fetchPublishedTutors(limit: 100);
      _visibleCount = _allTutors.length < 20 ? _allTutors.length : 20;
      state = PublishedTutorsState(
        tutors: _allTutors.take(_visibleCount).toList(),
        hasMore: _visibleCount < _allTutors.length,
        isLoadingInitial: false,
        isLoadingMore: false,
        totalFetched: _allTutors.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingInitial: false,
        error: e.toString(),
        totalFetched: 0,
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoadingInitial) return;

    state = state.copyWith(isLoadingMore: true);
    _visibleCount = (_visibleCount + 20).clamp(0, _allTutors.length).toInt();
    state = state.copyWith(
      tutors: _allTutors.take(_visibleCount).toList(),
      hasMore: _visibleCount < _allTutors.length,
      isLoadingMore: false,
    );
  }
}

final publishedTutorsNotifierProvider =
    StateNotifierProvider<PublishedTutorsNotifier, PublishedTutorsState>((ref) {
      return PublishedTutorsNotifier(ref.watch(marketplaceRepositoryProvider));
    });

final publishedTutorsStreamProvider = StreamProvider<List<TutorProfile>>((ref) {
  try {
    return ref.watch(marketplaceRepositoryProvider).watchPublishedTutors();
  } catch (_) {
    return Stream.value([]);
  }
});

final tutorRequestsStreamProvider = StreamProvider<List<LessonRequest>>((ref) {
  final user = ref.watch(currentAuthUserProvider);
  final uid = user?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(marketplaceRepositoryProvider).watchTutorRequests(uid);
});

final learnerRequestsStreamProvider = StreamProvider<List<LessonRequest>>((
  ref,
) {
  final user = ref.watch(currentAuthUserProvider);
  final uid = user?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(marketplaceRepositoryProvider).watchLearnerRequests(uid);
});
