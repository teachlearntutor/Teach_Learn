import 'models/lesson_request.dart';
import 'models/tutor_profile.dart';
import 'tutor_location.dart';

enum TutorSortOption { recommended, newest }

enum TutorRequestUiState { none, pending, accepted, declined, cancelled }

TutorRequestUiState tutorRequestUiState(LessonRequest? request) {
  if (request == null || request.id.isEmpty) return TutorRequestUiState.none;
  switch (request.status) {
    case LessonRequestStatus.pending:
      return TutorRequestUiState.pending;
    case LessonRequestStatus.accepted:
      return TutorRequestUiState.accepted;
    case LessonRequestStatus.declined:
      return TutorRequestUiState.declined;
    case LessonRequestStatus.cancelled:
      return TutorRequestUiState.cancelled;
  }
}

List<TutorProfile> filterTutors({
  required List<TutorProfile> tutors,
  required String searchQuery,
  required String cityFilter,
  required String areaFilter,
  required String modeFilter,
  required String levelFilter,
  required String subjectFilter,
  Set<String>? levelFilters,
  Set<String>? subjectFilters,
  GeoCoordinates? currentLocation,
  double? radiusKm,
}) {
  final cleanQuery = searchQuery.trim().toLowerCase();
  final cleanCity = cityFilter.trim().toLowerCase();
  final cleanArea = normalizeTutorArea(areaFilter);
  final cleanSubject = subjectFilter.trim().toLowerCase();
  final cleanSubjects =
      subjectFilters
          ?.map(_normalizeSubject)
          .toSet() ??
      const <String>{};
  final cleanLevels =
      levelFilters?.map((level) => level.trim().toLowerCase()).toSet() ??
      const <String>{};

  return tutors.where((tutor) {
    if (currentLocation != null &&
        radiusKm != null &&
        tutor.lat != null &&
        tutor.lng != null &&
        distanceBetweenKm(
              currentLocation,
              GeoCoordinates(latitude: tutor.lat!, longitude: tutor.lng!),
            ) >
            radiusKm) {
      return false;
    }

    // 1. Live search box (name, subject, city, area, public ID)
    if (cleanQuery.isNotEmpty) {
      final searchable = [
        tutor.displayName,
        tutor.publicId,
        tutor.headline,
        tutor.bio,
        tutor.city,
        tutor.area,
        ...tutor.subjects,
        ...tutor.levels,
      ].join(' ').toLowerCase();

      if (!searchable.contains(cleanQuery)) {
        return false;
      }
    }

    // 2. City Filter
    if (cleanCity.isNotEmpty &&
        cleanCity != 'all' &&
        cleanCity != 'all cities') {
      if (!tutor.city.toLowerCase().contains(cleanCity)) {
        return false;
      }
    }

    // 3. Area Filter
    if (cleanArea.isNotEmpty) {
      if (!normalizeTutorArea(tutor.area).contains(cleanArea)) {
        return false;
      }
    }

    // 4. Mode Filter (home / online / both)
    if (modeFilter != 'All' && modeFilter.isNotEmpty) {
      final targetMode = modeFilter.toLowerCase();
      final tutorMode = tutor.mode.toLowerCase();
      if (targetMode == 'both'
          ? tutorMode != 'both'
          : tutorMode != 'both' && tutorMode != targetMode) {
        return false;
      }
    }

    // 5. Class Level Filter
    if (cleanLevels.isNotEmpty) {
      if (!tutor.levels.any((level) => cleanLevels.contains(level.toLowerCase()))) {
        return false;
      }
    } else if (levelFilter != 'All' && levelFilter.isNotEmpty) {
      if (!tutor.levels.any(
        (l) => l.toLowerCase() == levelFilter.toLowerCase(),
      )) {
        return false;
      }
    }

    // 6. Subject Filter
    if (cleanSubjects.isNotEmpty) {
      if (!tutor.subjects.any(
        (subject) => cleanSubjects.contains(_normalizeSubject(subject)),
      )) {
        return false;
      }
    } else if (cleanSubject.isNotEmpty) {
      if (!tutor.subjects.any(
        (subject) => subject.toLowerCase().contains(cleanSubject),
      )) {
        return false;
      }
    }

    return true;
  }).toList();
}

String _normalizeSubject(String subject) => switch (
  subject.trim().toLowerCase()
) {
  'math' || 'mathematics' => 'mathematics',
  'bio' || 'biology' => 'biology',
  'chem' || 'chemistry' => 'chemistry',
  'phys' || 'physics' => 'physics',
  'eng' || 'english' => 'english',
  'computer' || 'computer science' => 'computer science',
  _ => subject.trim().toLowerCase(),
};
