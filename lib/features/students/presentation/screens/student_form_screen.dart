import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.student;
    final student = Student(
      id: existing?.id ?? 'student_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      classLevel: _classController.text.trim(),
      schoolName: _schoolController.text.trim(),
      subjects: _subjectsController.text
          .split(',')
          .map((subject) => subject.trim())
          .where((subject) => subject.isNotEmpty)
          .toList(),
      parentContact: _contactController.text.trim(),
      status: _status,
      joinedAt: existing?.joinedAt ?? DateTime.now(),
    );

    final controller = ref.read(studentsProvider.notifier);
    if (existing == null) {
      controller.add(student);
    } else {
      controller.update(student);
    }
    Navigator.of(context).pop();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _validateContact(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid parent contact number';
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
                label: isEditing ? 'Save changes' : 'Add student',
                isFullWidth: true,
                onPressed: _save,
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
