import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:teach_learn/core/theme/app_theme.dart';
import 'package:teach_learn/core/widgets/app_snackbar.dart';
import 'package:teach_learn/core/widgets/contact_action_buttons.dart';
import 'package:teach_learn/features/auth/data/auth_repository.dart';
import 'package:teach_learn/features/auth/presentation/providers/auth_providers.dart';
import 'package:teach_learn/features/learner/presentation/screens/learner_home_screen.dart';
import 'package:teach_learn/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:teach_learn/features/marketplace/domain/models/lesson_request.dart';
import 'package:teach_learn/features/marketplace/domain/models/tutor_profile.dart';
import 'package:teach_learn/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:teach_learn/features/marketplace/presentation/screens/my_requests_screen.dart';
import 'package:teach_learn/features/marketplace/presentation/screens/find_tutor_screen.dart';
import 'package:teach_learn/features/marketplace/presentation/screens/public_profile_screen.dart';
import 'package:teach_learn/features/marketplace/presentation/screens/tutor_detail_screen.dart';
import 'package:teach_learn/features/students/data/fake_student_repository.dart';
import 'package:teach_learn/features/students/domain/models/student.dart';
import 'package:teach_learn/features/students/presentation/providers/student_providers.dart';
import 'package:teach_learn/features/students/presentation/screens/student_detail_screen.dart';

class _TestUser extends Fake implements User {
  @override
  String get uid => 'learner-1';

  @override
  String? get displayName => 'Jamie Learner';
}

class _TestAuthRepository extends Fake implements AuthRepository {
  final User _user = _TestUser();

  @override
  Stream<User?> get authStateChanges => Stream.value(_user);

  @override
  User? get currentUser => _user;

  @override
  Future<Map<String, dynamic>?> getUserProfile(String uid) async => {
    'displayName': 'Jamie Learner',
    'role': 'student',
    'classLevel': 'Class 9',
    'neededSubjects': ['Mathematics'],
    'city': 'Islamabad',
    'area': 'G-7',
    'preferredMode': 'both',
  };
}

class _ContactsMarketplace extends FakeMarketplaceRepository {
  _ContactsMarketplace({
    required TutorProfile tutor,
    required LessonRequest request,
  }) : super(initialProfiles: [tutor], initialRequests: [request]);

  @override
  Stream<String?> watchTutorPrivateContact(String tutorUid) =>
      Stream.value('+923001234567');
}

final _now = DateTime(2026, 11, 15);

final _tutor = TutorProfile(
  uid: 'tutor-1',
  displayName: 'Alexandria Tutor With A Long Name',
  publicId: 'TL-12345',
  headline: 'Mathematics tutor',
  bio: 'A short profile.',
  subjects: const ['Physics'],
  levels: const ['Class 9'],
  city: 'Islamabad',
  area: 'G-8',
  mode: 'home',
  experienceYears: 8,
  availableDays: const [],
  isPublished: true,
  createdAt: _now,
  updatedAt: _now,
);

final _acceptedRequest = LessonRequest(
  id: 'learner-1_tutor-1',
  fromUid: 'learner-1',
  toUid: 'tutor-1',
  toName: _tutor.displayName,
  fromName: 'Jamie Learner',
  learnerName: 'Jamie Learner',
  classLevel: 'Class 9',
  subject: 'Mathematics',
  subjects: const ['Mathematics', 'Physics'],
  city: 'Islamabad',
  area: 'G-7',
  mode: 'home',
  message: '',
  status: LessonRequestStatus.accepted,
  createdAt: _now,
  updatedAt: _now,
);

void _setSmallDisplay(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
}

void _resetDisplay(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Widget _smallScreen(Widget child) => MediaQuery(
  data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
  child: child,
);

List<Override> _baseOverrides() => [
  authRepositoryProvider.overrideWith((ref) => _TestAuthRepository()),
  marketplaceRepositoryProvider.overrideWith(
    (ref) => _ContactsMarketplace(tutor: _tutor, request: _acceptedRequest),
  ),
  learnerRequestsStreamProvider.overrideWith(
    (ref) => Stream.value([_acceptedRequest]),
  ),
];

void main() {
  group('Contact card layouts at 360x640 and 1.5x text', () {
    testWidgets('learner home keeps both tutor card styles compact', (
      tester,
    ) async {
      _setSmallDisplay(tester);
      addTearDown(() => _resetDisplay(tester));

      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: _smallScreen(const LearnerHomeScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final verticalScroll = find
          .descendant(
            of: find.byType(LearnerHomeScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('My Confirmed Tutors'),
        180,
        scrollable: verticalScroll,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Call Tutor'),
        180,
        scrollable: verticalScroll,
      );

      expect(find.text('Near you'), findsOneWidget);
      expect(find.text('Call Tutor'), findsOneWidget);
      expect(find.text('G-8, Islamabad'), findsWidgets);
      expect(find.text('Physics'), findsWidgets);
      expect(find.byType(ContactActionButtons), findsOneWidget);
      expect(find.byType(FaIcon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('My Requests accepted tutor actions fit on a small screen', (
      tester,
    ) async {
      _setSmallDisplay(tester);
      addTearDown(() => _resetDisplay(tester));

      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: _smallScreen(const MyRequestsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Call Tutor'),
        120,
        scrollable: find.descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        ),
      );

      expect(find.byType(ContactActionButtons), findsOneWidget);
      expect(find.byType(FaIcon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepted tutor detail actions fit on a small screen', (
      tester,
    ) async {
      _setSmallDisplay(tester);
      addTearDown(() => _resetDisplay(tester));

      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: _smallScreen(TutorDetailScreen(tutor: _tutor)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Call Tutor'),
        180,
        scrollable: find.descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        ),
      );

      expect(find.byType(ContactActionButtons), findsOneWidget);
      expect(find.byType(FaIcon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Find Tutor location controls fit on a small screen', (
      tester,
    ) async {
      _setSmallDisplay(tester);
      addTearDown(() => _resetDisplay(tester));

      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: _smallScreen(const FindTutorScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Near me'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tutor location controls fit on a small screen', (
      tester,
    ) async {
      _setSmallDisplay(tester);
      addTearDown(() => _resetDisplay(tester));

      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: _smallScreen(const PublicProfileScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Use my current location'),
        180,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );

      expect(find.text('Use my current location'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('student detail WhatsApp action fits on a small screen', (
      tester,
    ) async {
      _setSmallDisplay(tester);
      addTearDown(() => _resetDisplay(tester));
      final student = Student(
        id: 'student-1',
        code: 'S-1234',
        name: 'Student One',
        searchName: 'student one',
        classLevel: 'Class 9',
        classSort: 9,
        subjects: const ['Mathematics'],
        parentContact: '03001234567',
        startDate: '2026-01-01',
        status: StudentStatus.active,
        createdAt: _now,
        updatedAt: _now,
      );
      final repo = FakeStudentRepository([student]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWith((ref) => _TestAuthRepository()),
            studentRepositoryProvider.overrideWith((ref) => repo),
            studentsNotifierProvider.overrideWith(
              (ref) => StudentsNotifier(repo, 'learner-1'),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: _smallScreen(
              const StudentDetailScreen(studentId: 'student-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('WhatsApp Parent'),
        180,
        scrollable: find.descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        ),
      );

      expect(find.byType(FaIcon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets(
    'toast respects safe bottom and keyboard insets, width, replacement, and swipe',
    (tester) async {
      _setSmallDisplay(tester);
      addTearDown(() => _resetDisplay(tester));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData.fromView(tester.view).copyWith(
              padding: const EdgeInsets.only(bottom: 20),
              viewInsets: const EdgeInsets.only(bottom: 180),
              textScaler: const TextScaler.linear(1.5),
            ),
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            showAppSnackBar(context, 'First toast'),
                        child: const Text('Show first'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            showAppSnackBar(context, 'Second toast'),
                        child: const Text('Show second'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show first'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Show second'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('First toast'), findsNothing);
      final toastText = find.text('Second toast');
      expect(toastText, findsOneWidget);
      final toastMaterial = find
          .ancestor(of: toastText, matching: find.byType(Material))
          .first;
      final toastBottom =
          tester.getTopLeft(toastMaterial).dy +
          tester.getSize(toastMaterial).height;
      expect(toastBottom, closeTo(350, 1));
      expect(tester.getSize(toastMaterial).width, lessThanOrEqualTo(328));

      await tester.drag(toastText, const Offset(100, 0));
      await tester.pumpAndSettle();
      expect(toastText, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('toast max width is 420 and default timeout is 2.5 seconds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      _resetDisplay(tester);
      clearActiveAppToast();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAppSnackBar(context, 'Timed toast'),
                child: const Text('Show timed toast'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show timed toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2499));
    final toastText = find.text('Timed toast');
    expect(toastText, findsOneWidget);

    final toastMaterial = find
        .ancestor(of: toastText, matching: find.byType(Material))
        .first;
    expect(tester.getSize(toastMaterial).width, closeTo(420, 1));
    expect(tester.getTopLeft(toastMaterial).dx, closeTo(90, 1));

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(toastText, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
