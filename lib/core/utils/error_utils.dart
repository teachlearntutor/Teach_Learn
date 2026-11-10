import 'package:firebase_core/firebase_core.dart';

/// Formats exceptions and Firebase errors into user-friendly English messages.
String formatUserFriendlyError(Object? error) {
  if (error == null) {
    return "Couldn't load. Check your connection and try again.";
  }

  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return "You don't have access to this yet.";
    }
    if (error.code == 'network-request-failed') {
      return "Couldn't load. Check your connection and try again.";
    }
  }

  final errStr = error.toString().toLowerCase();
  if (errStr.contains('permission-denied') ||
      errStr.contains('permission_denied') ||
      errStr.contains('insufficient permissions')) {
    return "You don't have access to this yet.";
  }

  return "Couldn't load. Check your connection and try again.";
}
