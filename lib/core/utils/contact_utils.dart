import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_snackbar.dart';

/// Formats Pakistani local phone numbers (e.g. 0301-555-0101 or 0300 1234567) to standard E.164 international format +923xx.
String normalizePakistaniPhoneNumber(String rawPhone) {
  final cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');

  if (cleanDigits.isEmpty) return '';

  if (cleanDigits.startsWith('923') && cleanDigits.length == 12) {
    return '+$cleanDigits';
  }

  if (cleanDigits.startsWith('03') && cleanDigits.length == 11) {
    return '+92${cleanDigits.substring(1)}';
  }

  if (cleanDigits.startsWith('3') && cleanDigits.length == 10) {
    return '+92$cleanDigits';
  }

  if (rawPhone.startsWith('+')) {
    return rawPhone;
  }

  return '+$cleanDigits';
}

/// Launches native phone dialer with normalized contact number.
Future<bool> makePhoneCall(String rawPhoneNumber) async {
  final phone = normalizePakistaniPhoneNumber(rawPhoneNumber);
  if (phone.isEmpty) return false;

  final uri = Uri.parse('tel:$phone');
  if (await canLaunchUrl(uri)) {
    return await launchUrl(uri);
  }
  return false;
}

String buildTutorContactWhatsAppMessage(String tutorName) {
  final name = tutorName.trim();
  final greeting = name.isEmpty ? 'Hello' : 'Hello $name';
  return '$greeting, I saw that you accepted my tuition request on Teach Learn. Please let me know the next steps.';
}

/// Launches a WhatsApp chat with the provided contact and message.
Future<bool> launchWhatsAppContact({
  required String rawPhoneNumber,
  required String message,
}) async {
  final phone = normalizePakistaniPhoneNumber(rawPhoneNumber)
      .replaceAll('+', '');
  if (phone.isEmpty) return false;

  final encodedMessage = Uri.encodeComponent(message);
  final whatsappUri = Uri.parse('https://wa.me/$phone?text=$encodedMessage');
  if (await canLaunchUrl(whatsappUri)) {
    return await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
  }
  return false;
}

/// Opens native email app with prefilled mailto and subject line, or copies email to clipboard if unavailable.
Future<void> openEmailApp({
  required String email,
  required String subject,
  required BuildContext context,
}) async {
  final uri = Uri.parse(
    'mailto:$email?subject=${Uri.encodeComponent(subject)}',
  );
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
  } catch (_) {}

  Clipboard.setData(ClipboardData(text: email));
  if (context.mounted) {
    showAppSnackBar(
      context,
      'Email app unavailable. Copied support email "$email" to clipboard.',
      isSuccess: true,
    );
  }
}
