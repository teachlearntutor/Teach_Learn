import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/features/marketplace/domain/models/lesson_request.dart';

void main() {
  test('old requests without learner details load with safe defaults', () {
    final request = LessonRequest.fromData('old_request', {
      'fromUid': 'learner-1',
      'toUid': 'tutor-1',
    });

    expect(request.learnerName, 'Learner');
    expect(request.classLevel, isEmpty);
    expect(request.subjects, isEmpty);
    expect(request.city, isEmpty);
    expect(request.area, isEmpty);
    expect(request.mode, isEmpty);
    expect(request.message, isEmpty);
  });

  test('request serialization includes learner details without phone data', () {
    final request = LessonRequest(
      id: 'learner-1_tutor-1',
      fromUid: 'learner-1',
      toUid: 'tutor-1',
      fromName: 'Ayesha Khan',
      learnerName: 'Ayesha Khan',
      classLevel: 'Class 9',
      subject: 'Mathematics',
      subjects: const ['Mathematics', 'Physics'],
      city: 'Islamabad',
      area: 'G-7',
      mode: 'home',
      message: 'Looking for weekly tuition.',
      status: LessonRequestStatus.pending,
      createdAt: DateTime(2026, 11, 14),
      updatedAt: DateTime(2026, 11, 14),
    );

    final data = request.toFirestore();
    expect(data['learnerName'], 'Ayesha Khan');
    expect(data['classLevel'], 'Class 9');
    expect(data['subjects'], ['Mathematics', 'Physics']);
    expect(data['city'], 'Islamabad');
    expect(data['area'], 'G-7');
    expect(data['mode'], 'home');
    expect(data['message'], 'Looking for weekly tuition.');
    expect(data.keys, isNot(contains('learnerPhone')));
  });

  test('legacy learner phone is ignored and never serialized', () {
    final request = LessonRequest.fromData('learner-1_tutor-1', {
      'fromUid': 'learner-1',
      'toUid': 'tutor-1',
      'learnerPhone': '+923001234567',
    });

    expect(request.toFirestore(), isNot(contains('learnerPhone')));
  });
}
