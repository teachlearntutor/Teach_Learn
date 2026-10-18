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
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

class FakeTransaction extends Fake implements Transaction {
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(DocumentReference<T> documentRef) async {
    final mockSnapshot = MockDocumentSnapshot();
    when(() => mockSnapshot.exists).thenReturn(false);
    return mockSnapshot as DocumentSnapshot<T>;
  }

  @override
  Transaction set<T extends Object?>(DocumentReference<T> documentRef, T data, [SetOptions? setOptions]) {
    return this;
  }
}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;
  late MockCollectionReference mockUsersCollection;
  late MockCollectionReference mockPublicIdsCollection;
  late MockDocumentReference mockUserDocRef;
  late MockDocumentReference mockPublicIdDocRef;
  late MockDocumentSnapshot mockUserDocSnapshot;
  late AuthRepository authRepository;

  setUpAll(() {
    registerFallbackValue(SetOptions(merge: true));
    registerFallbackValue(MockDocumentReference());
    registerFallbackValue(const Duration(seconds: 30));
  });

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();
    mockUsersCollection = MockCollectionReference();
    mockPublicIdsCollection = MockCollectionReference();
    mockUserDocRef = MockDocumentReference();
    mockPublicIdDocRef = MockDocumentReference();
    mockUserDocSnapshot = MockDocumentSnapshot();

    authRepository = AuthRepository(
      auth: mockAuth,
      firestore: mockFirestore,
    );

    when(() => mockUser.uid).thenReturn('test_uid_123');
    when(() => mockUser.photoURL).thenReturn(null);
    when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});
    when(() => mockUser.sendEmailVerification()).thenAnswer((_) async {});
    when(() => mockUser.delete()).thenAnswer((_) async {});

    when(() => mockUserCredential.user).thenReturn(mockUser);

    when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
    when(() => mockFirestore.collection('publicIds')).thenReturn(mockPublicIdsCollection);
    when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDocRef);
    when(() => mockUsersCollection.doc()).thenReturn(mockUserDocRef);
    when(() => mockPublicIdsCollection.doc(any())).thenReturn(mockPublicIdDocRef);
    when(() => mockPublicIdsCollection.doc()).thenReturn(mockPublicIdDocRef);
  });

  group('AuthRepository Tests', () {
    test('signUpWithEmail creates Auth user and executes Firestore transaction', () async {
      when(() => mockAuth.createUserWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          )).thenAnswer((_) async => mockUserCredential);

      when(() => mockFirestore.runTransaction<void>(
            any(),
            timeout: any(named: 'timeout'),
            maxAttempts: any(named: 'maxAttempts'),
          )).thenAnswer((invocation) async {
        final transactionHandler = invocation.positionalArguments[0] as Future<void> Function(Transaction);
        final fakeTransaction = FakeTransaction();
        await transactionHandler(fakeTransaction);
      });

      final result = await authRepository.signUpWithEmail(
        name: 'Test Tutor',
        email: 'test@example.com',
        password: 'password123',
        role: 'tutor',
      );

      expect(result.uid, equals('test_uid_123'));
      verify(() => mockUser.updateDisplayName('Test Tutor')).called(1);
    });

    test('Failed Firestore transaction deletes the Auth user so user can retry', () async {
      when(() => mockAuth.createUserWithEmailAndPassword(
            email: 'fail@example.com',
            password: 'password123',
          )).thenAnswer((_) async => mockUserCredential);

      when(() => mockFirestore.runTransaction<void>(
            any(),
            timeout: any(named: 'timeout'),
            maxAttempts: any(named: 'maxAttempts'),
          )).thenAnswer((_) => Future<void>.error(Exception('Firestore write error')));

      await expectLater(
        () => authRepository.signUpWithEmail(
          name: 'Fail User',
          email: 'fail@example.com',
          password: 'password123',
          role: 'student',
        ),
        throwsA(isA<AuthException>()),
      );

      verify(() => mockUser.delete()).called(1);
    });

    test('getUserRole throws AuthException when role is missing (never defaults to tutor)', () async {
      when(() => mockUsersCollection.doc('no_role_uid')).thenReturn(mockUserDocRef);
      when(() => mockUserDocRef.get()).thenAnswer((_) async => mockUserDocSnapshot);
      when(() => mockUserDocSnapshot.exists).thenReturn(false);

      await expectLater(
        () => authRepository.getUserRole('no_role_uid'),
        throwsA(isA<AuthException>()),
      );
    });

    test('signOut calls FirebaseAuth.signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await authRepository.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });
  });
}
