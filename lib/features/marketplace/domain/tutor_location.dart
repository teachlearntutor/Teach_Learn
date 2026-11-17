import 'dart:math' as math;

import 'models/tutor_profile.dart';

class GeoCoordinates {
  const GeoCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

String normalizeSector(String area) {
  final normalized = area.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  final sector = RegExp(
    r'^(?:sector\s+)?([a-z])\s*-?\s*(\d+)(?:\s*(?:/\s*\d+|-\s*\d+))?(?:\s+markaz(?:\b.*)?)?$',
  ).firstMatch(normalized);
  if (sector != null) {
    return '${sector.group(1)}${sector.group(2)}';
  }
  return normalized;
}

String normalizeTutorArea(String area) =>
    normalizeSector(area).replaceAll(RegExp(r'[\s-]+'), '');

bool tutorAreasMatch(String firstArea, String secondArea) {
  final first = normalizeSector(firstArea);
  final second = normalizeSector(secondArea);
  final firstSector = RegExp(r'^[a-z]\d+$').hasMatch(first);
  final secondSector = RegExp(r'^[a-z]\d+$').hasMatch(second);

  if (firstSector || secondSector) return first == second;

  final normalizedFirst = normalizeTutorArea(firstArea);
  final normalizedSecond = normalizeTutorArea(secondArea);
  return normalizedFirst.contains(normalizedSecond) ||
      normalizedSecond.contains(normalizedFirst);
}

bool areNeighboringSectors(String firstArea, String secondArea) {
  final first = normalizeSector(firstArea);
  final second = normalizeSector(secondArea);
  final firstMatch = RegExp(r'^([a-z])(\d+)$').firstMatch(first);
  final secondMatch = RegExp(r'^([a-z])(\d+)$').firstMatch(second);
  if (firstMatch == null || secondMatch == null || first == second) {
    return false;
  }

  final firstLetter = firstMatch.group(1)!.codeUnitAt(0);
  final secondLetter = secondMatch.group(1)!.codeUnitAt(0);
  final firstNumber = int.parse(firstMatch.group(2)!);
  final secondNumber = int.parse(secondMatch.group(2)!);
  return (firstLetter == secondLetter &&
          (firstNumber - secondNumber).abs() == 1) ||
      (firstNumber == secondNumber && (firstLetter - secondLetter).abs() == 1);
}

double distanceBetweenKm(GeoCoordinates first, GeoCoordinates second) {
  const earthRadiusKm = 6371.0;
  final latitudeDelta = _toRadians(second.latitude - first.latitude);
  final longitudeDelta = _toRadians(second.longitude - first.longitude);
  final firstLatitude = _toRadians(first.latitude);
  final secondLatitude = _toRadians(second.latitude);
  final haversine =
      math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(firstLatitude) *
          math.cos(secondLatitude) *
          math.pow(math.sin(longitudeDelta / 2), 2);
  final boundedHaversine = haversine.clamp(0.0, 1.0);
  return earthRadiusKm *
      2 *
      math.atan2(math.sqrt(boundedHaversine), math.sqrt(1 - boundedHaversine));
}

int typedLocationScore({
  required String learnerCity,
  required String learnerArea,
  required TutorProfile tutor,
}) {
  final city = learnerCity.trim().toLowerCase();
  final tutorCity = tutor.city.trim().toLowerCase();
  final sameCity =
      city.isNotEmpty &&
      tutorCity.isNotEmpty &&
      (city == tutorCity ||
          city.contains(tutorCity) ||
          tutorCity.contains(city));
  final sameArea =
      learnerArea.trim().isNotEmpty && tutorAreasMatch(learnerArea, tutor.area);

  if (sameCity && sameArea) return 3;
  if (sameCity && areNeighboringSectors(learnerArea, tutor.area)) return 2;
  if (sameCity || sameArea) return 1;
  return 0;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
