// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:teach_learn/features/students/data/student_repository.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockWriteBatch extends Mock implements WriteBatch {}

class FakeDocumentReference extends Fake
    implements DocumentReference<Object?> {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDocumentReference());
  });

  test('deletes nested tests before deleting the student', () async {
    final firestore = MockFirebaseFirestore();
    final usersCollection = MockCollectionReference();
    final userDocument = MockDocumentReference();
    final studentsCollection = MockCollectionReference();
    final studentDocument = MockDocumentReference();
    final testsCollection = MockCollectionReference();
    final testsSnapshot = MockQuerySnapshot();
    final testDocument = MockQueryDocumentSnapshot();
    final testReference = MockDocumentReference();
    final attendanceCollection = MockCollectionReference();
    final attendanceQuery = MockQuery();
    final attendanceSnapshot = MockQuerySnapshot();
    final batch = MockWriteBatch();
    final events = <Object>[];

    when(() => firestore.collection('users')).thenReturn(usersCollection);
    when(() => usersCollection.doc('user_123')).thenReturn(userDocument);
    when(() => userDocument.collection('students'))
        .thenReturn(studentsCollection);
    when(() => studentsCollection.doc('student_1'))
        .thenReturn(studentDocument);
    when(() => studentDocument.collection('tests')).thenReturn(testsCollection);
    when(() => testsCollection.get()).thenAnswer((_) async => testsSnapshot);
    when(() => testsSnapshot.docs).thenReturn([testDocument]);
    when(() => testDocument.reference).thenReturn(testReference);
    when(() => userDocument.collection('attendance'))
        .thenReturn(attendanceCollection);
    when(
      () => attendanceCollection.where(
        'studentId',
        isEqualTo: 'student_1',
      ),
    ).thenReturn(attendanceQuery);
    when(() => attendanceQuery.get())
        .thenAnswer((_) async => attendanceSnapshot);
    when(() => attendanceSnapshot.docs).thenReturn([]);
    when(() => firestore.batch()).thenReturn(batch);
    when(() => batch.delete(any())).thenAnswer((invocation) {
      events.add(invocation.positionalArguments.single as Object);
    });
    when(() => batch.commit()).thenAnswer((_) async {
      events.add('tests-committed');
    });
    when(() => studentDocument.delete()).thenAnswer((_) async {
      events.add('student-deleted');
    });

    final repository = FirestoreStudentRepository(firestore: firestore);
    await repository.deleteStudent('user_123', 'student_1');

    expect(events, [testReference, 'tests-committed', 'student-deleted']);
  });
}
