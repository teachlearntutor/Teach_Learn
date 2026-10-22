import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/contact_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
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
    _contactController = TextEditingController(
      text: student?.parentContact ?? '',
    );
    _status = student?.status ?? StudentStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _schoolController.dispose();
    _subjectsController.dispose();
    _contactController.dispose();
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
        final existingStudents = ref.read(studentsProvider).value ?? [];
        final normalizedContact = normalizePakistaniPhoneNumber(_contactController.text.trim());

        final isDuplicateName = existingStudents.any((s) => s.name.trim().toLowerCase() == nameStr.toLowerCase());
        final isDuplicateContact = normalizedContact.isNotEmpty && existingStudents.any((s) {
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
      final classSort = classDigitMatch != null ? int.parse(classDigitMatch.group(0)!) : 9;

      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

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
        startDate: existing?.startDate.isNotEmpty == true ? existing!.startDate : todayStr,
        status: _status,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? '';
      final repo = ref.read(studentRepositoryProvider);

      if (existing == null) {
        await repo.addStudent(uid, student);
      } else {
        await repo.updateStudent(uid, student);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null ? 'Student added successfully!' : 'Student profile updated!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _generateStudentCode() {
    final rand = math.Random.secure();
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final code = List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'S-$code';
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

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
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Class level',
                hint: 'For example, Class 9',
                controller: _classController,
                textInputAction: TextInputAction.next,
                validator: _required,
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
              AppTextField(
                label: 'Subjects',
                hint: 'Separate subjects with commas',
                controller: _subjectsController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: _required,
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
