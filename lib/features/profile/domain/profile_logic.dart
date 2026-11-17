/// Pure logic for Profile screen UI rules.
bool shouldShowChangePassword({
  required bool isGoogleUser,
  required bool isPasswordUser,
}) {
  final isGoogleOnlyAccount = isGoogleUser && !isPasswordUser;
  return !isGoogleOnlyAccount;
}
