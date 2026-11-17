import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/class_level_picker.dart';
import '../../../../core/utils/contact_utils.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/subject_picker.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/models/student.dart';
import '../providers/student_providers.dart';

class StudentFormScreen extends ConsumerStatefulWidget {
  const StudentFormScreen({super.key, this.student});

  final Student? student;

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _classController;
  late final TextEditingController _schoolController;
  late final TextEditingController _subjectsController;
  late final TextEditingController _contactController;
  late final TextEditingController _notesController;
  final Set<String> _selectedSubjects = {};
  late StudentStatus _status;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final student = widget.student;
    _nameController = TextEditingController(text: student?.name ?? '');
    _classController = TextEditingController(text: student?.classLevel ?? '');
    _schoolController = TextEditingController(text: student?.schoolName ?? '');
    _subjectsController = TextEditingController(
      text: student?.subjects.join(', ') ?? '',
    );
    _selectedSubjects.addAll(
      _subjectsController.text
          .split(',')
          .map((subject) => subject.trim())
          .where((subject) => subject.isNotEmpty),
    );
    _contactController = TextEditingController(
      text: student?.parentContact ?? '',
    );
    _notesController = TextEditingController(text: student?.notes ?? '');
    _status = student?.status ?? StudentStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _schoolController.dispose();
    _subjectsController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final existing = widget.student;
      final now = DateTime.now();
      final nameStr = _nameController.text.trim();
      final classStr = _classController.text.trim();

      // Check for duplicates when adding a new student
      if (existing == null) {
        final existingStudents = ref.read(studentsProvider).valueOrNull ?? [];
        final normalizedContact = normalizePakistaniPhoneNumber(
          _contactController.text.trim(),
        );

        final isDuplicateName = existingStudents.any(
          (s) => s.name.trim().toLowerCase() == nameStr.toLowerCase(),
        );
        final isDuplicateContact =
            normalizedContact.isNotEmpty &&
            existingStudents.any((s) {
              final c = normalizePakistaniPhoneNumber(s.parentContact ?? '');
              return c.isNotEmpty && c == normalizedContact;
            });

        if (isDuplicateName || isDuplicateContact) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Duplicate Warning'),
              content: Text(
                isDuplicateName
                    ? 'A student named "$nameStr" already exists. Do you still want to add another student with this name?'
                    : 'A student with parent contact "${_contactController.text.trim()}" already exists. Do you still want to proceed?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Proceed Anyway'),
                ),
              ],
            ),
          );

          if (confirm != true) {
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      // Extract numeric sort digit from class string (e.g. "Class 9" -> 9)
      final classDigitMatch = RegExp(r'\d+').firstMatch(classStr);
      final classSort = classDigitMatch != null
          ? int.parse(classDigitMatch.group(0)!)
          : 9;

      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final student = Student(
        id: existing?.id ?? '',
        code: existing?.code ?? _generateStudentCode(),
        name: nameStr,
        searchName: nameStr.toLowerCase(),
        classLevel: classStr,
        classSort: classSort,
        school: _schoolController.text.trim(),
        subjects: _subjectsController.text
            .split(',')
            .map((subject) => subject.trim())
            .where((subject) => subject.isNotEmpty)
            .toList(),
        parentContact: _contactController.text.trim(),
        startDate: existing?.startDate.isNotEmpty == true
            ? existing!.startDate
            : todayStr,
        status: _status,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      final notifier = ref.read(studentsNotifierProvider.notifier);

      if (existing == null) {
        await notifier.addStudent(student);
      } else {
        await notifier.updateStudent(student);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackBar(
        context,
        existing == null
            ? 'Student added successfully!'
            : 'Student profile updated!',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      final uid = ref.read(studentsNotifierProvider.notifier).uid;
      final details = formatFirestoreErrorDetails(e, 'users/$uid/students');
      showAppSnackBar(
        context,
        formatUserFriendlyError(e),
        isError: true,
        diagnostic: details,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _generateStudentCode() {
    final rand = math.Random.secure();
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final code = List.generate(
      4,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
    return 'S-$code';
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'This field is required';
    if (name.length > 80) return 'Name must be 80 characters or fewer';
    return null;
  }

  String? _validateSubjects(String? value) {
    final count = (value ?? '')
        .split(',')
        .map((subject) => subject.trim())
        .where((subject) => subject.isNotEmpty)
        .length;
    if (count > 10) return 'Enter no more than 10 subjects';
    return null;
  }

  String? _validateClass(String? value) =>
      value == null || value.trim().isEmpty ? 'Class is required' : null;

  String? _validateContact(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid contact number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.student != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit student' : 'Add student')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppTextField(
                label: 'Student name',
                hint: 'Full name',
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: _validateName,
              ),
              const SizedBox(height: AppSpacing.md),
              FormField<Set<String>>(
                initialValue: _classController.text.trim().isEmpty
                    ? <String>{}
                    : {_classController.text.trim()},
                validator: (levels) => _validateClass(
                  levels == null || levels.isEmpty ? '' : levels.first,
                ),
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class level',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    ClassLevelPicker(
                      singleSelection: true,
                      selectedLevels: field.value ?? <String>{},
                      onChanged: (levels) {
                        setState(() {
                          _classController.text = levels.isEmpty
                              ? ''
                              : levels.first;
                        });
                        field.didChange(levels);
                      },
                    ),
                    if (field.errorText != null)
                      Text(
                        field.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'School',
                hint: 'School name',
                controller: _schoolController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.md),
              FormField<Set<String>>(
                initialValue: _selectedSubjects,
                validator: (subjects) =>
                    _validateSubjects(subjects?.join(', ')),
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subjects',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SubjectPicker(
                      selectedSubjects: _selectedSubjects,
                      onChanged: (subjects) {
                        setState(() {
                          _selectedSubjects
                            ..clear()
                            ..addAll(subjects);
                          _subjectsController.text = subjects.join(', ');
                        });
                        field.didChange(subjects);
                      },
                    ),
                    if (field.errorText != null)
                      Text(
                        field.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Parent contact',
                hint: '03xx-xxxxxxx',
                controller: _contactController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: _validateContact,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Private Notes (Optional)',
                hint: 'e.g. Needs extra focus on Organic Chemistry',
                controller: _notesController,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Status', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<StudentStatus>(
                initialValue: _status,
                decoration: const InputDecoration(),
                items: StudentStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(_statusLabel(status)),
                      ),
                    )
                    .toList(),
                onChanged: (status) {
                  if (status != null) setState(() => _status = status);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                label: _isSaving
                    ? 'Saving...'
                    : isEditing
                    ? 'Save changes'
                    : 'Add student',
                isLoading: _isSaving,
                isFullWidth: true,
                onPressed: _isSaving ? null : _save,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

String _statusLabel(StudentStatus status) => switch (status) {
  StudentStatus.active => 'Active',
  StudentStatus.paused => 'Paused',
  StudentStatus.left => 'Left',
};
