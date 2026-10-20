import 'package:cloud_firestore/cloud_firestore.dart';

class Holiday {
  final String id;
  final String date; // 'yyyy-MM-dd'
  final String? reason;

  const Holiday({
    required this.id,
    required this.date,
    this.reason,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'reason': reason,
    };
  }

  factory Holiday.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Holiday(
      id: doc.id,
      date: data['date'] as String? ?? '',
      reason: data['reason'] as String?,
    );
  }
}
