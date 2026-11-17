import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/core/theme/app_theme.dart';
import 'package:teach_learn/features/students/data/fake_student_repository.dart';
import 'package:teach_learn/features/students/domain/models/student.dart';
import 'package:teach_learn/features/students/presentation/providers/student_providers.dart';
import 'package:teach_learn/features/students/presentation/screens/students_screen.dart';

void main() {
  testWidgets('StudentsScreen widget CRUD: add -> appears, edit -> updates, delete -> disappears', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();

    final testStudent = Student(
      id: 'st_101',
      code: 'S-101',
      name: 'Usman Ali',
      searchName: 'usman ali',
      classLevel: 'Class 9',
      classSort: 9,
      subjects: const ['Mathematics'],
      startDate: '2026-01-01',
      status: StudentStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    final fakeRepo = FakeStudentRepository([testStudent]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentRepositoryProvider.overrideWith((ref) => fakeRepo),
          studentsNotifierProvider.overrideWith((ref) => StudentsNotifier(fakeRepo, 'user_123')),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: StudentsScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Initial render -> "Usman Ali" appears
    expect(find.text('Usman Ali'), findsOneWidget);

    // 2. Add student via repository + notifier -> appears
    final newStudent = Student(
      id: 'st_102',
      code: 'S-102',
      name: 'Bilal Hassan',
      searchName: 'bilal hassan',
      classLevel: 'Class 10',
      classSort: 10,
      subjects: const ['Physics'],
      startDate: '2026-01-01',
      status: StudentStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    final container = ProviderScope.containerOf(tester.element(find.byType(StudentsScreen)));
    await container.read(studentsNotifierProvider.notifier).addStudent(newStudent);
    await tester.pumpAndSettle();

    expect(find.text('Bilal Hassan'), findsOneWidget);

    // 3. Edit student -> updates
    final updatedStudent = newStudent.copyWith(name: 'Bilal Ahmed Hassan');
    await container.read(studentsNotifierProvider.notifier).updateStudent(updatedStudent);
    await tester.pumpAndSettle();

    expect(find.text('Bilal Ahmed Hassan'), findsOneWidget);

    // 4. Delete student -> disappears
    await container.read(studentsNotifierProvider.notifier).deleteStudent('st_102');
    await tester.pumpAndSettle();

    expect(find.text('Bilal Ahmed Hassan'), findsNothing);
  });
}
