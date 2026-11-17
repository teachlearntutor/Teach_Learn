import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/features/learner/domain/models/learner_preferences.dart';
import 'package:teach_learn/features/marketplace/domain/models/tutor_profile.dart';
import 'package:teach_learn/features/marketplace/domain/tutor_location.dart';
import 'package:teach_learn/features/marketplace/domain/tutor_recommendations.dart';

void main() {
  group('Learner Preferences & Tutor Recommendations Pure Logic Tests', () {
    final now = DateTime.now();

    final tutorLahoreDHA = TutorProfile(
      uid: 't_lahore_dha',
      displayName: 'Tutor Lahore DHA',
      publicId: 'TL-1',
      headline: 'O Level Math Specialist',
      bio: 'Bio text',
      subjects: const ['Mathematics', 'Physics'],
      levels: const ['Class 9', 'O Levels'],
      city: 'Lahore',
      area: 'DHA Phase 5',
      mode: 'home',
      experienceYears: 5,
      availableDays: const ['Mon'],
      isPublished: true,
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now,
    );

    final tutorLahoreGulberg = TutorProfile(
      uid: 't_lahore_gulberg',
      displayName: 'Tutor Lahore Gulberg',
      publicId: 'TL-2',
      headline: 'Math & Chemistry Tutor',
      bio: 'Bio text',
      subjects: const ['Mathematics', 'Chemistry'],
      levels: const ['Class 9', 'Class 10'],
      city: 'Lahore',
      area: 'Gulberg III',
      mode: 'online',
      experienceYears: 4,
      availableDays: const ['Tue'],
      isPublished: true,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );

    final tutorKarachi = TutorProfile(
      uid: 't_karachi',
      displayName: 'Tutor Karachi',
      publicId: 'TL-3',
      headline: 'Class 9 Math Specialist',
      bio: 'Bio text',
      subjects: const ['Mathematics'],
      levels: const ['Class 9'],
      city: 'Karachi',
      area: 'Clifton',
      mode: 'both',
      experienceYears: 6,
      availableDays: const ['Wed'],
      isPublished: true,
      createdAt: now,
      updatedAt: now,
    );

    final tutorClass10Only = TutorProfile(
      uid: 't_class10',
      displayName: 'Tutor Class 10',
      publicId: 'TL-4',
      headline: 'A Level Specialist',
      bio: 'Bio text',
      subjects: const ['Biology'],
      levels: const ['A Levels'],
      city: 'Lahore',
      area: 'DHA Phase 5',
      mode: 'both',
      experienceYears: 8,
      availableDays: const ['Thu'],
      isPublished: true,
      createdAt: now,
      updatedAt: now,
    );

    test('LearnerPreferences validation and serialization', () {
      const emptyPrefs = LearnerPreferences(
        classLevel: '',
        neededSubjects: [],
        city: '',
        area: '',
        preferredMode: 'both',
      );
      expect(emptyPrefs.isComplete, isFalse);

      const validPrefs = LearnerPreferences(
        classLevel: 'Class 9',
        neededSubjects: ['Mathematics'],
        city: 'Lahore',
        area: 'DHA Phase 5',
        preferredMode: 'home',
      );
      expect(validPrefs.isComplete, isTrue);

      final map = validPrefs.toMap();
      expect(map['classLevel'], equals('Class 9'));
      expect(map['city'], equals('Lahore'));

      final parsed = LearnerPreferences.fromMap(map);
      expect(parsed.classLevel, equals('Class 9'));
      expect(parsed.city, equals('Lahore'));
      expect(parsed.neededSubjects.first, equals('Mathematics'));
    });

    test(
      'rankRecommendedTutors ranks same area > same city > different city',
      () {
        const prefs = LearnerPreferences(
          classLevel: 'Class 9',
          neededSubjects: ['Mathematics'],
          city: 'Lahore',
          area: 'DHA Phase 5',
          preferredMode: 'home',
        );

        final tutors = [
          tutorKarachi,
          tutorLahoreGulberg,
          tutorLahoreDHA,
          tutorClass10Only,
        ];

        final ranked = rankRecommendedTutors(
          tutors: tutors,
          preferences: prefs,
          showAllTutors: false,
        );

        // All tutors included, ranked by relevance
        expect(ranked.length, equals(4));

        // Rank 1: tutorLahoreDHA (Same Class + Same City + Same Area)
        expect(ranked[0].tutor.uid, equals('t_lahore_dha'));
        expect(ranked[0].matchBadges.contains('Matches your class'), isTrue);
        expect(ranked[0].matchBadges.contains('In your area'), isTrue);

        // Rank 2: tutorLahoreGulberg (Same Class + Same City)
        expect(ranked[1].tutor.uid, equals('t_lahore_gulberg'));
        expect(ranked[1].matchBadges.contains('In your city'), isTrue);

        // Rank 3: tutorKarachi (Same Class + Different City)
        expect(ranked[2].tutor.uid, equals('t_karachi'));
      },
    );

    test('Realistic Islamabad G-7 Class 9 student finds matching tutors via soft ranking', () {
      final tutorIslamabadG7 = TutorProfile(
        uid: 't_isb_g7',
        displayName: 'Tutor Islamabad G-7',
        publicId: 'TL-10',
        headline: 'Class 9 Science Specialist',
        bio: 'Bio text',
        subjects: const ['Mathematics', 'Physics'],
        levels: const ['Class 9', 'Class 10'],
        city: 'Islamabad',
        area: 'Sector G-7/2',
        mode: 'home',
        experienceYears: 4,
        availableDays: const ['Mon'],
        isPublished: true,
        createdAt: now,
        updatedAt: now,
      );

      const prefs = LearnerPreferences(
        classLevel: 'Class 9',
        neededSubjects: ['Mathematics'],
        city: 'Islamabad',
        area: 'G-7',
        preferredMode: 'both',
      );

      final ranked = rankRecommendedTutors(
        tutors: [tutorIslamabadG7, tutorKarachi],
        preferences: prefs,
      );

      expect(ranked.isNotEmpty, isTrue);
      expect(ranked.first.tutor.uid, equals('t_isb_g7'));
      expect(ranked.first.matchBadges.contains('Matches your class'), isTrue);
      expect(ranked.first.matchBadges.contains('In your area'), isTrue);
    });

    test('sector ranking orders same sector, neighbor, then same city', () {
      final sameSector = tutorLahoreDHA.copyWith(area: 'G-7/4');
      final neighbor = tutorLahoreDHA.copyWith(uid: 'neighbor', area: 'G-8');
      final sameCity = tutorLahoreDHA.copyWith(uid: 'same-city', area: 'F-10');
      const preferences = LearnerPreferences(
        classLevel: 'Class 9',
        neededSubjects: ['Mathematics'],
        city: 'Lahore',
        area: 'G-7/1',
        preferredMode: 'home',
      );

      final results = rankRecommendedTutors(
        tutors: [sameCity, neighbor, sameSector],
        preferences: preferences,
      );

      expect(results.map((result) => result.tutor.uid), [
        't_lahore_dha',
        'neighbor',
        'same-city',
      ]);
      expect(areNeighboringSectors('G-7', 'G-8'), isTrue);
      expect(tutorAreasMatch('G-7/1', 'G-7/4'), isTrue);
      expect(tutorAreasMatch('G-7', 'G-8'), isFalse);
    });
  });
}
