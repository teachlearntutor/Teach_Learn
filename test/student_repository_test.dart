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
      subjects: const ['Mathematics', 'Physics'],
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

    test('minimal new student payload satisfies validStudent rules', () {
      final minimalStudent = Student(
        id: '',
        code: 'S-NEW1',
        name: '  New student  ',
        searchName: '',
        classLevel: ' Class 1 ',
        classSort: 1,
        subjects: const [],
        startDate: '2026-10-19',
        status: StudentStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final payload = minimalStudent.toFirestore();
      expect(payload['name'], isA<String>());
      expect((payload['name'] as String).length, inInclusiveRange(1, 80));
      expect(payload['name'], equals('New student'));
      expect(payload['status'], anyOf('active', 'paused', 'left'));
      expect(payload['classLevel'], isA<String>());
      expect(payload['subjects'], isA<List>());
      expect((payload['subjects'] as List).length, lessThanOrEqualTo(10));
    });

    test('FakeStudentRepository performs CRUD stream operations and cascade delete', () async {
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
      expect(repo.isStudentAttendanceDeleted('user_123', 'st_1'), equals(true));
    });

    test('FakeStudentRepository pagination test (fetchStudentsPage)', () async {
      final seedList = List.generate(
        120,
        (i) => Student(
          id: 'st_$i',
          code: 'S-$i',
          name: 'Student $i',
          searchName: 'student $i',
          classLevel: 'Class 9',
          classSort: 9,
          subjects: const ['Math'],
          startDate: '2026-01-01',
          status: StudentStatus.active,
          createdAt: now.add(Duration(minutes: i)),
          updatedAt: now,
        ),
      );

      final repo = FakeStudentRepository(seedList);

      // Page 1 -> 50 students
      final page1 = await repo.fetchStudentsPage('user_123', limit: 50);
      expect(page1.length, equals(50));

      // Page 2 -> 50 students starting after last student of page 1
      final page2 = await repo.fetchStudentsPage(
        'user_123',
        limit: 50,
        startAfterId: page1.last.id,
      );
      expect(page2.length, equals(50));

      // Page 3 -> remaining 20 students
      final page3 = await repo.fetchStudentsPage(
        'user_123',
        limit: 50,
        startAfterId: page2.last.id,
      );
      expect(page3.length, equals(20));
    });
  });
}
