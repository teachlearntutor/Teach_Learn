import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/core/theme/app_theme.dart';
import 'package:teach_learn/features/students/data/fake_student_repository.dart';
import 'package:teach_learn/features/students/domain/models/student.dart';
import 'package:teach_learn/features/students/presentation/providers/student_providers.dart';
import 'package:teach_learn/features/students/presentation/screens/students_screen.dart';

void main() {
  testWidgets('StudentsScreen paginates 120 students across 3 pages with Load More button', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();

    final testStudents = List.generate(
      120,
      (i) => Student(
        id: 'st_$i',
        code: 'S-$i',
        name: 'Student Number $i',
        searchName: 'student number $i',
        classLevel: 'Class ${(i % 4) + 6}',
        classSort: (i % 4) + 6,
        subjects: const ['Math'],
        startDate: '2026-01-01',
        status: StudentStatus.active,
        createdAt: now.add(Duration(minutes: i)),
        updatedAt: now,
      ),
    );

    final fakeRepo = FakeStudentRepository(testStudents);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentRepositoryProvider.overrideWith((ref) => fakeRepo),
          studentsNotifierProvider.overrideWith(
            (ref) => StudentsNotifier(fakeRepo, 'user_123'),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: StudentsScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final verticalScrollable = find.byType(Scrollable).last;

    // Scroll down to reveal Load More button on Page 1
    await tester.scrollUntilVisible(
      find.text('Load More Students'),
      100.0,
      scrollable: verticalScrollable,
    );

    expect(find.text('Load More Students'), findsOneWidget);

    // Tap "Load More Students" -> Page 2 (100 students)
    await tester.tap(find.text('Load More Students'), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Load More Students'),
      100.0,
      scrollable: verticalScrollable,
    );

    expect(find.text('Load More Students'), findsOneWidget);

    // Tap "Load More Students" -> Page 3 (120 students; button disappears)
    await tester.tap(find.text('Load More Students'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Load More Students'), findsNothing);
  });
}
