import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

final userChangesProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.userChanges;
});

final currentUserRoleProvider = FutureProvider.family<String?, String>((ref, uid) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getUserRole(uid);
});

final userProfileProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getUserProfile(uid);
});
