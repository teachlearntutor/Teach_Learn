import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/core/widgets/class_level_picker.dart';
import 'package:teach_learn/core/widgets/subject_picker.dart';

void main() {
  testWidgets('class group chip selects all levels in the group', (
    tester,
  ) async {
    final selected = <String>{};

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: ClassLevelPicker(
              selectedLevels: selected,
              onChanged: (levels) => setState(() {
                selected
                  ..clear()
                  ..addAll(levels);
              }),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Class 1-5').first);
    await tester.pumpAndSettle();

    expect(selected, {'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5'});
    expect(find.text('5 selected'), findsOneWidget);
  });

  testWidgets('pre-medical preset selects its complete subject set', (
    tester,
  ) async {
    final selected = <String>{};

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: SingleChildScrollView(
              child: SubjectPicker(
                selectedSubjects: selected,
                onChanged: (subjects) => setState(() {
                  selected
                    ..clear()
                    ..addAll(subjects);
                }),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pre-Medical').first);
    await tester.pumpAndSettle();

    expect(selected, {'Biology', 'Chemistry', 'Physics', 'English', 'Urdu'});
    expect(find.text('5/10'), findsOneWidget);
  });

  testWidgets('presets keep selection within ten and explain truncation', (
    tester,
  ) async {
    final selected = <String>{
      'Algebra',
      'Geometry',
      'Calculus',
      'Statistics',
      'Biology',
      'Chemistry',
      'Physics',
      'Arabic',
      'Persian',
    };
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => SubjectPicker(
                selectedSubjects: selected,
                onChanged: (subjects) => setState(() {
                  selected
                    ..clear()
                    ..addAll(subjects);
                }),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pre-Medical').first);
    await tester.pumpAndSettle();

    expect(
      find.text('Preset exceeds the 10-subject limit; selected the first 10.'),
      findsOneWidget,
    );
    expect(selected.length, 10);
    expect(find.text('10/10'), findsOneWidget);
    expect(find.text('All subjects'), findsNothing);
  });
}
