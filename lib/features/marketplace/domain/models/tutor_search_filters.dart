import 'marketplace_types.dart';

class TutorSearchFilters {
  const TutorSearchFilters({
    this.subject,
    this.classLevel,
    this.city,
    this.minimumMonthlyFee,
    this.maximumMonthlyFee,
    this.modes = const {},
  }) : assert(
         minimumMonthlyFee == null ||
             maximumMonthlyFee == null ||
             minimumMonthlyFee <= maximumMonthlyFee,
       );

  final String? subject;
  final String? classLevel;
  final String? city;
  final int? minimumMonthlyFee;
  final int? maximumMonthlyFee;
  final Set<TutoringMode> modes;
}
