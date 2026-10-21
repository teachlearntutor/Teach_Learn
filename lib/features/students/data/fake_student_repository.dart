import 'dart:async';
import '../domain/models/student.dart';
import 'student_repository.dart';

class FakeStudentRepository implements StudentRepository {
  final List<Student> _students = [];
  final _controller = StreamController<List<Student>>.broadcast();

  FakeStudentRepository([List<Student>? initial]) {
    if (initial != null) _students.addAll(initial);
  }

  void _emit() {
    _controller.add(List.unmodifiable(_students));
  }

  @override
  Stream<List<Student>> watchStudents(String uid) {
    scheduleMicrotask(_emit);
    return _controller.stream;
  }

  @override
  Future<void> addStudent(String uid, Student student) async {
    final newId = student.id.isEmpty
        ? 'student_${DateTime.now().millisecondsSinceEpoch}'
        : student.id;
    _students.add(student.copyWith(id: newId, searchName: student.name.toLowerCase()));
    _emit();
  }

  @override
  Future<void> updateStudent(String uid, Student student) async {
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      _students[index] = student.copyWith(searchName: student.name.toLowerCase());
      _emit();
    }
  }

  @override
  Future<void> deleteStudent(String uid, String studentId) async {
    _students.removeWhere((s) => s.id == studentId);
    _emit();
  }

  void dispose() {
    _controller.close();
  }
}
