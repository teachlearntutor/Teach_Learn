import 'dart:async';
import '../domain/models/academic_test.dart';
import 'academic_test_repository.dart';

class FakeAcademicTestRepository implements AcademicTestRepository {
  final List<AcademicTest> _tests = [];
  final _controller = StreamController<List<AcademicTest>>.broadcast();

  FakeAcademicTestRepository([List<AcademicTest>? initial]) {
    if (initial != null) _tests.addAll(initial);
  }

  void _emit() {
    _controller.add(List.unmodifiable(_tests));
  }

  @override
  Stream<List<AcademicTest>> watchAcademicTests(String uid, String studentId) {
    scheduleMicrotask(() => _emit());
    return _controller.stream;
  }

  @override
  Future<void> saveAcademicTest(String uid, String studentId, AcademicTest test) async {
    final newId = test.id.isEmpty ? 'test_${DateTime.now().millisecondsSinceEpoch}' : test.id;
    final testWithId = test.copyWith(id: newId);
    final idx = _tests.indexWhere((t) => t.id == newId);
    if (idx != -1) {
      _tests[idx] = testWithId;
    } else {
      _tests.add(testWithId);
    }
    _emit();
  }

  @override
  Future<void> deleteAcademicTest(String uid, String studentId, String testId) async {
    _tests.removeWhere((t) => t.id == testId);
    _emit();
  }

  void dispose() {
    _controller.close();
  }
}
