import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/features/profile/domain/profile_logic.dart';

void main() {
  group('Profile Screen Pure Logic Tests', () {
    test('Change Password row is hidden for Google-only accounts', () {
      expect(shouldShowChangePassword(isGoogleUser: true, isPasswordUser: false), isFalse);
    });

    test('Change Password row is shown for Email/Password accounts', () {
      expect(shouldShowChangePassword(isGoogleUser: false, isPasswordUser: true), isTrue);
    });

    test('Change Password row is shown for accounts with both password and Google auth', () {
      expect(shouldShowChangePassword(isGoogleUser: true, isPasswordUser: true), isTrue);
    });
  });
}
