enum ClassSessionStatus { scheduled, completed, cancelled }

enum ClassSessionType { regular, extra }

class ClassSession {
  const ClassSession({
    required this.id,
    required this.subject,
    required this.startsAt,
    required this.durationMinutes,
    required this.studentIds,
    this.status = ClassSessionStatus.scheduled,
    this.type = ClassSessionType.regular,
    this.cancellationReason,
  });

  final String id;
  final String subject;
  final DateTime startsAt;
  final int durationMinutes;
  final List<String> studentIds;
  final ClassSessionStatus status;
  final ClassSessionType type;
  final String? cancellationReason;

  DateTime get endsAt => startsAt.add(Duration(minutes: durationMinutes));

  ClassSession copyWith({
    String? subject,
    DateTime? startsAt,
    int? durationMinutes,
    List<String>? studentIds,
    ClassSessionStatus? status,
    ClassSessionType? type,
    String? cancellationReason,
  }) {
    return ClassSession(
      id: id,
      subject: subject ?? this.subject,
      startsAt: startsAt ?? this.startsAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      studentIds: studentIds ?? this.studentIds,
      status: status ?? this.status,
      type: type ?? this.type,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
