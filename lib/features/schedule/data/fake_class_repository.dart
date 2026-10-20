import 'dart:async';
import '../domain/models/weekly_class.dart';
import 'class_repository.dart';

class FakeClassRepository implements ClassRepository {
  final List<WeeklyClass> _classes = [];
  final _controller = StreamController<List<WeeklyClass>>.broadcast();

  FakeClassRepository([List<WeeklyClass>? initial]) {
    if (initial != null) {
      _classes.addAll(initial);
    }
  }

  void _emit() {
    _controller.add(List.unmodifiable(_classes));
  }

  @override
  Stream<List<WeeklyClass>> watchClasses(String uid) {
    scheduleMicrotask(_emit);
    return _controller.stream;
  }

  @override
  Future<void> addClass(String uid, WeeklyClass weeklyClass) async {
    final newId = weeklyClass.id.isEmpty
        ? 'class_${DateTime.now().millisecondsSinceEpoch}'
        : weeklyClass.id;
    _classes.add(weeklyClass.copyWith(id: newId));
    _emit();
  }

  @override
  Future<void> updateClass(String uid, WeeklyClass weeklyClass) async {
    final index = _classes.indexWhere((c) => c.id == weeklyClass.id);
    if (index != -1) {
      _classes[index] = weeklyClass;
      _emit();
    }
  }

  @override
  Future<void> deleteClass(String uid, String classId) async {
    _classes.removeWhere((c) => c.id == classId);
    _emit();
  }

  void dispose() {
    _controller.close();
  }
}
