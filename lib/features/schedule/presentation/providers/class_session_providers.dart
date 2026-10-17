import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/class_session_repository.dart';
import '../../domain/models/class_session.dart';

final classSessionRepositoryProvider = Provider<InMemoryClassSessionRepository>(
  (ref) => InMemoryClassSessionRepository(),
);

final classSessionsProvider =
    StateNotifierProvider<
      ClassSessionController,
      AsyncValue<List<ClassSession>>
    >(
      (ref) =>
          ClassSessionController(ref.watch(classSessionRepositoryProvider)),
    );

class ClassSessionController
    extends StateNotifier<AsyncValue<List<ClassSession>>> {
  ClassSessionController(this._repository) : super(const AsyncLoading()) {
    _load();
  }

  final InMemoryClassSessionRepository _repository;

  Future<void> _load() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) state = AsyncData(_repository.getAll());
  }

  void add(ClassSession session) {
    _repository.add(session);
    state = AsyncData(_repository.getAll());
  }

  void update(ClassSession session) {
    _repository.update(session);
    state = AsyncData(_repository.getAll());
  }

  void delete(String sessionId) {
    _repository.delete(sessionId);
    state = AsyncData(_repository.getAll());
  }
}
