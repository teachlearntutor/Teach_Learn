import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/student_repository.dart';
import '../../domain/models/student.dart';

final studentRepositoryProvider = Provider<InMemoryStudentRepository>(
  (ref) => InMemoryStudentRepository(),
);

final studentsProvider =
    StateNotifierProvider<StudentController, AsyncValue<List<Student>>>(
      (ref) => StudentController(ref.watch(studentRepositoryProvider)),
    );

class StudentController extends StateNotifier<AsyncValue<List<Student>>> {
  StudentController(this._repository) : super(const AsyncLoading()) {
    _load();
  }

  final InMemoryStudentRepository _repository;

  Future<void> _load() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) state = AsyncData(_repository.getAll());
  }

  void add(Student student) {
    _repository.add(student);
    state = AsyncData(_repository.getAll());
  }

  void update(Student student) {
    _repository.update(student);
    state = AsyncData(_repository.getAll());
  }

  void delete(String studentId) {
    if (state.hasValue) {
      final current = state.value!;
      state = AsyncData(current.where((s) => s.id != studentId).toList());
    }
  }
}
