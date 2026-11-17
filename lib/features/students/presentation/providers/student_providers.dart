import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/student_repository.dart';
import '../../domain/models/student.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return FirestoreStudentRepository();
});

class StudentsState {
  final List<Student> students;
  final bool hasMore;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final Object? error;

  const StudentsState({
    required this.students,
    required this.hasMore,
    required this.isLoadingInitial,
    required this.isLoadingMore,
    this.error,
  });

  StudentsState copyWith({
    List<Student>? students,
    bool? hasMore,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    Object? error,
  }) {
    return StudentsState(
      students: students ?? this.students,
      hasMore: hasMore ?? this.hasMore,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

class StudentsNotifier extends StateNotifier<StudentsState> {
  final StudentRepository _repository;
  final String _uid;
  String get uid => _uid;

  StudentsNotifier(this._repository, this._uid)
    : super(
        const StudentsState(
          students: [],
          hasMore: true,
          isLoadingInitial: true,
          isLoadingMore: false,
        ),
      ) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (_uid.isEmpty) {
      state = state.copyWith(
        isLoadingInitial: false,
        students: [],
        hasMore: false,
      );
      return;
    }

    state = state.copyWith(isLoadingInitial: true, error: null);
    try {
      final page = await _repository.fetchStudentsPage(_uid, limit: 50);
      state = StudentsState(
        students: page,
        hasMore: page.length >= 50,
        isLoadingInitial: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingInitial: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (_uid.isEmpty ||
        !state.hasMore ||
        state.isLoadingMore ||
        state.isLoadingInitial) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      final lastId = state.students.isNotEmpty ? state.students.last.id : null;
      final newPage = await _repository.fetchStudentsPage(
        _uid,
        limit: 50,
        startAfterId: lastId,
      );

      final combined = [...state.students, ...newPage];
      state = state.copyWith(
        students: combined,
        hasMore: newPage.length >= 50,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> addStudent(Student student) async {
    await _repository.addStudent(_uid, student);
    await loadInitial();
  }

  Future<void> updateStudent(Student student) async {
    await _repository.updateStudent(_uid, student);
    await loadInitial();
  }

  Future<void> deleteStudent(String studentId) async {
    await _repository.deleteStudent(_uid, studentId);
    await loadInitial();
  }
}

final studentsNotifierProvider =
    StateNotifierProvider<StudentsNotifier, StudentsState>((ref) {
      final user = ref.watch(currentAuthUserProvider);
      final uid = user?.uid ?? '';
      return StudentsNotifier(ref.watch(studentRepositoryProvider), uid);
    });

final studentsStreamProvider = StreamProvider<List<Student>>((ref) {
  final user = ref.watch(currentAuthUserProvider);
  final uid = user?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(studentRepositoryProvider).watchStudents(uid);
});

final allActiveStudentsStreamProvider = StreamProvider<List<Student>>((ref) {
  final user = ref.watch(currentAuthUserProvider);
  final uid = user?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(studentRepositoryProvider).watchActiveStudents(uid);
});

final studentsProvider = Provider<AsyncValue<List<Student>>>((ref) {
  final state = ref.watch(studentsNotifierProvider);
  if (state.isLoadingInitial) {
    return const AsyncLoading();
  }
  if (state.error != null) {
    return AsyncError(state.error!, StackTrace.current);
  }
  return AsyncData(state.students);
});

final activeStudentsCountProvider = Provider<int>((ref) {
  final students = ref.watch(studentsProvider).valueOrNull ?? [];
  return students.where((s) => s.status == StudentStatus.active).length;
});
