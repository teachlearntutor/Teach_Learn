import 'dart:async';

import '../domain/models/student.dart';
import 'student_repository.dart';

class FakeStudentRepository implements StudentRepository {
  final List<Student> _students = [];
  final Map<String, List<String>> _deletedAttendanceStudentIds = {};
  final _controller = StreamController<List<Student>>.broadcast();

  FakeStudentRepository([List<Student>? initial]) {
    if (initial != null) _students.addAll(initial);
  }

  void _emit() {
    _controller.add(List.unmodifiable(_students));
  }

  @override
  Stream<List<Student>> watchStudents(String uid, {int limit = 50}) {
    scheduleMicrotask(() {
      final sorted = List<Student>.from(_students)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _controller.add(List.unmodifiable(sorted.take(limit).toList()));
    });
    return _controller.stream;
  }

  @override
  Stream<List<Student>> watchActiveStudents(String uid) {
    scheduleMicrotask(_emit);
    return _controller.stream.map(
      (students) => students
          .where((student) => student.status == StudentStatus.active)
          .toList(),
    );
  }

  @override
  Future<List<Student>> fetchStudentsPage(
    String uid, {
    int limit = 50,
    String? startAfterId,
  }) async {
    final sorted = List<Student>.from(_students)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int startIndex = 0;
    if (startAfterId != null && startAfterId.isNotEmpty) {
      final idx = sorted.indexWhere((s) => s.id == startAfterId);
      if (idx != -1) {
        startIndex = idx + 1;
      }
    }

    if (startIndex >= sorted.length) return [];
    final endIndex = (startIndex + limit).clamp(0, sorted.length);
    return sorted.sublist(startIndex, endIndex);
  }

  @override
  Future<void> addStudent(String uid, Student student) async {
    final newId = student.id.isEmpty
        ? 'student_${DateTime.now().millisecondsSinceEpoch}'
        : student.id;
    _students.add(
      student.copyWith(id: newId, searchName: student.name.toLowerCase()),
    );
    _emit();
  }

  @override
  Future<void> updateStudent(String uid, Student student) async {
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      _students[index] = student.copyWith(
        searchName: student.name.toLowerCase(),
      );
      _emit();
    }
  }

  @override
  Future<void> deleteStudent(String uid, String studentId) async {
    _students.removeWhere((s) => s.id == studentId);
    _deletedAttendanceStudentIds.putIfAbsent(uid, () => []).add(studentId);
    _emit();
  }

  bool isStudentAttendanceDeleted(String uid, String studentId) {
    return _deletedAttendanceStudentIds[uid]?.contains(studentId) ?? false;
  }

  void dispose() {
    _controller.close();
  }
}
