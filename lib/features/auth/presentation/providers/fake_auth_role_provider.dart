import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FakeAuthRole { tutor, student, parent }

final fakeAuthRoleProvider = StateProvider<FakeAuthRole>(
  (ref) => FakeAuthRole.tutor,
);
