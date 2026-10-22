import 'package:url_launcher/url_launcher.dart';

/// Normalizes Pakistani phone numbers to E.164 international format (+923xxxxxxxx)
String normalizePakistaniPhoneNumber(String input) {
  if (input.trim().isEmpty) return '';

  // Extract digits and leading plus sign
  String digits = input.replaceAll(RegExp(r'[^\d+]'), '');

  if (digits.startsWith('+92')) {
    return digits;
  } else if (digits.startsWith('92') && digits.length >= 12) {
    return '+$digits';
  } else if (digits.startsWith('03') && digits.length == 11) {
    return '+92${digits.substring(1)}';
  } else if (digits.startsWith('3') && digits.length == 10) {
    return '+92$digits';
  }

  return digits.startsWith('+') ? digits : '+$digits';
}

/// Launches phone dialer for parent contact
Future<bool> makePhoneCall(String rawPhoneNumber) async {
  final normalized = normalizePakistaniPhoneNumber(rawPhoneNumber);
  if (normalized.isEmpty) return false;

  final Uri uri = Uri(scheme: 'tel', path: normalized);
  if (await canLaunchUrl(uri)) {
    return await launchUrl(uri);
  }
  return false;
}

/// Launches WhatsApp with pre-filled English message template
Future<bool> launchWhatsAppContact({
  required String rawPhoneNumber,
  required String studentName,
  String? customMessage,
}) async {
  final normalized = normalizePakistaniPhoneNumber(rawPhoneNumber);
  if (normalized.isEmpty) return false;

  final digitsOnly = normalized.replaceAll('+', '');
  final message = customMessage ??
      "Hello, this is TeachLearn regarding $studentName's tuition class. Please let me know if you have any questions.";

  final Uri uri = Uri.parse(
    'https://wa.me/$digitsOnly?text=${Uri.encodeComponent(message)}',
  );

  if (await canLaunchUrl(uri)) {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}
