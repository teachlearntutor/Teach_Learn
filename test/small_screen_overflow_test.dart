import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/core/theme/app_theme.dart';
import 'package:teach_learn/features/attendance/data/fake_attendance_repository.dart';
import 'package:teach_learn/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:teach_learn/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:teach_learn/features/auth/data/auth_repository.dart';
import 'package:teach_learn/features/auth/presentation/providers/auth_providers.dart';
import 'package:teach_learn/features/auth/presentation/screens/auth_screen.dart';
import 'package:teach_learn/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:teach_learn/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:teach_learn/features/marketplace/presentation/screens/find_tutor_screen.dart';
import 'package:teach_learn/features/marketplace/presentation/screens/public_profile_screen.dart';
import 'package:teach_learn/features/marketplace/presentation/screens/tutor_detail_screen.dart';
import 'package:teach_learn/features/marketplace/domain/models/tutor_profile.dart';
import 'package:teach_learn/features/learner/presentation/screens/learner_home_screen.dart';
import 'package:teach_learn/features/profile/presentation/screens/profile_screen.dart';
import 'package:teach_learn/features/students/data/fake_student_repository.dart';
import 'package:teach_learn/features/students/domain/models/student.dart';
import 'package:teach_learn/features/students/presentation/providers/student_providers.dart';
import 'package:teach_learn/features/students/presentation/screens/students_screen.dart';
import 'package:teach_learn/features/tutor/presentation/screens/tutor_home_screen.dart';

class _FakeUnauthRepository extends Fake implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(null);
  @override
  User? get currentUser => null;
}

final _testNow = DateTime.now();

final _sampleStudents = [
  Student(
    id: 'student_1',
    code: 'S-4K2P',
    name: 'Ayesha Khan',
    searchName: 'ayesha khan',
    classLevel: 'Class 9',
    classSort: 9,
    school: 'Beaconhouse School',
    subjects: const ['Mathematics', 'Physics'],
    parentContact: '0301-555-0101',
    startDate: '2026-01-01',
    status: StudentStatus.active,
    createdAt: _testNow,
    updatedAt: _testNow,
  ),
];

void main() {
  group(
    'Small Screen (360x640) & Large Text (1.5x) Overflow Prevention Tests',
    () {
      void setupSmallDisplay(WidgetTester tester) {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
      }

      void resetDisplay(WidgetTester tester) {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }

      testWidgets(
        'AuthScreen renders cleanly at 360x640 with 1.5x text scale',
        (WidgetTester tester) async {
          setupSmallDisplay(tester);
          addTearDown(() => resetDisplay(tester));

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authRepositoryProvider.overrideWith(
                  (ref) => _FakeUnauthRepository(),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.5),
                  ),
                  child: const AuthScreen(),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(find.text('Welcome back'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'StudentsScreen renders cleanly at 360x640 with 1.5x text scale',
        (WidgetTester tester) async {
          setupSmallDisplay(tester);
          addTearDown(() => resetDisplay(tester));

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authRepositoryProvider.overrideWith(
                  (ref) => _FakeUnauthRepository(),
                ),
                studentRepositoryProvider.overrideWith(
                  (ref) => FakeStudentRepository(_sampleStudents),
                ),
                studentsStreamProvider.overrideWith(
                  (ref) => Stream.value(_sampleStudents),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.5),
                  ),
                  child: const Scaffold(body: StudentsScreen()),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(find.text('Search students'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'FindTutorScreen renders cleanly at 360x640 with 1.5x text scale',
        (WidgetTester tester) async {
          setupSmallDisplay(tester);
          addTearDown(() => resetDisplay(tester));

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authRepositoryProvider.overrideWith(
                  (ref) => _FakeUnauthRepository(),
                ),
                marketplaceRepositoryProvider.overrideWith(
                  (ref) => FakeMarketplaceRepository(),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.5),
                  ),
                  child: const FindTutorScreen(),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(
            find.text('Search by name, city, area, or ID'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'TutorDetailScreen renders cleanly at 360x640 with 1.5x text scale',
        (WidgetTester tester) async {
          setupSmallDisplay(tester);
          addTearDown(() => resetDisplay(tester));
          final now = DateTime.now();

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authRepositoryProvider.overrideWith(
                  (ref) => _FakeUnauthRepository(),
                ),
                marketplaceRepositoryProvider.overrideWith(
                  (ref) => FakeMarketplaceRepository(),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.5),
                  ),
                  child: TutorDetailScreen(
                    tutor: TutorProfile(
                      uid: 'tutor-1',
                      displayName: 'Ayesha Khan',
                      publicId: 'TL-12345',
                      headline: 'Experienced Mathematics Tutor',
                      bio: 'A short teaching profile.',
                      subjects: const ['Mathematics', 'Physics'],
                      levels: const ['Class 9', 'Class 10'],
                      city: 'Islamabad',
                      area: 'G-7',
                      mode: 'home',
                      experienceYears: 8,
                      availableDays: const [],
                      isPublished: true,
                      createdAt: now,
                      updatedAt: now,
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(find.text('Ayesha Khan'), findsNWidgets(2));
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'LearnerHomeScreen renders cleanly at 360x640 with 1.5x text scale',
        (WidgetTester tester) async {
          setupSmallDisplay(tester);
          addTearDown(() => resetDisplay(tester));

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authRepositoryProvider.overrideWith(
                  (ref) => _FakeUnauthRepository(),
                ),
                marketplaceRepositoryProvider.overrideWith(
                  (ref) => FakeMarketplaceRepository(),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.5),
                  ),
                  child: const LearnerHomeScreen(),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(find.text('Find Tutors'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'ProfileScreen renders cleanly at 360x640 with 1.5x text scale',
        (WidgetTester tester) async {
          setupSmallDisplay(tester);
          addTearDown(() => resetDisplay(tester));

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authRepositoryProvider.overrideWith(
                  (ref) => _FakeUnauthRepository(),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.5),
                  ),
                  child: const Scaffold(body: ProfileScreen()),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(find.text('Teach Learn User'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'PublicProfileScreen renders cleanly at 360x640 with 1.5x text scale',
        (WidgetTester tester) async {
          setupSmallDisplay(tester);
          addTearDown(() => resetDisplay(tester));

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authRepositoryProvider.overrideWith(
                  (ref) => _FakeUnauthRepository(),
                ),
                marketplaceRepositoryProvider.overrideWith(
                  (ref) => FakeMarketplaceRepository(),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.5),
                  ),
                  child: const PublicProfileScreen(),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(find.text('Visible in Tutor Finder'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'AttendanceScreen renders cleanly at 360x640 with 1.5x text scale',
        (WidgetTester tester) async {
          setupSmallDisplay(tester);
          addTearDown(() => resetDisplay(tester));

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authRepositoryProvider.overrideWith(
                  (ref) => _FakeUnauthRepository(),
                ),
                attendanceRepositoryProvider.overrideWith(
                  (ref) => FakeAttendanceRepository([]),
                ),
                allActiveStudentsStreamProvider.overrideWith(
                  (ref) => Stream.value(
                    _sampleStudents
                        .where(
                          (student) => student.status == StudentStatus.active,
                        )
                        .toList(),
                  ),
                ),
                studentsNotifierProvider.overrideWith(
                  (ref) => StudentsNotifier(
                    FakeStudentRepository(_sampleStudents),
                    'user_123',
                  ),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.5),
                  ),
                  child: const Scaffold(body: AttendanceScreen()),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(find.byType(AttendanceScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'TutorHomeScreen renders cleanly at 360x640 with 1.5x text scale',
        (WidgetTester tester) async {
          setupSmallDisplay(tester);
          addTearDown(() => resetDisplay(tester));

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authRepositoryProvider.overrideWith(
                  (ref) => _FakeUnauthRepository(),
                ),
                studentRepositoryProvider.overrideWith(
                  (ref) => FakeStudentRepository(_sampleStudents),
                ),
                studentsStreamProvider.overrideWith(
                  (ref) => Stream.value(_sampleStudents),
                ),
                tutorRequestsStreamProvider.overrideWith(
                  (ref) => Stream.value([]),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const TutorHomeScreen(),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(find.text('Home'), findsAtLeastNWidgets(1));
          expect(tester.takeException(), isNull);
        },
      );
    },
  );
}
