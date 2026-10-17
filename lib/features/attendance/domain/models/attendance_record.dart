enum AttendanceStatus { present, absent, late }

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.classSessionId,
    required this.studentId,
    required this.sessionDate,
    required this.status,
    required this.markedAt,
    this.absenceReason,
  });

  final String id;
  final String classSessionId;
  final String studentId;
  final DateTime sessionDate;
  final AttendanceStatus status;
  final DateTime markedAt;
  final String? absenceReason;
}
