import 'models/lesson_request.dart';
import 'models/tutor_profile.dart';

enum TutorSortOption { newest, mostExperienced }

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
  required String subjectQuery,
  required String cityQuery,
  required String modeFilter,
  required String levelFilter,
  required String? selectedSubjectChip,
  required int minExperience,
}) {
  return tutors.where((tutor) {
    if (cityQuery.isNotEmpty &&
        !tutor.city.toLowerCase().contains(cityQuery.toLowerCase())) {
      return false;
    }
    if (modeFilter != 'All' &&
        tutor.mode != 'both' &&
        tutor.mode != modeFilter.toLowerCase()) {
      return false;
    }
    if (levelFilter != 'All' &&
        !tutor.levels.any((l) => l.toLowerCase() == levelFilter.toLowerCase())) {
      return false;
    }
    if (tutor.experienceYears < minExperience) {
      return false;
    }
    if (selectedSubjectChip != null &&
        !tutor.subjects.contains(selectedSubjectChip)) {
      return false;
    }
    if (subjectQuery.isNotEmpty) {
      final subjectMatch =
          tutor.subjects.any((s) => s.toLowerCase().contains(subjectQuery));
      final headlineMatch =
          tutor.headline.toLowerCase().contains(subjectQuery);
      final nameMatch =
          tutor.displayName.toLowerCase().contains(subjectQuery);
      return subjectMatch || headlineMatch || nameMatch;
    }
    return true;
  }).toList();
}

List<TutorProfile> sortTutors({
  required List<TutorProfile> tutors,
  required TutorSortOption sortOption,
}) {
  final list = List<TutorProfile>.from(tutors);
  list.sort((a, b) {
    if (sortOption == TutorSortOption.mostExperienced) {
      return b.experienceYears.compareTo(a.experienceYears);
    }
    return b.createdAt.compareTo(a.createdAt);
  });
  return list;
}
