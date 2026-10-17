import 'availability_slot.dart';
import 'marketplace_types.dart';

class TutorProfile {
  const TutorProfile({
    required this.id,
    required this.displayName,
    required this.subjects,
    required this.classLevels,
    required this.city,
    required this.area,
    required this.minimumMonthlyFee,
    required this.maximumMonthlyFee,
    required this.currencyCode,
    required this.modes,
    required this.yearsOfExperience,
    required this.bio,
    required this.availability,
    this.photoUrl,
    this.isVerified = false,
    this.averageRating,
    this.ratingCount = 0,
  }) : assert(minimumMonthlyFee >= 0),
       assert(maximumMonthlyFee >= minimumMonthlyFee),
       assert(yearsOfExperience >= 0),
       assert(ratingCount >= 0);

  final String id;
  final String displayName;
  final String? photoUrl;
  final List<String> subjects;
  final List<String> classLevels;
  final String city;
  final String area;
  final int minimumMonthlyFee;
  final int maximumMonthlyFee;
  final String currencyCode;
  final Set<TutoringMode> modes;
  final int yearsOfExperience;
  final String bio;
  final List<AvailabilitySlot> availability;
  final bool isVerified;
  final double? averageRating;
  final int ratingCount;
}
