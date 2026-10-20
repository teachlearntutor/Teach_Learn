import 'package:cloud_firestore/cloud_firestore.dart';
import 'weekly_class.dart';

class ClassSession {
  final String id;
  final String? classId;
  final String kind; // 'regular' | 'extra' | 'makeup'
  final String date; // 'yyyy-MM-dd'
  final DateTime startAt;
  final DateTime endAt;
  final String status; // 'scheduled' | 'completed' | 'cancelled' | 'rescheduled'
  final String? cancelReason;
  final String? rescheduledFrom;
  final String subject;
  final List<String> studentIds;
  final ClassLocation location;
  final bool attendanceMarked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassSession({
    required this.id,
    this.classId,
    this.kind = 'regular',
    required this.date,
    required this.startAt,
    required this.endAt,
    this.status = 'scheduled',
    this.cancelReason,
    this.rescheduledFrom,
    required this.subject,
    required this.studentIds,
    required this.location,
    this.attendanceMarked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  int get durationMinutes => endAt.difference(startAt).inMinutes;
  DateTime get startsAt => startAt;

  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'kind': kind,
      'date': date,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'status': status,
      'cancelReason': cancelReason,
      'rescheduledFrom': rescheduledFrom,
      'subject': subject,
      'studentIds': studentIds,
      'location': location.toMap(),
      'attendanceMarked': attendanceMarked,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ClassSession.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final locationMap = data['location'] as Map<String, dynamic>? ?? {};

    return ClassSession(
      id: doc.id,
      classId: data['classId'] as String?,
      kind: data['kind'] as String? ?? 'regular',
      date: data['date'] as String? ?? '',
      startAt: _parseDate(data['startAt']),
      endAt: _parseDate(data['endAt']),
      status: data['status'] as String? ?? 'scheduled',
      cancelReason: data['cancelReason'] as String?,
      rescheduledFrom: data['rescheduledFrom'] as String?,
      subject: data['subject'] as String? ?? '',
      studentIds: (data['studentIds'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      location: ClassLocation.fromMap(locationMap),
      attendanceMarked: data['attendanceMarked'] as bool? ?? false,
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

  ClassSession copyWith({
    String? id,
    String? classId,
    String? kind,
    String? date,
    DateTime? startAt,
    DateTime? endAt,
    String? status,
    String? cancelReason,
    String? rescheduledFrom,
    String? subject,
    List<String>? studentIds,
    ClassLocation? location,
    bool? attendanceMarked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassSession(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      kind: kind ?? this.kind,
      date: date ?? this.date,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      rescheduledFrom: rescheduledFrom ?? this.rescheduledFrom,
      subject: subject ?? this.subject,
      studentIds: studentIds ?? this.studentIds,
      location: location ?? this.location,
      attendanceMarked: attendanceMarked ?? this.attendanceMarked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
