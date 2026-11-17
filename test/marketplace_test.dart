import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/core/utils/contact_utils.dart';
import 'package:teach_learn/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:teach_learn/features/marketplace/domain/models/lesson_request.dart';
import 'package:teach_learn/features/marketplace/domain/models/tutor_profile.dart';
import 'package:teach_learn/features/marketplace/domain/tutor_filter.dart';
import 'package:teach_learn/features/marketplace/domain/tutor_location.dart';
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
        searchQuery: '',
        cityFilter: 'Lahore',
        areaFilter: '',
        modeFilter: 'All',
        levelFilter: 'All',
        subjectFilter: '',
      );

      expect(res.length, equals(1));
      expect(res.first.uid, equals('t1'));
    });

    test('filterTutors mode, level, and area filters', () {
      final res = filterTutors(
        tutors: [tutor1, tutor2],
        searchQuery: '',
        cityFilter: '',
        areaFilter: 'Clifton',
        modeFilter: 'Online',
        levelFilter: 'A Levels',
        subjectFilter: '',
      );

      expect(res.length, equals(1));
      expect(res.first.uid, equals('t2'));
    });

    test('filterTutors subject, headline, name, and publicId search', () {
      final res1 = filterTutors(
        tutors: [tutor1, tutor2],
        searchQuery: 'physics',
        cityFilter: '',
        areaFilter: '',
        modeFilter: 'All',
        levelFilter: 'All',
        subjectFilter: '',
      );
      expect(res1.length, equals(1));
      expect(res1.first.uid, equals('t1'));

      final res2 = filterTutors(
        tutors: [tutor1, tutor2],
        searchQuery: 'zainab',
        cityFilter: '',
        areaFilter: '',
        modeFilter: 'All',
        levelFilter: 'All',
        subjectFilter: '',
      );
      expect(res2.length, equals(1));
      expect(res2.first.uid, equals('t2'));
    });

    test('filterTutors returns empty list when no match', () {
      final res = filterTutors(
        tutors: [tutor1, tutor2],
        searchQuery: 'NonExistentSubject',
        cityFilter: '',
        areaFilter: '',
        modeFilter: 'All',
        levelFilter: 'All',
        subjectFilter: '',
      );
      expect(res.isEmpty, equals(true));
    });

    test('both-mode tutors match Home and Online filters', () {
      final tutorBoth = tutor1.copyWith(uid: 't3', mode: 'both');

      final homeResults = filterTutors(
        tutors: [tutor1, tutor2, tutorBoth],
        searchQuery: '',
        cityFilter: '',
        areaFilter: '',
        modeFilter: 'Home',
        levelFilter: 'All',
        subjectFilter: '',
      );
      final onlineResults = filterTutors(
        tutors: [tutor1, tutor2, tutorBoth],
        searchQuery: '',
        cityFilter: '',
        areaFilter: '',
        modeFilter: 'Online',
        levelFilter: 'All',
        subjectFilter: '',
      );

      expect(homeResults.map((tutor) => tutor.uid), containsAll(['t1', 't3']));
      expect(onlineResults.map((tutor) => tutor.uid), containsAll(['t2', 't3']));
    });

    test('multi-class and grouped subject filters match saved tutor values', () {
      final results = filterTutors(
        tutors: [tutor1, tutor2],
        searchQuery: '',
        cityFilter: '',
        areaFilter: '',
        modeFilter: 'All',
        levelFilter: 'All',
        subjectFilter: '',
        levelFilters: {'Class 9'},
        subjectFilters: {'Math'},
      );

      expect(results.map((tutor) => tutor.uid), ['t1']);
    });

    test('sector variants normalize and filter as one parent sector', () {
      for (final variant in [
        'G-7',
        'g7',
        'G 7',
        'G-7/1',
        'G-7/2',
        'G7-3',
        'G-7 Markaz',
      ]) {
        expect(normalizeSector(variant), 'g7');
      }
      expect(normalizeSector('F-10/3'), 'f10');
      expect(normalizeSector('I-8/4'), 'i8');
      expect(normalizeSector('DHA Phase 2'), 'dha phase 2');

      final tutorG7Subsector = tutor1.copyWith(
        city: 'Islamabad',
        area: 'G-7/4',
      );
      final tutorG8 = tutor1.copyWith(city: 'Islamabad', area: 'G-8');
      final results = filterTutors(
        tutors: [tutorG7Subsector, tutorG8],
        searchQuery: '',
        cityFilter: 'All',
        areaFilter: 'G-7/1',
        modeFilter: 'All',
        levelFilter: 'All',
        subjectFilter: '',
      );

      expect(results.map((tutor) => tutor.area), ['G-7/4']);
    });

    test('GPS radius uses Haversine distance and retains unlocated tutors', () {
      final islamabadG7 = tutor1.copyWith(
        city: 'Islamabad',
        area: 'G-7/1',
        lat: 33.716,
        lng: 73.055,
      );
      final islamabadG8 = tutor1.copyWith(
        uid: 'g8',
        city: 'Islamabad',
        area: 'G-8',
        lat: 33.704,
        lng: 73.056,
      );
      final karachi = tutor2.copyWith(lat: 24.8607, lng: 67.0011);
      final unlocated = tutor2.copyWith(
        uid: 'unlocated',
        clearCoordinates: true,
      );
      const studentLocation = GeoCoordinates(
        latitude: 33.716,
        longitude: 73.055,
      );

      final g7ToG8 = distanceBetweenKm(
        studentLocation,
        GeoCoordinates(latitude: islamabadG8.lat!, longitude: islamabadG8.lng!),
      );
      final toKarachi = distanceBetweenKm(
        studentLocation,
        GeoCoordinates(latitude: karachi.lat!, longitude: karachi.lng!),
      );
      expect(g7ToG8, inInclusiveRange(1, 2));
      expect(toKarachi, greaterThan(1100));

      final results = filterTutors(
        tutors: [islamabadG7, islamabadG8, karachi, unlocated],
        searchQuery: '',
        cityFilter: 'All',
        areaFilter: '',
        modeFilter: 'All',
        levelFilter: 'All',
        subjectFilter: '',
        currentLocation: studentLocation,
        radiusKm: 3,
      );
      expect(results.map((tutor) => tutor.uid), ['t1', 'g8', 'unlocated']);
    });

    test('tutor profile coordinates serialize as numbers', () {
      final located = tutor1.copyWith(lat: 33.71, lng: 73.06);
      final serialized = located.toFirestore();
      expect(serialized['lat'], isA<double>());
      expect(serialized['lng'], isA<double>());
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
        tutorRequestUiState(
          req.copyWith(status: LessonRequestStatus.cancelled),
        ),
        equals(TutorRequestUiState.cancelled),
      );
    });

    test(
      'Pagination Notifier with FakeRepository (45 tutors -> 3 pages)',
      () async {
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
      },
    );

    test('Pakistani phone number normalization (+923xx)', () {
      expect(
        normalizePakistaniPhoneNumber('0301-555-0101'),
        equals('+923015550101'),
      );
      expect(
        normalizePakistaniPhoneNumber('0300 1234567'),
        equals('+923001234567'),
      );
    });
  });
}

extension _NotifierTest on PublishedTutorsNotifier {
  PublishedTutorsState get currentState => state;
}
