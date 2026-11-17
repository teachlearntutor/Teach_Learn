import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/core/theme/app_theme.dart';
import 'package:teach_learn/core/widgets/app_snackbar.dart';
import 'package:teach_learn/features/attendance/data/fake_attendance_repository.dart';
import 'package:teach_learn/features/attendance/domain/models/attendance_record.dart';
import 'package:teach_learn/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:teach_learn/features/auth/data/auth_repository.dart';
import 'package:teach_learn/features/auth/presentation/providers/auth_providers.dart';
import 'package:teach_learn/features/learner/presentation/screens/learner_home_screen.dart';
import 'package:teach_learn/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:teach_learn/features/marketplace/domain/models/tutor_profile.dart';
import 'package:teach_learn/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:teach_learn/features/marketplace/presentation/screens/find_tutor_screen.dart';
import 'package:teach_learn/features/marketplace/presentation/screens/tutor_detail_screen.dart';
import 'package:teach_learn/features/profile/presentation/screens/profile_screen.dart';
import 'package:teach_learn/features/students/data/fake_student_repository.dart';
import 'package:teach_learn/features/students/domain/models/academic_test.dart';
import 'package:teach_learn/features/students/domain/models/student.dart';
import 'package:teach_learn/features/students/presentation/providers/academic_test_providers.dart';
import 'package:teach_learn/features/students/presentation/providers/student_providers.dart';
import 'package:teach_learn/features/students/presentation/screens/students_screen.dart';
import 'package:teach_learn/features/tutor/presentation/screens/tutor_home_screen.dart';

class _UnauthenticatedRepository extends Fake implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(null);

  @override
  User? get currentUser => null;
}

final _now = DateTime.now();
final _students = [
  Student(
    id: 'student-1',
    code: 'S-1001',
    name: 'Ayesha Khan',
    searchName: 'ayesha khan',
    classLevel: 'Class 9',
    classSort: 9,
    school: 'City School',
    subjects: const ['Mathematics', 'Physics'],
    parentContact: '0300-1234567',
    startDate: '2025-01-01',
    status: StudentStatus.active,
    createdAt: _now,
    updatedAt: _now,
  ),
  Student(
    id: 'student-2',
    code: 'S-1002',
    name: 'Hamza Raza',
    searchName: 'hamza raza',
    classLevel: 'Class 8',
    classSort: 8,
    school: 'City School',
    subjects: const ['Science'],
    parentContact: '0300-7654321',
    startDate: '2025-01-01',
    status: StudentStatus.active,
    createdAt: _now,
    updatedAt: _now,
  ),
];

final _tutor = TutorProfile(
  uid: 'tutor-1',
  displayName: 'Sara Ahmed',
  publicId: 'TL-12345',
  headline: 'Mathematics tutor',
  bio: 'A brief tutor profile.',
  subjects: const ['Mathematics'],
  levels: const ['Class 9'],
  city: 'Lahore',
  area: 'Gulberg',
  mode: 'both',
  experienceYears: 5,
  availableDays: const ['Monday'],
  isPublished: true,
  createdAt: _now,
  updatedAt: _now,
);

List<Override> _overrides({
  List<Student>? seededStudents,
  TutorProfile? profile,
}) {
  final students = seededStudents ?? _students;
  final marketplaceRepository = FakeMarketplaceRepository(
    initialProfiles: profile == null ? const [] : [profile],
  );
  return [
    authRepositoryProvider.overrideWith((ref) => _UnauthenticatedRepository()),
    marketplaceRepositoryProvider.overrideWith((ref) => marketplaceRepository),
    studentRepositoryProvider.overrideWith(
      (ref) => FakeStudentRepository(students),
    ),
    studentsNotifierProvider.overrideWith((ref) {
      final notifier = StudentsNotifier(
        ref.watch(studentRepositoryProvider),
        'test-tutor',
      );
      notifier.state = StudentsState(
        students: students,
        hasMore: false,
        isLoadingInitial: false,
        isLoadingMore: false,
      );
      return notifier;
    }),
    studentsProvider.overrideWith((ref) => AsyncData(students)),
    allAttendanceStreamProvider.overrideWith(
      (ref) => Stream.value([
        AttendanceRecord(
          id: 'student-1_${_dateString(_now)}',
          studentId: 'student-1',
          studentName: 'Ayesha Khan',
          date: _dateString(_now),
          status: AttendanceStatus.present,
          markedAt: _now,
        ),
        AttendanceRecord(
          id: 'student-2_${_dateString(_now.subtract(const Duration(days: 8)))}',
          studentId: 'student-2',
          studentName: 'Hamza Raza',
          date: _dateString(_now.subtract(const Duration(days: 8))),
          status: AttendanceStatus.absent,
          markedAt: _now.subtract(const Duration(days: 8)),
        ),
      ]),
    ),
    allActiveStudentsStreamProvider.overrideWith(
      (ref) => Stream.value(students),
    ),
    attendanceRepositoryProvider.overrideWith(
      (ref) => FakeAttendanceRepository(),
    ),
    tutorRequestsStreamProvider.overrideWith((ref) => Stream.value([])),
    currentTutorProfileProvider.overrideWith(
      (ref) => ref
          .watch(marketplaceRepositoryProvider)
          .watchTutorProfile(_tutor.uid),
    ),
    studentAcademicTestsStreamProvider.overrideWith((ref, studentId) {
      if (studentId != 'student-1') return Stream.value([]);
      return Stream.value([
        AcademicTest(
          id: 'test-1',
          title: 'Algebra test',
          date: _dateString(_now),
          totalMarks: 100,
          obtainedMarks: 85,
          createdAt: _now,
        ),
      ]);
    }),
  ];
}

String _dateString(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

void main() {
  testWidgets('dark theme text has readable contrast on requested screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    Future<void> pumpDark(Widget home) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(),
          child: MaterialApp(theme: AppTheme.darkTheme, home: home),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      _expectReadableText(tester, AppTheme.darkTheme.colorScheme);
      expect(tester.takeException(), isNull);
    }

    await pumpDark(const TutorHomeScreen());
    await tester.tap(find.text('Students').last);
    await tester.pump();
    _expectReadableText(tester, AppTheme.darkTheme.colorScheme);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Attendance').last);
    await tester.pump();
    _expectReadableText(tester, AppTheme.darkTheme.colorScheme);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Profile').last);
    await tester.pump();
    _expectReadableText(tester, AppTheme.darkTheme.colorScheme);
    expect(tester.takeException(), isNull);

    await pumpDark(const ProfileScreen());
    await tester.scrollUntilVisible(
      find.text('Delete Account'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    _expectReadableText(tester, AppTheme.darkTheme.colorScheme);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();

    await pumpDark(const Scaffold(body: StudentsScreen()));
    await pumpDark(const LearnerHomeScreen());
    await pumpDark(const FindTutorScreen());
    await pumpDark(TutorDetailScreen(tutor: _tutor));

    await pumpDark(
      Builder(
        builder: (context) => Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Delete account?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('Open dialog'),
                ),
              ),
              TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (sheetContext) => const SafeArea(
                    child: ListTile(title: Text('Dark bottom sheet')),
                  ),
                ),
                child: const Text('Open sheet'),
              ),
              TextButton(
                onPressed: () => showAppSnackBar(
                  context,
                  'Dark toast sample',
                  duration: const Duration(seconds: 20),
                ),
                child: const Text('Open toast'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open dialog'));
    await tester.pump();
    _expectReadableText(tester, AppTheme.darkTheme.colorScheme);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel').last);
    await tester.pump();

    await tester.tap(find.text('Open sheet'));
    await tester.pump();
    _expectReadableText(tester, AppTheme.darkTheme.colorScheme);
    expect(find.text('Dark bottom sheet'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();

    await tester.tap(find.text('Open toast'));
    await tester.pump();
    _expectReadableText(tester, AppTheme.darkTheme.colorScheme);
    expect(find.text('Dark toast sample'), findsOneWidget);
    clearActiveAppToast();
  });

  testWidgets('Students screen fits 360x640 at 1.5x text', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              devicePixelRatio: 1,
              textScaler: TextScaler.linear(1.5),
            ),
            child: const Scaffold(body: StudentsScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Ayesha');
    await tester.pump();
    expect(find.text('Ayesha Khan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tutor dashboard fits a small dark screen at 1.5x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              devicePixelRatio: 1,
              textScaler: TextScaler.linear(1.5),
            ),
            child: const TutorHomeScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('1 of 2 marked'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recent test results'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Recent test results'), findsOneWidget);
    _expectReadableText(tester, AppTheme.darkTheme.colorScheme);
    await tester.scrollUntilVisible(
      find.text('Add test'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Add test'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add test'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a student'), findsOneWidget);
    final selectedStudent = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('Ayesha Khan'),
    );
    await tester.ensureVisible(selectedStudent);
    await tester.tap(selectedStudent);
    await tester.pumpAndSettle();
    expect(find.text('Add Test Record'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pump();
  });

  testWidgets('dashboard attention and public visibility use real records', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(profile: _tutor),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TutorHomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.scrollUntilVisible(
      find.text('Needs attention'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Hamza Raza'), findsOneWidget);
    expect(find.textContaining('Attendance 0%'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(Switch),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.text('Visible'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.text('Hidden'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty tutor dashboard prompts for the first student', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(seededStudents: const []),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TutorHomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Add your first student'), findsAtLeastNWidgets(1));
    expect(find.text('Total students'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tutor and learner tabs follow horizontal swipes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    Future<void> pumpHome(Widget home) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(),
          child: MaterialApp(theme: AppTheme.lightTheme, home: home),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> swipeToNextTab() async {
      await tester.drag(find.byType(PageView).first, const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
    }

    await pumpHome(const TutorHomeScreen());
    await swipeToNextTab();

    await pumpHome(const LearnerHomeScreen());
    await swipeToNextTab();
    expect(tester.takeException(), isNull);
  });
}

void _expectReadableText(WidgetTester tester, ColorScheme colors) {
  expect(
    _contrastRatio(colors.onSurface, colors.surface),
    greaterThanOrEqualTo(4.5),
  );
  expect(
    _contrastRatio(colors.onSurfaceVariant, colors.surface),
    greaterThanOrEqualTo(4.5),
  );
  expect(
    _contrastRatio(colors.onPrimary, colors.primary),
    greaterThanOrEqualTo(4.5),
  );
  expect(
    _contrastRatio(colors.onPrimaryContainer, colors.primaryContainer),
    greaterThanOrEqualTo(4.5),
  );
  expect(
    _contrastRatio(colors.onError, colors.error),
    greaterThanOrEqualTo(4.5),
  );
  expect(
    _contrastRatio(colors.onErrorContainer, colors.errorContainer),
    greaterThanOrEqualTo(4.5),
  );
  expect(
    _contrastRatio(colors.onTertiary, colors.tertiary),
    greaterThanOrEqualTo(4.5),
  );

  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final inheritedColor =
        DefaultTextStyle.of(element).style.color ?? colors.onSurface;
    final baseColor = widget.style?.color ?? inheritedColor;
    final background = _backgroundForTextColor(baseColor, colors);
    final span = widget.textSpan;
    if (span is TextSpan) {
      _checkSpanContrast(span, baseColor, background);
    } else if (widget.data?.trim().isNotEmpty == true) {
      _expectTextColor(widget.data!, baseColor, background);
    }
  }
}

Color _backgroundForTextColor(Color foreground, ColorScheme colors) {
  if (foreground == colors.onPrimary) return colors.primary;
  if (foreground == colors.onSecondary) return colors.secondary;
  if (foreground == colors.onTertiary) return colors.tertiary;
  if (foreground == colors.onError) return colors.error;
  if (foreground == colors.onPrimaryContainer) return colors.primaryContainer;
  if (foreground == colors.onErrorContainer) return colors.errorContainer;
  return colors.surface;
}

void _checkSpanContrast(TextSpan span, Color inherited, Color background) {
  final color = span.style?.color ?? inherited;
  if (span.text?.trim().isNotEmpty == true) {
    _expectTextColor(span.text!, color, background);
  }
  for (final child in span.children ?? const <InlineSpan>[]) {
    if (child is TextSpan) _checkSpanContrast(child, color, background);
  }
}

void _expectTextColor(String text, Color foreground, Color background) {
  final visibleForeground = Color.alphaBlend(foreground, background);
  expect(
    _contrastRatio(visibleForeground, background),
    greaterThanOrEqualTo(4.5),
    reason: 'Text "$text" does not meet 4.5:1 contrast on the dark surface.',
  );
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
