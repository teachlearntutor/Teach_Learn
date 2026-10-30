import 'package:cloud_firestore/cloud_firestore.dart';

enum LessonRequestStatus { pending, accepted, declined, cancelled }

class LessonRequest {
  final String id; // '{fromUid}_{toUid}'
  final String fromUid;
  final String toUid;
  final String fromName;
  final String subject;
  final String message;
  final LessonRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LessonRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.fromName,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'fromUid': fromUid,
      'toUid': toUid,
      'fromName': fromName,
      'subject': subject,
      'message': message,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LessonRequest.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final statusStr = data['status'] as String? ?? 'pending';
    final status = LessonRequestStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => LessonRequestStatus.pending,
    );

    return LessonRequest(
      id: doc.id,
      fromUid: data['fromUid'] as String? ?? '',
      toUid: data['toUid'] as String? ?? '',
      fromName: data['fromName'] as String? ?? 'Learner',
      subject: data['subject'] as String? ?? 'Tuition',
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
    String? fromName,
    String? subject,
    String? message,
    LessonRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonRequest(
      id: id ?? this.id,
      fromUid: fromUid ?? this.fromUid,
      toUid: toUid ?? this.toUid,
      fromName: fromName ?? this.fromName,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
