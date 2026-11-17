import '../../learner/domain/models/learner_preferences.dart';
import 'models/tutor_profile.dart';
import 'tutor_filter.dart' show TutorSortOption;
import 'tutor_location.dart';

class TutorMatchResult {
  final TutorProfile tutor;
  final int matchScore;
  final List<String> matchBadges;

  const TutorMatchResult({
    required this.tutor,
    required this.matchScore,
    required this.matchBadges,
  });
}

List<TutorMatchResult> rankRecommendedTutors({
  required List<TutorProfile> tutors,
  required LearnerPreferences preferences,
  bool showAllTutors = false,
  TutorSortOption sortOption = TutorSortOption.newest,
}) {
  final results = <TutorMatchResult>[];

  final studentClass = preferences.classLevel.trim().toLowerCase();
  final studentCity = preferences.city.trim().toLowerCase();
  final studentArea = preferences.area.trim().toLowerCase();

  for (final tutor in tutors) {
    bool classMatches = false;
    if (studentClass.isNotEmpty) {
      classMatches = tutor.levels.any(
        (l) =>
            l.trim().toLowerCase() == studentClass ||
            l.trim().toLowerCase().contains(studentClass),
      );
    }

    int score = 0;
    final badges = <String>[];

    if (classMatches) {
      score += 100;
      badges.add('Matches your class');
    }

    final tutorCity = tutor.city.trim().toLowerCase();
    final sameCity =
        studentCity.isNotEmpty &&
        tutorCity.isNotEmpty &&
        (tutorCity.contains(studentCity) || studentCity.contains(tutorCity));

    final locationScore = typedLocationScore(
      learnerCity: studentCity,
      learnerArea: studentArea,
      tutor: tutor,
    );

    if (locationScore == 3) {
      score += 80;
      badges.add('In your area');
    } else if (locationScore == 2) {
      score += 60;
      badges.add('Nearby sector');
    } else if (locationScore == 1) {
      score += 40;
      badges.add(sameCity ? 'In your city' : 'In your area');
    }

    if (preferences.neededSubjects.isNotEmpty) {
      final subjectMatches = tutor.subjects
          .where(
            (s) => preferences.neededSubjects.any(
              (ns) => ns.trim().toLowerCase() == s.trim().toLowerCase(),
            ),
          )
          .length;
      score += subjectMatches * 15;
    }

    results.add(
      TutorMatchResult(tutor: tutor, matchScore: score, matchBadges: badges),
    );
  }

  results.sort((a, b) {
    final comp = b.matchScore.compareTo(a.matchScore);
    if (comp != 0) return comp;
    if (sortOption == TutorSortOption.newest) {
      return b.tutor.createdAt.compareTo(a.tutor.createdAt);
    }
    return b.tutor.experienceYears.compareTo(a.tutor.experienceYears);
  });

  return results;
}
