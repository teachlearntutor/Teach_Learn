import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teach_learn/core/widgets/app_button.dart';
import 'package:teach_learn/core/theme/app_theme.dart';
import 'package:teach_learn/features/tutor/presentation/screens/tutor_home_screen.dart';
import 'package:teach_learn/features/auth/presentation/screens/auth_screen.dart';
import 'package:teach_learn/main.dart';

void main() {
  testWidgets('TeachLearnApp opens login after the splash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TeachLearnApp()));

    expect(find.text('TeachLearn'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text("I'm a Tutor"), findsNothing);
  });

  testWidgets('Login defaults to Tutor without a registered role', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: AuthScreen(onThemeModeChanged: (_) {}),
        ),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'tutor@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.ensureVisible(_submitButton('Log in'));
    await tester.pumpAndSettle();
    await tester.tap(_submitButton('Log in'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Home').first, findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('Sign-up role is remembered for login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: AuthScreen(onThemeModeChanged: (_) {}),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("I'm looking for a tutor"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parent'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Jordan Lee');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'parent@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.enterText(find.byType(TextFormField).at(3), 'password123');
    await tester.ensureVisible(_submitButton('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(_submitButton('Create account'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Demo parent authentication succeeded'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Your learning space'), findsOneWidget);

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'parent@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.ensureVisible(_submitButton('Log in'));
    await tester.pumpAndSettle();
    await tester.tap(_submitButton('Log in'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Demo parent authentication succeeded'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Your learning space'), findsOneWidget);
  });

  testWidgets('Branded auth fits a phone viewport in dark mode', (
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
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: AuthScreen(onThemeModeChanged: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Teach. Learn. Track.'), findsOneWidget);
    expect(find.bySemanticsLabel('TeachLearn open-book mark'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text("I'm a Tutor"), findsOneWidget);
    expect(find.text("I'm looking for a tutor"), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text("I'm looking for a tutor"));
    await tester.pumpAndSettle();
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Parent'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tutor students tab shows seeded students and history', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: TutorHomeScreen(onThemeModeChanged: (_) {}),
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
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: TutorHomeScreen(onThemeModeChanged: (_) {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsAtLeastNWidgets(1));
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Fees'), findsNothing);
  });
}

Finder _submitButton(String label) => find.byWidgetPredicate(
  (widget) => widget is AppButton && widget.label == label,
);
