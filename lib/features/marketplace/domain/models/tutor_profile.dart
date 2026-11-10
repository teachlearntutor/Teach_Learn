import 'package:cloud_firestore/cloud_firestore.dart';

class TutorProfile {
  final String uid;
  final String displayName;
  final String publicId;
  final String headline;
  final String bio;
  final List<String> subjects;
  final List<String> levels;
  final String city;
  final String area;
  final String mode; // 'home' | 'online' | 'both'
  final int experienceYears;
  final List<String> availableDays;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TutorProfile({
    required this.uid,
    required this.displayName,
    required this.publicId,
    required this.headline,
    required this.bio,
    required this.subjects,
    required this.levels,
    required this.city,
    required this.area,
    required this.mode,
    required this.experienceYears,
    required this.availableDays,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  int get completenessPercentage {
    int score = 0;
    if (headline.trim().isNotEmpty) score += 20;
    if (bio.trim().isNotEmpty) score += 20;
    if (subjects.isNotEmpty) score += 20;
    if (levels.isNotEmpty) score += 20;
    if (city.trim().isNotEmpty && area.trim().isNotEmpty) score += 20;
    return score;
  }

  bool get isCompleteForPublish => completenessPercentage == 100;

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'publicId': publicId,
      'headline': headline,
      'bio': bio,
      'subjects': subjects,
      'levels': levels,
      'city': city,
      'area': area,
      'mode': mode,
      'experienceYears': experienceYears,
      'availableDays': availableDays,
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory TutorProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TutorProfile(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? 'Tutor',
      publicId: data['publicId'] as String? ?? '',
      headline: data['headline'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      subjects: (data['subjects'] as List? ?? []).map((e) => e.toString()).toList(),
      levels: (data['levels'] as List? ?? []).map((e) => e.toString()).toList(),
      city: data['city'] as String? ?? '',
      area: data['area'] as String? ?? '',
      mode: data['mode'] as String? ?? 'both',
      experienceYears: (data['experienceYears'] as num? ?? 1).toInt(),
      availableDays: (data['availableDays'] as List? ?? []).map((e) => e.toString()).toList(),
      isPublished: data['isPublished'] as bool? ?? false,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) {
      final parsed = DateTime.tryParse(val);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  TutorProfile copyWith({
    String? uid,
    String? displayName,
    String? publicId,
    String? headline,
    String? bio,
    List<String>? subjects,
    List<String>? levels,
    String? city,
    String? area,
    String? mode,
    int? experienceYears,
    List<String>? availableDays,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TutorProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      publicId: publicId ?? this.publicId,
      headline: headline ?? this.headline,
      bio: bio ?? this.bio,
      subjects: subjects ?? this.subjects,
      levels: levels ?? this.levels,
      city: city ?? this.city,
      area: area ?? this.area,
      mode: mode ?? this.mode,
      experienceYears: experienceYears ?? this.experienceYears,
      availableDays: availableDays ?? this.availableDays,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
