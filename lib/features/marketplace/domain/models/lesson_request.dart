import 'package:cloud_firestore/cloud_firestore.dart';

enum LessonRequestStatus { pending, accepted, declined, cancelled }

class LessonRequest {
  final String id; // '{fromUid}_{toUid}'
  final String fromUid;
  final String toUid;
  final String toName;
  final String fromName;
  final String learnerName;
  final String classLevel;
  final String subject;
  final List<String> subjects;
  final String city;
  final String area;
  final String mode;
  final String message;
  final LessonRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LessonRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    this.toName = '',
    required this.fromName,
    this.learnerName = '',
    this.classLevel = '',
    required this.subject,
    this.subjects = const [],
    this.city = '',
    this.area = '',
    this.mode = '',
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'fromUid': fromUid,
      'toUid': toUid,
      'toName': toName,
      'fromName': fromName,
      'learnerName': learnerName,
      'classLevel': classLevel,
      'subject': subject,
      'subjects': subjects,
      'city': city,
      'area': area,
      'mode': mode,
      'message': message,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LessonRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return LessonRequest.fromData(doc.id, doc.data());
  }

  factory LessonRequest.fromData(String id, Map<String, dynamic>? rawData) {
    final data = rawData ?? {};
    final statusStr = data['status'] as String? ?? 'pending';
    final status = LessonRequestStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => LessonRequestStatus.pending,
    );

    return LessonRequest(
      id: id,
      fromUid: data['fromUid'] as String? ?? '',
      toUid: data['toUid'] as String? ?? '',
      toName: data['toName'] as String? ?? '',
      fromName: data['fromName'] as String? ?? 'Learner',
      learnerName:
          data['learnerName'] as String? ??
          data['fromName'] as String? ??
          'Learner',
      classLevel: data['classLevel'] as String? ?? '',
      subject: data['subject'] as String? ?? 'Tuition',
      subjects: (data['subjects'] as List? ?? [])
          .map((value) => value.toString())
          .toList(),
      city: data['city'] as String? ?? '',
      area: data['area'] as String? ?? '',
      mode: data['mode'] as String? ?? '',
      message: data['message'] as String? ?? '',
      status: status,
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

  LessonRequest copyWith({
    String? id,
    String? fromUid,
    String? toUid,
    String? toName,
    String? fromName,
    String? learnerName,
    String? classLevel,
    String? subject,
    List<String>? subjects,
    String? city,
    String? area,
    String? mode,
    String? message,
    LessonRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonRequest(
      id: id ?? this.id,
      fromUid: fromUid ?? this.fromUid,
      toUid: toUid ?? this.toUid,
      toName: toName ?? this.toName,
      fromName: fromName ?? this.fromName,
      learnerName: learnerName ?? this.learnerName,
      classLevel: classLevel ?? this.classLevel,
      subject: subject ?? this.subject,
      subjects: subjects ?? this.subjects,
      city: city ?? this.city,
      area: area ?? this.area,
      mode: mode ?? this.mode,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
