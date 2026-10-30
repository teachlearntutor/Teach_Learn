import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:teach_learn/features/marketplace/domain/models/lesson_request.dart';
import 'package:teach_learn/features/marketplace/domain/models/tutor_profile.dart';

void main() {
  group('Marketplace M1 Domain & Repository Tests', () {
    final now = DateTime.now();

    final testTutor = TutorProfile(
      uid: 'tutor_1',
      displayName: 'Malik Azmat',
      publicId: 'TL-HD85R',
      headline: 'O/A Level Math & Computer Specialist',
      bio: 'Over 5 years of teaching experience.',
      subjects: ['Mathematics', 'Computer Science'],
      levels: ['Class 9', 'Class 10', 'O Levels'],
      city: 'Lahore',
      area: 'DHA Phase 5',
      mode: 'both',
      experienceYears: 5,
      availableDays: ['Mon', 'Wed', 'Fri'],
      isPublished: true,
      createdAt: now,
      updatedAt: now,
    );

    final testRequest = LessonRequest(
      id: 'learner1_tutor1',
      fromUid: 'learner1',
      toUid: 'tutor_1',
      fromName: 'Ali Raza',
      subject: 'Mathematics',
      message: 'Looking for home tuition for Class 9 Mathematics',
      status: LessonRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    test('TutorProfile converts to and from Firestore map cleanly', () {
      final map = testTutor.toFirestore();
      expect(map['displayName'], equals('Malik Azmat'));
      expect(map['isPublished'], equals(true));
      expect((map['subjects'] as List).contains('Mathematics'), equals(true));
    });

    test('LessonRequest transitions status correctly', () {
      final accepted = testRequest.copyWith(status: LessonRequestStatus.accepted);
      expect(accepted.status, equals(LessonRequestStatus.accepted));

      final cancelled = testRequest.copyWith(status: LessonRequestStatus.cancelled);
      expect(cancelled.status, equals(LessonRequestStatus.cancelled));
    });

    test('FakeMarketplaceRepository handles profile and request streams', () async {
      final repo = FakeMarketplaceRepository(
        initialProfiles: [testTutor],
        initialRequests: [testRequest],
      );

      final published = await repo.watchPublishedTutors().first;
      expect(published.length, equals(1));
      expect(published.first.displayName, equals('Malik Azmat'));

      await repo.updateRequestStatus(
        requestId: 'learner1_tutor1',
        status: LessonRequestStatus.accepted,
      );

      final tutorRequests = await repo.watchTutorRequests('tutor_1').first;
      expect(tutorRequests.first.status, equals(LessonRequestStatus.accepted));
    });
  });
}
