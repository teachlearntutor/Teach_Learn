// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:teach_learn/features/auth/data/auth_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockUserInfo extends Mock implements UserInfo {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockWriteBatch extends Mock implements WriteBatch {}

class FakeDocumentReference extends Fake
    implements DocumentReference<Object?> {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockUser;
  late MockUserInfo mockUserInfo;
  late MockCollectionReference mockTutorProfilesCollection;
  late MockCollectionReference mockPrivateCollection;
  late MockCollectionReference mockUsersCollection;
  late MockCollectionReference mockStudentsCollection;
  late MockDocumentReference mockTutorDoc;
  late MockDocumentReference mockContactDoc;
  late MockDocumentReference mockUserDoc;
  late MockQuerySnapshot mockEmptyQuerySnap;
  late AuthRepository authRepository;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
    mockUserInfo = MockUserInfo();
    mockTutorProfilesCollection = MockCollectionReference();
    mockPrivateCollection = MockCollectionReference();
    mockUsersCollection = MockCollectionReference();
    mockStudentsCollection = MockCollectionReference();
    mockTutorDoc = MockDocumentReference();
    mockContactDoc = MockDocumentReference();
    mockUserDoc = MockDocumentReference();
    mockEmptyQuerySnap = MockQuerySnapshot();

    authRepository = AuthRepository(auth: mockAuth, firestore: mockFirestore);

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('uid_123');
    when(() => mockUser.email).thenReturn('user@example.com');
    when(() => mockUserInfo.providerId).thenReturn('password');
    when(() => mockUser.providerData).thenReturn([mockUserInfo]);
    when(() => mockUser.reauthenticateWithCredential(any()))
        .thenAnswer((_) async => MockUserCredential());
    when(() => mockUser.delete()).thenAnswer((_) async {});

    when(() => mockFirestore.collection('tutorProfiles'))
        .thenReturn(mockTutorProfilesCollection);
    when(() => mockTutorProfilesCollection.doc('uid_123'))
        .thenReturn(mockTutorDoc);
    when(() => mockTutorDoc.collection('private'))
        .thenReturn(mockPrivateCollection);
    when(() => mockPrivateCollection.doc('contact')).thenReturn(mockContactDoc);
    when(() => mockContactDoc.delete()).thenAnswer((_) async {});
    when(() => mockTutorDoc.delete()).thenAnswer((_) async {});

    when(() => mockFirestore.collection('users'))
        .thenReturn(mockUsersCollection);
    when(() => mockUsersCollection.doc('uid_123')).thenReturn(mockUserDoc);
    when(() => mockUserDoc.collection(any()))
        .thenReturn(mockStudentsCollection);
    when(() => mockStudentsCollection.get())
        .thenAnswer((_) async => mockEmptyQuerySnap);
    when(() => mockEmptyQuerySnap.docs).thenReturn([]);
    when(() => mockUserDoc.delete()).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(FakeDocumentReference());
    registerFallbackValue(
      EmailAuthProvider.credential(email: 'test@example.com', password: 'pass'),
    );
  });

  group('Account Deletion Order & Safety Tests', () {
    test('Successful delete sequence: tutor contact -> tutor profile -> subcollections -> user doc -> auth user', () async {
      await authRepository.deleteUserAccount(password: 'secret123');

      // Verify deletion order execution
      verify(() => mockContactDoc.delete()).called(1);
      verify(() => mockTutorDoc.delete()).called(1);
      verify(() => mockUserDoc.delete()).called(1);
      verify(() => mockUser.delete()).called(1);
    });

    test('Failure in tutor profile step stops execution and Auth user is NOT deleted', () async {
      // Simulate permission error on tutor profile deletion
      when(() => mockTutorDoc.delete()).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Permission denied',
        ),
      );

      await expectLater(
        () => authRepository.deleteUserAccount(password: 'secret123'),
        throwsA(isA<AuthException>()),
      );

      // Verify that user doc and Auth user delete were NEVER called due to early failure
      verifyNever(() => mockUserDoc.delete());
      verifyNever(() => mockUser.delete());
    });

    test(
      'deletes nested tests before students in batches of at most 400',
      () async {
        final studentRef = MockDocumentReference();
        final studentSnapshot = MockQueryDocumentSnapshot();
        final studentsSnapshot = MockQuerySnapshot();
        final testsCollection = MockCollectionReference();
        final testsSnapshot = MockQuerySnapshot();
        final batch = MockWriteBatch();
        final emptyCollection = MockCollectionReference();
        final testReferences = <MockDocumentReference>[];
        final events = <Object>[];
        final testDocuments = List.generate(401, (_) {
          final document = MockQueryDocumentSnapshot();
          final reference = MockDocumentReference();
          testReferences.add(reference);
          when(() => document.reference).thenReturn(reference);
          return document;
        });

        when(() => mockUserDoc.collection('students'))
            .thenReturn(mockStudentsCollection);
        when(() => mockStudentsCollection.get())
            .thenAnswer((_) async => studentsSnapshot);
        when(() => studentsSnapshot.docs).thenReturn([studentSnapshot]);
        when(() => studentSnapshot.reference).thenReturn(studentRef);
        when(() => studentRef.collection('tests')).thenReturn(testsCollection);
        when(() => testsCollection.get())
            .thenAnswer((_) async => testsSnapshot);
        when(() => testsSnapshot.docs).thenReturn(testDocuments);
        when(() => emptyCollection.get())
            .thenAnswer((_) async => mockEmptyQuerySnap);
        for (final name in ['attendance', 'holidays', 'classes', 'sessions']) {
          when(() => mockUserDoc.collection(name)).thenReturn(emptyCollection);
        }
        when(() => mockFirestore.batch()).thenReturn(batch);
        when(() => batch.delete(any())).thenAnswer((invocation) {
          events.add(invocation.positionalArguments.first as Object);
        });
        when(() => batch.commit()).thenAnswer((_) async {
          events.add('commit');
        });
        when(() => mockUserDoc.delete()).thenAnswer((_) async {
          events.add('user-document');
        });
        when(() => mockUser.delete()).thenAnswer((_) async {
          events.add('auth-user');
        });

        await authRepository.deleteUserAccount(password: 'secret123');

        final commitIndices = [
          for (var index = 0; index < events.length; index++)
            if (events[index] == 'commit') index,
        ];
        expect(commitIndices, hasLength(3));
        expect(
          events.take(commitIndices.first).whereType<MockDocumentReference>(),
          hasLength(400),
        );
        expect(
          events
              .skip(commitIndices[0] + 1)
              .take(commitIndices[1] - commitIndices[0] - 1)
              .whereType<MockDocumentReference>(),
          hasLength(1),
        );
        expect(
          events.indexOf(testReferences.first),
          lessThan(commitIndices.first),
        );
        expect(
          events.indexOf(testReferences.last),
          greaterThan(commitIndices.first),
        );
        expect(
          events.indexOf(testReferences.last),
          lessThan(events.indexOf(studentRef)),
        );
        expect(
          events.indexOf(studentRef),
          lessThan(events.indexOf('user-document')),
        );
        expect(
          events.indexOf('user-document'),
          lessThan(events.indexOf('auth-user')),
        );
      },
    );
  });
}
