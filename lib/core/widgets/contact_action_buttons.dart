import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactActionButtons extends StatelessWidget {
  const ContactActionButtons({
    super.key,
    required this.onCall,
    required this.onWhatsApp,
    this.callLabel = 'Call',
    this.whatsAppLabel = 'WhatsApp',
  });

  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final String callLabel;
  final String whatsAppLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCall,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(Icons.phone_rounded, size: 17),
            label: Text(
              callLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onWhatsApp,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.tertiary,
              foregroundColor: colors.onTertiary,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
            label: Text(
              whatsAppLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
