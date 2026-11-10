import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/core/theme/app_theme.dart';
import 'package:teach_learn/core/utils/error_utils.dart';
import 'package:teach_learn/features/students/presentation/providers/student_providers.dart';
import 'package:teach_learn/features/students/presentation/screens/students_screen.dart';

void main() {
  group('User-Friendly Permission Denied Error Handling Tests', () {
    test('formatUserFriendlyError maps permission-denied to access message', () {
      final permError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions',
      );

      final msg = formatUserFriendlyError(permError);
      expect(msg, equals("You don't have access to this yet."));
    });

    testWidgets('StudentsScreen shows friendly message when provider emits permission-denied', (
      WidgetTester tester,
    ) async {
      final permError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentsStreamProvider.overrideWith(
              (ref) => Stream.error(permError),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: StudentsScreen()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("You don't have access to this yet."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
