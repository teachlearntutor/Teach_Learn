import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/device_location_service.dart';

Future<void> showLocationAccessDialog(
  BuildContext context,
  LocationAccessIssue issue,
) async {
  final servicesDisabled = issue == LocationAccessIssue.servicesDisabled;
  final deniedForever = issue == LocationAccessIssue.permissionDeniedForever;
  final title = servicesDisabled
      ? 'Turn on location services'
      : 'Location permission needed';
  final message = servicesDisabled
      ? 'Turn on your phone location services to find nearby tutors. Your location is only used on this device.'
      : deniedForever
      ? 'Location permission is blocked for Teach Learn. Open app settings to allow location while using the app.'
      : 'Location permission was not granted. You can allow it in app settings to find nearby tutors.';

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            final opened = servicesDisabled
                ? await Geolocator.openLocationSettings()
                : await Geolocator.openAppSettings();
            if (!opened && context.mounted) {
              showAppSnackBar(
                context,
                'Could not open settings. Please open your device settings.',
                isError: true,
              );
            }
          },
          child: const Text('Open settings'),
        ),
      ],
    ),
  );
}
