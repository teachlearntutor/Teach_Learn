import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/core/utils/contact_utils.dart';
import 'package:teach_learn/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:teach_learn/features/marketplace/domain/models/lesson_request.dart';
import 'package:teach_learn/features/marketplace/domain/models/tutor_profile.dart';
import 'package:teach_learn/features/marketplace/domain/tutor_filter.dart';
import 'package:teach_learn/features/marketplace/presentation/providers/marketplace_providers.dart';

void main() {
  group('Marketplace Pure Tutor Filtering & Sorting Tests', () {
    final now = DateTime.now();

    final tutor1 = TutorProfile(
      uid: 't1',
      displayName: 'Malik Azmat',
      publicId: 'TL-1',
      headline: 'Math & Physics Specialist',
      bio: 'Tutor bio 1',
      subjects: const ['Mathematics', 'Physics'],
      levels: const ['Class 9', 'Class 10'],
      city: 'Lahore Cantt',
      area: 'DHA Phase 5',
      mode: 'home',
      experienceYears: 5,
      availableDays: const ['Mon', 'Wed'],
      isPublished: true,
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now,
    );

    final tutor2 = TutorProfile(
      uid: 't2',
      displayName: 'Zainab Ahmed',
      publicId: 'TL-2',
      headline: 'Chemistry Master',
      bio: 'Tutor bio 2',
      subjects: const ['Chemistry'],
      levels: const ['Class 11', 'A Levels'],
      city: 'Karachi South',
      area: 'Clifton',
      mode: 'online',
      experienceYears: 10,
      availableDays: const ['Tue', 'Thu'],
      isPublished: true,
      createdAt: now,
      updatedAt: now,
    );

    test('filterTutors city contains search', () {
      final res = filterTutors(
        tutors: [tutor1, tutor2],
        subjectQuery: '',
        cityQuery: 'Lahore',
        modeFilter: 'All',
        levelFilter: 'All',
        selectedSubjectChip: null,
        minExperience: 0,
      );

      expect(res.length, equals(1));
      expect(res.first.uid, equals('t1'));
    });

    test('filterTutors mode, level, and min experience filters', () {
      final res = filterTutors(
        tutors: [tutor1, tutor2],
        subjectQuery: '',
        cityQuery: '',
        modeFilter: 'Online',
        levelFilter: 'A Levels',
        selectedSubjectChip: null,
        minExperience: 8,
      );

      expect(res.length, equals(1));
      expect(res.first.uid, equals('t2'));
    });

    test('filterTutors subject, headline, and name search', () {
      final res1 = filterTutors(
        tutors: [tutor1, tutor2],
        subjectQuery: 'physics',
        cityQuery: '',
        modeFilter: 'All',
        levelFilter: 'All',
        selectedSubjectChip: null,
        minExperience: 0,
      );
      expect(res1.length, equals(1));
      expect(res1.first.uid, equals('t1'));

      final res2 = filterTutors(
        tutors: [tutor1, tutor2],
        subjectQuery: 'zainab',
        cityQuery: '',
        modeFilter: 'All',
        levelFilter: 'All',
        selectedSubjectChip: null,
        minExperience: 0,
      );
      expect(res2.length, equals(1));
      expect(res2.first.uid, equals('t2'));
    });

    test('filterTutors returns empty list when no match', () {
      final res = filterTutors(
        tutors: [tutor1, tutor2],
        subjectQuery: 'NonExistentSubject',
        cityQuery: '',
        modeFilter: 'All',
        levelFilter: 'All',
        selectedSubjectChip: null,
        minExperience: 0,
      );
      expect(res.isEmpty, equals(true));
    });

    test('sortTutors sorts by newest vs most experienced', () {
      final byExp = sortTutors(
        tutors: [tutor1, tutor2],
        sortOption: TutorSortOption.mostExperienced,
      );
      expect(byExp.first.uid, equals('t2'));

      final byNewest = sortTutors(
        tutors: [tutor1, tutor2],
        sortOption: TutorSortOption.newest,
      );
      expect(byNewest.first.uid, equals('t2'));
    });

    test('tutorRequestUiState returns pure enum states', () {
      expect(tutorRequestUiState(null), equals(TutorRequestUiState.none));

      final req = LessonRequest(
        id: 'r1',
        fromUid: 'u1',
        toUid: 'u2',
        fromName: 'Name',
        subject: 'Math',
        message: 'Msg',
        status: LessonRequestStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      expect(tutorRequestUiState(req), equals(TutorRequestUiState.pending));

      expect(
        tutorRequestUiState(req.copyWith(status: LessonRequestStatus.accepted)),
        equals(TutorRequestUiState.accepted),
      );

      expect(
        tutorRequestUiState(req.copyWith(status: LessonRequestStatus.declined)),
        equals(TutorRequestUiState.declined),
      );

      expect(
        tutorRequestUiState(req.copyWith(status: LessonRequestStatus.cancelled)),
        equals(TutorRequestUiState.cancelled),
      );
    });

    test('Pagination Notifier with FakeRepository (45 tutors -> 3 pages)', () async {
      final tutors = List.generate(
        45,
        (i) => TutorProfile(
          uid: 'tutor_$i',
          displayName: 'Tutor $i',
          publicId: 'TL-$i',
          headline: 'Headline $i',
          bio: 'Bio $i',
          subjects: const ['Math'],
          levels: const ['Class 9'],
          city: 'Lahore',
          area: 'Area $i',
          mode: 'both',
          experienceYears: 2,
          availableDays: const ['Mon'],
          isPublished: true,
          createdAt: now.add(Duration(minutes: i)),
          updatedAt: now,
        ),
      );

      final fakeRepo = FakeMarketplaceRepository(initialProfiles: tutors);
      final notifier = PublishedTutorsNotifier(fakeRepo);

      // Initial page load -> 20 tutors
      await notifier.loadInitial();

      expect(notifier.currentState.tutors.length, equals(20));
      expect(notifier.currentState.hasMore, equals(true));

      // Page 2 load -> +20 = 40 tutors
      await notifier.loadMore();
      expect(notifier.currentState.tutors.length, equals(40));
      expect(notifier.currentState.hasMore, equals(true));

      // Page 3 load -> +5 = 45 tutors (hasMore becomes false)
      await notifier.loadMore();
      expect(notifier.currentState.tutors.length, equals(45));
      expect(notifier.currentState.hasMore, equals(false));
    });

    test('Pakistani phone number normalization (+923xx)', () {
      expect(normalizePakistaniPhoneNumber('0301-555-0101'), equals('+923015550101'));
      expect(normalizePakistaniPhoneNumber('0300 1234567'), equals('+923001234567'));
    });
  });
}

extension _NotifierTest on PublishedTutorsNotifier {
  PublishedTutorsState get currentState => state;
}
