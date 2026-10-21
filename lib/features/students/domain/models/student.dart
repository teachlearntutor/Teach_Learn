import 'package:cloud_firestore/cloud_firestore.dart';

enum StudentStatus { active, paused, left }

class Student {
  final String id;
  final String code; // e.g. "S-4K2P"
  final String name;
  final String searchName; // lowercase name
  final String classLevel;
  final int classSort; // numeric sorting helper
  final String? school;
  final List<String> subjects;
  final String? parentName;
  final String? parentContact;
  final String? address;
  final String startDate; // "yyyy-MM-dd"
  final StudentStatus status;
  final DateTime? leftAt;
  final String? notes;
  final String? avatarKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Student({
    required this.id,
    required this.code,
    required this.name,
    required this.searchName,
    required this.classLevel,
    required this.classSort,
    this.school,
    required this.subjects,
    this.parentName,
    this.parentContact,
    this.address,
    required this.startDate,
    required this.status,
    this.leftAt,
    this.notes,
    this.avatarKey,
    required this.createdAt,
    required this.updatedAt,
  });

  // Backward compatibility getters for existing UI
  String get schoolName => school ?? '';

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'name': name,
      'searchName': searchName,
      'classLevel': classLevel,
      'classSort': classSort,
      'school': school,
      'subjects': subjects,
      'parentName': parentName,
      'parentContact': parentContact,
      'address': address,
      'startDate': startDate,
      'status': status.name,
      'leftAt': leftAt != null ? Timestamp.fromDate(leftAt!) : null,
      'notes': notes,
      'avatarKey': avatarKey,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Student.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final statusStr = data['status'] as String? ?? 'active';
    final status = StudentStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => StudentStatus.active,
    );

    final nameStr = data['name'] as String? ?? 'Unnamed Student';

    return Student(
      id: doc.id,
      code: data['code'] as String? ?? 'S-${doc.id.substring(0, 4).toUpperCase()}',
      name: nameStr,
      searchName: data['searchName'] as String? ?? nameStr.toLowerCase(),
      classLevel: data['classLevel'] as String? ?? 'Class 9',
      classSort: (data['classSort'] as num? ?? 9).toInt(),
      school: data['school'] as String? ?? data['schoolName'] as String?,
      subjects: (data['subjects'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      parentName: data['parentName'] as String?,
      parentContact: data['parentContact'] as String?,
      address: data['address'] as String?,
      startDate: data['startDate'] as String? ?? '',
      status: status,
      leftAt: _parseDate(data['leftAt']),
      notes: data['notes'] as String?,
      avatarKey: data['avatarKey'] as String?,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) {
      final parsed = DateTime.tryParse(val);
      if (parsed != null) return parsed;
    }
    return null;
  }

  Student copyWith({
    String? id,
    String? code,
    String? name,
    String? searchName,
    String? classLevel,
    int? classSort,
    String? school,
    List<String>? subjects,
    String? parentName,
    String? parentContact,
    String? address,
    String? startDate,
    StudentStatus? status,
    DateTime? leftAt,
    String? notes,
    String? avatarKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      searchName: searchName ?? this.searchName,
      classLevel: classLevel ?? this.classLevel,
      classSort: classSort ?? this.classSort,
      school: school ?? this.school,
      subjects: subjects ?? this.subjects,
      parentName: parentName ?? this.parentName,
      parentContact: parentContact ?? this.parentContact,
      address: address ?? this.address,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
      leftAt: leftAt ?? this.leftAt,
      notes: notes ?? this.notes,
      avatarKey: avatarKey ?? this.avatarKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
