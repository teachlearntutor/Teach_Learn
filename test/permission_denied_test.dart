import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/core/theme/app_theme.dart';
import 'package:teach_learn/core/utils/error_utils.dart';
import 'package:teach_learn/features/students/data/fake_student_repository.dart';
import 'package:teach_learn/features/students/domain/models/student.dart';
import 'package:teach_learn/features/students/presentation/providers/student_providers.dart';
import 'package:teach_learn/features/students/presentation/screens/students_screen.dart';

class _ThrowingStudentRepository extends FakeStudentRepository {
  final Object errorToThrow;
  _ThrowingStudentRepository(this.errorToThrow);

  @override
  Future<List<Student>> fetchStudentsPage(
    String uid, {
    int limit = 50,
    String? startAfterId,
  }) async {
    throw errorToThrow;
  }
}

void main() {
  group('User-Friendly Permission Denied Error Handling Tests', () {
    test(
      'formatUserFriendlyError maps permission-denied to access message',
      () {
        final permError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Missing or insufficient permissions',
        );

        final msg = formatUserFriendlyError(permError);
        expect(msg, equals("You don't have access to this yet."));
      },
    );

    testWidgets(
      'StudentsScreen shows friendly message when provider emits permission-denied',
      (WidgetTester tester) async {
        final permError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Missing or insufficient permissions',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              studentsNotifierProvider.overrideWith(
                (ref) => StudentsNotifier(
                  _ThrowingStudentRepository(permError),
                  'user_123',
                ),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(body: StudentsScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text("You don't have access to this yet."), findsOneWidget);
        expect(
          find.textContaining(
            'Firestore permission-denied at users/user_123/students',
          ),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
