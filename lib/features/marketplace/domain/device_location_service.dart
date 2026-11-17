import 'package:geolocator/geolocator.dart';

import 'tutor_location.dart';

enum LocationAccessIssue {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationAccessException implements Exception {
  const LocationAccessException(this.issue);

  final LocationAccessIssue issue;
}

class DeviceLocationService {
  static Future<GeoCoordinates> requestCurrentCoordinates() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationAccessException(LocationAccessIssue.servicesDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationAccessException(
        LocationAccessIssue.permissionDeniedForever,
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationAccessException(LocationAccessIssue.permissionDenied);
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    return GeoCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  static Future<GeoCoordinates?> currentCoordinatesIfAlreadyPermitted() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    return GeoCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
