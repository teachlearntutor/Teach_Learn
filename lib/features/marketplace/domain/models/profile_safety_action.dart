import 'marketplace_types.dart';

class ProfileReport {
  const ProfileReport({
    required this.id,
    required this.reporterAccountId,
    required this.targetProfileId,
    required this.reason,
    required this.createdAt,
    this.details,
  });

  final String id;
  final String reporterAccountId;
  final String targetProfileId;
  final ProfileReportReason reason;
  final String? details;
  final DateTime createdAt;
}

class ProfileBlock {
  const ProfileBlock({
    required this.blockingAccountId,
    required this.blockedProfileId,
    required this.createdAt,
  });

  final String blockingAccountId;
  final String blockedProfileId;
  final DateTime createdAt;
}
