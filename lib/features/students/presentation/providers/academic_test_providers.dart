import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/academic_test_repository.dart';
import '../../domain/models/academic_test.dart';

final academicTestRepositoryProvider = Provider<AcademicTestRepository>((ref) {
  return FirestoreAcademicTestRepository();
});

final studentAcademicTestsStreamProvider =
    StreamProvider.family<List<AcademicTest>, String>((ref, studentId) {
      final user = ref.watch(currentAuthUserProvider);
      final uid = user?.uid ?? '';
      if (uid.isEmpty || studentId.isEmpty) return Stream.value([]);
      return ref
          .watch(academicTestRepositoryProvider)
          .watchAcademicTests(uid, studentId);
    });

final studentAcademicAverageProvider = Provider.family<double, String>((
  ref,
  studentId,
) {
  final tests =
      ref.watch(studentAcademicTestsStreamProvider(studentId)).valueOrNull ??
      [];
  if (tests.isEmpty) return 0.0;
  final totalPct = tests.fold<double>(0.0, (sum, t) => sum + t.percentage);
  return totalPct / tests.length;
});
