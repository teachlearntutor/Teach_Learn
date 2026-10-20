import 'package:cloud_firestore/cloud_firestore.dart';

class ClassLocation {
  final String type; // 'home' | 'online'
  final String? place;
  final String? link;

  const ClassLocation({
    required this.type,
    this.place,
    this.link,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'place': place,
      'link': link,
    };
  }

  factory ClassLocation.fromMap(Map<String, dynamic> map) {
    return ClassLocation(
      type: map['type'] as String? ?? 'home',
      place: map['place'] as String?,
      link: map['link'] as String?,
    );
  }
}

class WeeklyClass {
  final String id;
  final String? title;
  final String subject;
  final String classLevel;
  final List<String> studentIds;
  final List<int> weekdays; // 1 = Monday .. 7 = Sunday
  final String startTime; // 'HH:mm'
  final int durationMin;
  final String timezone;
  final String startDate; // 'yyyy-MM-dd'
  final String? endDate; // 'yyyy-MM-dd'
  final ClassLocation location;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WeeklyClass({
    required this.id,
    this.title,
    required this.subject,
    required this.classLevel,
    required this.studentIds,
    required this.weekdays,
    required this.startTime,
    required this.durationMin,
    this.timezone = 'Asia/Karachi',
    required this.startDate,
    this.endDate,
    required this.location,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subject': subject,
      'classLevel': classLevel,
      'studentIds': studentIds,
      'weekdays': weekdays,
      'startTime': startTime,
      'durationMin': durationMin,
      'timezone': timezone,
      'startDate': startDate,
      'endDate': endDate,
      'location': location.toMap(),
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory WeeklyClass.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final locationMap = data['location'] as Map<String, dynamic>? ?? {};

    return WeeklyClass(
      id: doc.id,
      title: data['title'] as String?,
      subject: data['subject'] as String? ?? '',
      classLevel: data['classLevel'] as String? ?? '',
      studentIds: (data['studentIds'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      weekdays: (data['weekdays'] as List? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      startTime: data['startTime'] as String? ?? '17:00',
      durationMin: (data['durationMin'] as num? ?? 60).toInt(),
      timezone: data['timezone'] as String? ?? 'Asia/Karachi',
      startDate: data['startDate'] as String? ?? '',
      endDate: data['endDate'] as String?,
      location: ClassLocation.fromMap(locationMap),
      active: data['active'] as bool? ?? true,
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

  WeeklyClass copyWith({
    String? id,
    String? title,
    String? subject,
    String? classLevel,
    List<String>? studentIds,
    List<int>? weekdays,
    String? startTime,
    int? durationMin,
    String? timezone,
    String? startDate,
    String? endDate,
    ClassLocation? location,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeeklyClass(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      classLevel: classLevel ?? this.classLevel,
      studentIds: studentIds ?? this.studentIds,
      weekdays: weekdays ?? this.weekdays,
      startTime: startTime ?? this.startTime,
      durationMin: durationMin ?? this.durationMin,
      timezone: timezone ?? this.timezone,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
