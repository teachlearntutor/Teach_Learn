enum StudentStatus { active, paused, left }

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.classLevel,
    required this.schoolName,
    required this.subjects,
    required this.parentContact,
    required this.status,
    required this.joinedAt,
  });

  final String id;
  final String name;
  final String classLevel;
  final String schoolName;
  final List<String> subjects;
  final String parentContact;
  final StudentStatus status;
  final DateTime joinedAt;

  Student copyWith({
    String? name,
    String? classLevel,
    String? schoolName,
    List<String>? subjects,
    String? parentContact,
    StudentStatus? status,
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      classLevel: classLevel ?? this.classLevel,
      schoolName: schoolName ?? this.schoolName,
      subjects: subjects ?? this.subjects,
      parentContact: parentContact ?? this.parentContact,
      status: status ?? this.status,
      joinedAt: joinedAt,
    );
  }
}
