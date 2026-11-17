class LearnerPreferences {
  final String classLevel;
  final List<String> neededSubjects;
  final String city;
  final String area;
  final String preferredMode; // 'home' | 'online' | 'both'

  const LearnerPreferences({
    required this.classLevel,
    required this.neededSubjects,
    required this.city,
    required this.area,
    required this.preferredMode,
  });

  bool get isComplete =>
      classLevel.isNotEmpty && city.isNotEmpty && preferredMode.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'classLevel': classLevel,
      'neededSubjects': neededSubjects,
      'city': city,
      'area': area,
      'preferredMode': preferredMode,
    };
  }

  factory LearnerPreferences.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const LearnerPreferences(
        classLevel: '',
        neededSubjects: [],
        city: '',
        area: '',
        preferredMode: 'both',
      );
    }

    return LearnerPreferences(
      classLevel: data['classLevel'] as String? ?? '',
      neededSubjects: (data['neededSubjects'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      city: data['city'] as String? ?? '',
      area: data['area'] as String? ?? '',
      preferredMode: data['preferredMode'] as String? ?? 'both',
    );
  }
}
