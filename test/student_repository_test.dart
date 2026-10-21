import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/features/students/data/fake_student_repository.dart';
import 'package:teach_learn/features/students/domain/models/student.dart';

void main() {
  group('Student Repository & Model Tests', () {
    final now = DateTime.now();

    final testStudent = Student(
      id: 'st_1',
      code: 'S-4K2P',
      name: 'Ayesha Khan',
      searchName: 'ayesha khan',
      classLevel: 'Class 9',
      classSort: 9,
      school: 'Beaconhouse School',
      subjects: ['Mathematics', 'Physics'],
      parentName: 'Tariq Khan',
      parentContact: '03015550101',
      address: 'DHA Phase 5, Lahore',
      startDate: '2026-10-19',
      status: StudentStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    test('Student model converts to and from Firestore correctly', () {
      final map = testStudent.toFirestore();
      expect(map['code'], equals('S-4K2P'));
      expect(map['name'], equals('Ayesha Khan'));
      expect(map['searchName'], equals('ayesha khan'));
      expect(map['classSort'], equals(9));
      expect(map['status'], equals('active'));
      expect((map['subjects'] as List).length, equals(2));
    });

    test('FakeStudentRepository performs CRUD stream operations', () async {
      final repo = FakeStudentRepository();

      await repo.addStudent('user_123', testStudent);

      var students = await repo.watchStudents('user_123').first;
      expect(students.length, equals(1));
      expect(students.first.name, equals('Ayesha Khan'));

      final updated = testStudent.copyWith(name: 'Ayesha Tariq Khan');
      await repo.updateStudent('user_123', updated);

      students = await repo.watchStudents('user_123').first;
      expect(students.first.name, equals('Ayesha Tariq Khan'));

      await repo.deleteStudent('user_123', 'st_1');
      students = await repo.watchStudents('user_123').first;
      expect(students.isEmpty, equals(true));
    });
  });
}
