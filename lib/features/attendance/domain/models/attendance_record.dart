import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, leave }

class AttendanceRecord {
  final String id; // '{studentId}_{date}'
  final String studentId;
  final String studentName;
  final String date; // 'yyyy-MM-dd'
  final AttendanceStatus status;
  final String? note;
  final DateTime markedAt;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.status,
    this.note,
    required this.markedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'date': date,
      'status': status.name,
      'note': note,
      'markedAt': Timestamp.fromDate(markedAt),
    };
  }

  factory AttendanceRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final statusStr = data['status'] as String? ?? 'present';
    final status = AttendanceStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => AttendanceStatus.present,
    );

    return AttendanceRecord(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      date: data['date'] as String? ?? '',
      status: status,
      note: data['note'] as String?,
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
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  AttendanceRecord copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? date,
    AttendanceStatus? status,
    String? note,
    DateTime? markedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      date: date ?? this.date,
      status: status ?? this.status,
      note: note ?? this.note,
      markedAt: markedAt ?? this.markedAt,
    );
  }
}
