import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, late }

class AttendanceRecord {
  final String id; // '{sessionId}_{studentId}'
  final String sessionId;
  final String? classId;
  final String studentId;
  final String date; // 'yyyy-MM-dd'
  final DateTime startAt;
  final AttendanceStatus status;
  final String? reason;
  final DateTime markedAt;

  const AttendanceRecord({
    required this.id,
    required this.sessionId,
    this.classId,
    required this.studentId,
    required this.date,
    required this.startAt,
    required this.status,
    this.reason,
    required this.markedAt,
  });

  DateTime get sessionDate => startAt;

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'classId': classId,
      'studentId': studentId,
      'date': date,
      'startAt': Timestamp.fromDate(startAt),
      'status': status.name,
      'reason': reason,
      'markedAt': Timestamp.fromDate(markedAt),
    };
  }

  factory AttendanceRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final statusStr = data['status'] as String? ?? 'present';
    final status = AttendanceStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => AttendanceStatus.present,
    );

    return AttendanceRecord(
      id: doc.id,
      sessionId: data['sessionId'] as String? ?? '',
      classId: data['classId'] as String?,
      studentId: data['studentId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      startAt: _parseDate(data['startAt']),
      status: status,
      reason: data['reason'] as String?,
      markedAt: _parseDate(data['markedAt']),
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

  AttendanceRecord copyWith({
    String? id,
    String? sessionId,
    String? classId,
    String? studentId,
    String? date,
    DateTime? startAt,
    AttendanceStatus? status,
    String? reason,
    DateTime? markedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      classId: classId ?? this.classId,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      startAt: startAt ?? this.startAt,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      markedAt: markedAt ?? this.markedAt,
    );
  }
}
