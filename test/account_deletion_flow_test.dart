import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/core/theme/app_theme.dart';
import 'package:teach_learn/features/auth/data/auth_repository.dart';
import 'package:teach_learn/features/auth/presentation/providers/auth_providers.dart';
import 'package:teach_learn/features/profile/presentation/screens/profile_screen.dart';

class _DeleteAccountRepository extends Fake implements AuthRepository {
  _DeleteAccountRepository({this.user});

  final User? user;
  final deletion = Completer<void>();
  String? deletedPassword;

  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(user);

  @override
  User? get currentUser => user;

  @override
  Future<void> deleteUserAccount({String? password}) {
    deletedPassword = password;
    return deletion.future;
  }
}

class _PasswordUser extends Fake implements User {
  @override
  String? get displayName => 'Test Tutor';

  @override
  String? get email => 'tutor@example.com';

  @override
  String get uid => 'tutor-1';

  @override
  List<UserInfo> get providerData => [_PasswordProviderInfo()];
}

class _PasswordProviderInfo extends Fake implements UserInfo {
  @override
  String get providerId => 'password';
}

void main() {
  testWidgets('account deletion blocks navigation and shows a friendly error', (
    tester,
  ) async {
    final repository = _DeleteAccountRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWith((ref) => repository)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Delete Account'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    final cancelButton = find.ancestor(
      of: find.text('Cancel'),
      matching: find.byType(OutlinedButton),
    );
    final deleteButton = find.ancestor(
      of: find.text('Delete'),
      matching: find.byType(ElevatedButton),
    );
    expect(
      tester.getSize(cancelButton.first).width,
      closeTo(tester.getSize(deleteButton.first).width, 0.1),
    );
    final deleteStyle = tester
        .widget<ElevatedButton>(deleteButton.first)
        .style!;
    expect(
      deleteStyle.backgroundColor!.resolve({}),
      AppTheme.darkTheme.colorScheme.error,
    );
    await tester.tap(find.text('Delete'));
    await tester.pump();

    expect(find.text('Deleting your account...'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Deleting your account...'), findsOneWidget);

    repository.deletion.completeError(StateError('network failure'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Deleting your account...'), findsNothing);
    expect(
      find.text("Couldn't load. Check your connection and try again."),
      findsOneWidget,
    );
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account deletion confirms success before routing to Login', (
    tester,
  ) async {
    final repository = _DeleteAccountRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWith((ref) => repository)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Delete Account'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump();
    expect(find.text('Deleting your account...'), findsOneWidget);

    repository.deletion.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Account deleted'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Account deleted'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('password users submit the entered password for deletion', (
    tester,
  ) async {
    final repository = _DeleteAccountRepository(user: _PasswordUser());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWith((ref) => repository)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Delete Account'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    expect(find.text('Re-authenticate to Delete Account'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'test-password');
    await tester.tap(find.text('Delete'));
    await tester.pump();

    expect(repository.deletedPassword, 'test-password');
    expect(find.text('Deleting your account...'), findsOneWidget);

    repository.deletion.completeError(StateError('network failure'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Deleting your account...'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
