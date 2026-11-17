import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicTest {
  final String id;
  final String title;
  final String date; // 'yyyy-MM-dd'
  final double totalMarks;
  final double obtainedMarks;
  final String? note;
  final DateTime createdAt;

  const AcademicTest({
    required this.id,
    required this.title,
    required this.date,
    required this.totalMarks,
    required this.obtainedMarks,
    this.note,
    required this.createdAt,
  });

  double get percentage => totalMarks > 0 ? (obtainedMarks / totalMarks) * 100 : 0;

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'date': date,
      'totalMarks': totalMarks,
      'obtainedMarks': obtainedMarks,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AcademicTest.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AcademicTest(
      id: doc.id,
      title: data['title'] as String? ?? '',
      date: data['date'] as String? ?? '',
      totalMarks: (data['totalMarks'] as num? ?? 100).toDouble(),
      obtainedMarks: (data['obtainedMarks'] as num? ?? 0).toDouble(),
      note: data['note'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  AcademicTest copyWith({
    String? id,
    String? title,
    String? date,
    double? totalMarks,
    double? obtainedMarks,
    String? note,
    DateTime? createdAt,
  }) {
    return AcademicTest(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      totalMarks: totalMarks ?? this.totalMarks,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
