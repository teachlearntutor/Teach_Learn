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
