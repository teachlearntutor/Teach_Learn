import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teach_learn/core/widgets/app_button.dart';
import 'package:teach_learn/core/theme/app_theme.dart';
import 'package:teach_learn/features/auth/data/auth_repository.dart';
import 'package:teach_learn/features/auth/presentation/providers/auth_providers.dart';
import 'package:teach_learn/features/tutor/presentation/screens/tutor_home_screen.dart';
import 'package:teach_learn/features/auth/presentation/screens/auth_screen.dart';
import 'package:teach_learn/main.dart';

class _UnauthenticatedAuthRepository extends Fake implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(null);
}

void main() {
  testWidgets('TeachLearnApp opens login screen after splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => _UnauthenticatedAuthRepository(),
          ),
        ],
        child: const TeachLearnApp(),
      ),
    );

    expect(find.text('TeachLearn'), findsAtLeastNWidgets(1));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('AuthScreen validates empty input fields on submission', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );

    await tester.tap(_submitButton('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsAtLeastNWidgets(1));
  });

  testWidgets('Branded auth layout renders cleanly in dark mode', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.darkTheme, home: const AuthScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Teach. Learn. Track.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text("I'm a Tutor"), findsOneWidget);
    expect(find.text("I'm looking for a tutor"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tutor students tab shows seeded students and detail screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TutorHomeScreen(),
        ),
      ),
    );
    await tester.tap(find.text('Students'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Ayesha Khan'), findsOneWidget);
    expect(find.text('Hamza Raza'), findsOneWidget);

    await tester.tap(find.text('Ayesha Khan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Parent contact'), findsOneWidget);
    expect(find.textContaining('% attendance'), findsOneWidget);
  });

  testWidgets('Tutor navigation has five tabs and no Fees tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: TutorHomeScreen())),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsAtLeastNWidgets(1));
    expect(find.text('Students'), findsAtLeastNWidgets(1));
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Fees'), findsNothing);
  });
}

Finder _submitButton(String label) => find.byWidgetPredicate(
  (widget) => widget is AppButton && widget.label == label,
);
