import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/models/lesson_request.dart';
import '../../domain/models/tutor_profile.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return FirestoreMarketplaceRepository();
});

final currentTutorProfileProvider = StreamProvider<TutorProfile?>((ref) {
  try {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? '';
    if (uid.isEmpty) return Stream.value(null);
    return ref.watch(marketplaceRepositoryProvider).watchTutorProfile(uid);
  } catch (_) {
    return Stream.value(null);
  }
});

final tutorPrivateContactStreamProvider = StreamProvider.family<String?, String>((ref, tutorUid) {
  try {
    return ref.watch(marketplaceRepositoryProvider).watchTutorPrivateContact(tutorUid);
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

  const PublishedTutorsState({
    required this.tutors,
    required this.hasMore,
    required this.isLoadingInitial,
    required this.isLoadingMore,
    this.error,
  });

  PublishedTutorsState copyWith({
    List<TutorProfile>? tutors,
    bool? hasMore,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    String? error,
  }) {
    return PublishedTutorsState(
      tutors: tutors ?? this.tutors,
      hasMore: hasMore ?? this.hasMore,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

class PublishedTutorsNotifier extends StateNotifier<PublishedTutorsState> {
  final MarketplaceRepository _repository;

  PublishedTutorsNotifier(this._repository)
      : super(const PublishedTutorsState(
          tutors: [],
          hasMore: true,
          isLoadingInitial: true,
          isLoadingMore: false,
        )) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoadingInitial: true, error: null);
    try {
      final page = await _repository.fetchPublishedTutorsPageProfiles(limit: 20);
      state = PublishedTutorsState(
        tutors: page,
        hasMore: page.length >= 20,
        isLoadingInitial: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingInitial: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoadingInitial) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final lastUid = state.tutors.isNotEmpty ? state.tutors.last.uid : null;
      final newPage = await _repository.fetchPublishedTutorsPageProfiles(
        limit: 20,
        startAfterUid: lastUid,
      );

      final combined = [...state.tutors, ...newPage];
      state = state.copyWith(
        tutors: combined,
        hasMore: newPage.length >= 20,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
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
  try {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? '';
    if (uid.isEmpty) return Stream.value([]);
    return ref.watch(marketplaceRepositoryProvider).watchTutorRequests(uid);
  } catch (_) {
    return Stream.value([]);
  }
});

final learnerRequestsStreamProvider = StreamProvider<List<LessonRequest>>((ref) {
  try {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? '';
    if (uid.isEmpty) return Stream.value([]);
    return ref.watch(marketplaceRepositoryProvider).watchLearnerRequests(uid);
  } catch (_) {
    return Stream.value([]);
  }
});
