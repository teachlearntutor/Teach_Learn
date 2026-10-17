import 'marketplace_types.dart';

class LessonRequest {
  const LessonRequest({
    required this.id,
    required this.tutorProfileId,
    required this.learnerProfileId,
    required this.requesterAccountId,
    required this.requesterRole,
    required this.createdAt,
    this.message,
    this.status = LessonRequestStatus.pending,
    this.respondedAt,
  }) : assert(requesterRole != AccountRole.tutor);

  final String id;
  final String tutorProfileId;
  final String learnerProfileId;
  final String requesterAccountId;
  final AccountRole requesterRole;
  final DateTime createdAt;
  final String? message;
  final LessonRequestStatus status;
  final DateTime? respondedAt;
}

class TutorStudentLink {
  const TutorStudentLink({
    required this.tutorProfileId,
    required this.learnerProfileId,
    required this.acceptedRequestId,
    required this.connectedAt,
  });

  final String tutorProfileId;
  final String learnerProfileId;
  final String acceptedRequestId;
  final DateTime connectedAt;
}
