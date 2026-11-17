import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/features/auth/data/auth_repository.dart';
import 'package:teach_learn/features/auth/presentation/providers/auth_providers.dart';
import 'package:teach_learn/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:teach_learn/features/marketplace/domain/models/tutor_profile.dart';
import 'package:teach_learn/features/marketplace/domain/tutor_filter.dart';
import 'package:teach_learn/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:teach_learn/features/marketplace/presentation/screens/find_tutor_screen.dart';

void main() {
  final now = DateTime(2026, 11, 14);
  final nearbyTutor = TutorProfile(
    uid: 'tutor-islamabad',
    displayName: 'Ayesha Khan',
    publicId: 'TL-10001',
    headline: 'Math and science tutor',
    bio: 'Experienced home tutor',
    subjects: const ['Mathematics', 'Physics'],
    levels: const ['Class 9', 'Class 10'],
    city: 'Islamabad',
    area: 'Sector G-7/2',
    mode: 'home',
    experienceYears: 6,
    availableDays: const ['Mon', 'Wed'],
    isPublished: true,
    createdAt: now,
    updatedAt: now,
  );
  final otherTutor = TutorProfile(
    uid: 'tutor-karachi',
    displayName: 'Omar Ali',
    publicId: 'TL-10002',
    headline: 'English tutor',
    bio: 'Online lessons',
    subjects: const ['English'],
    levels: const ['O Levels'],
    city: 'Karachi',
    area: 'Clifton',
    mode: 'online',
    experienceYears: 3,
    availableDays: const ['Tue'],
    isPublished: true,
    createdAt: now.subtract(const Duration(days: 1)),
    updatedAt: now,
  );

  test(
    'real tutor filter matches city case-insensitively and soft-matches areas',
    () {
      final results = filterTutors(
        tutors: [nearbyTutor, otherTutor],
        searchQuery: '',
        cityFilter: 'islamabad',
        areaFilter: 'g7',
        modeFilter: 'All',
        levelFilter: 'All',
        subjectFilter: '',
      );

      expect(results.map((tutor) => tutor.uid).toList(), ['tutor-islamabad']);
    },
  );

  test('no applied filters keeps all published tutors visible', () {
    final results = filterTutors(
      tutors: [nearbyTutor, otherTutor],
      searchQuery: '',
      cityFilter: 'All',
      areaFilter: '',
      modeFilter: 'All',
      levelFilter: 'All',
      subjectFilter: '',
    );

    expect(results.map((tutor) => tutor.uid).toList(), [
      'tutor-islamabad',
      'tutor-karachi',
    ]);
  });

  test(
    'published tutor notifier exposes fetch failures for UI retry state',
    () async {
      final repository = _FailingMarketplaceRepository();
      final notifier = PublishedTutorsNotifier(repository);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isLoadingInitial, isFalse);
      expect(notifier.state.tutors, isEmpty);
      expect(notifier.state.error, contains('Firestore unavailable'));

      await notifier.loadInitial();
      expect(repository.attempts, greaterThanOrEqualTo(2));
      expect(notifier.state.error, contains('Firestore unavailable'));

      notifier.dispose();
      repository.dispose();
    },
  );

  testWidgets('shows the 100 tutor fetch limit note immediately', (
    tester,
  ) async {
    final repository = FakeMarketplaceRepository(
      initialProfiles: List.generate(
        100,
        (index) => nearbyTutor.copyWith(
          uid: 'tutor-$index',
          displayName: 'Tutor $index',
          publicId: 'TL-${index.toString().padLeft(5, '0')}',
        ),
      ),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketplaceRepositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(
            _UnauthenticatedAuthRepository(),
          ),
        ],
        child: const MaterialApp(home: FindTutorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Showing first 100 tutors. Use filters to narrow.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Find Tutor renders fetch errors and retries instead of empty results',
    (tester) async {
      final repository = _FailingMarketplaceRepository();
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marketplaceRepositoryProvider.overrideWithValue(repository),
            authRepositoryProvider.overrideWithValue(
              _UnauthenticatedAuthRepository(),
            ),
          ],
          child: const MaterialApp(home: FindTutorScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tutors Unavailable'), findsOneWidget);
      expect(find.textContaining('Firestore unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('No tutors yet'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repository.attempts, greaterThanOrEqualTo(2));
      expect(find.text('Tutors Unavailable'), findsOneWidget);
    },
  );
}

class _UnauthenticatedAuthRepository extends Fake implements AuthRepository {
  @override
  User? get currentUser => null;
}

class _FailingMarketplaceRepository extends FakeMarketplaceRepository {
  int attempts = 0;

  @override
  Future<List<TutorProfile>> fetchPublishedTutors({int limit = 100}) async {
    attempts++;
    throw StateError('Firestore unavailable');
  }
}
