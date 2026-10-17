import '../domain/models/student.dart';

class InMemoryStudentRepository {
  InMemoryStudentRepository() : _students = _seedStudents();

  final List<Student> _students;

  List<Student> getAll() => List.unmodifiable(_students);

  void add(Student student) {
    _students.add(student);
  }

  void update(Student updatedStudent) {
    final index = _students.indexWhere(
      (student) => student.id == updatedStudent.id,
    );
    if (index >= 0) _students[index] = updatedStudent;
  }

  static List<Student> _seedStudents() {
    final now = DateTime.now();
    return [
      _student(
        'student_1',
        'Ayesha Khan',
        'Class 9',
        'Beaconhouse School',
        ['Mathematics', 'Physics'],
        '0301-555-0101',
        StudentStatus.active,
        now,
        110,
      ),
      _student(
        'student_2',
        'Hamza Raza',
        'Class 8',
        'City School',
        ['Mathematics', 'Science'],
        '0302-555-0102',
        StudentStatus.active,
        now,
        92,
      ),
      _student(
        'student_3',
        'Mariam Iqbal',
        'Class 10',
        'Lahore Grammar School',
        ['Chemistry', 'Biology'],
        '0303-555-0103',
        StudentStatus.active,
        now,
        76,
      ),
      _student(
        'student_4',
        'Zain Ahmed',
        'Class 7',
        'The Educators',
        ['English', 'Mathematics'],
        '0304-555-0104',
        StudentStatus.active,
        now,
        62,
      ),
      _student(
        'student_5',
        'Noor Fatima',
        'Class 11',
        'Punjab College',
        ['Physics', 'Mathematics'],
        '0305-555-0105',
        StudentStatus.active,
        now,
        54,
      ),
      _student(
        'student_6',
        'Usman Ali',
        'Class 6',
        'Roots International',
        ['Science', 'English'],
        '0306-555-0106',
        StudentStatus.active,
        now,
        43,
      ),
      _student(
        'student_7',
        'Hira Malik',
        'Class 9',
        'Lahore Grammar School',
        ['Mathematics', 'Chemistry'],
        '0307-555-0107',
        StudentStatus.paused,
        now,
        38,
      ),
      _student(
        'student_8',
        'Bilal Hussain',
        'Class 8',
        'Beaconhouse School',
        ['English', 'Science'],
        '0308-555-0108',
        StudentStatus.left,
        now,
        180,
      ),
    ];
  }

  static Student _student(
    String id,
    String name,
    String classLevel,
    String schoolName,
    List<String> subjects,
    String parentContact,
    StudentStatus status,
    DateTime now,
    int joinedDaysAgo,
  ) {
    return Student(
      id: id,
      name: name,
      classLevel: classLevel,
      schoolName: schoolName,
      subjects: subjects,
      parentContact: parentContact,
      status: status,
      joinedAt: now.subtract(Duration(days: joinedDaysAgo)),
    );
  }
}
