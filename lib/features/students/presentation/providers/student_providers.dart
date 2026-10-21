import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/student_repository.dart';
import '../../domain/models/student.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return FirestoreStudentRepository();
});

final studentsStreamProvider = StreamProvider<List<Student>>((ref) {
  try {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? '';
    if (uid.isEmpty) return Stream.value([]);
    return ref.watch(studentRepositoryProvider).watchStudents(uid);
  } catch (_) {
    return Stream.value([]);
  }
});

final studentsProvider = Provider<AsyncValue<List<Student>>>((ref) {
  return ref.watch(studentsStreamProvider);
});

final activeStudentsCountProvider = Provider<int>((ref) {
  final students = ref.watch(studentsProvider).value ?? [];
  return students.where((s) => s.status == StudentStatus.active).length;
});
