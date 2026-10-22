import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../students/presentation/providers/student_providers.dart';
import '../../domain/models/weekly_class.dart';
import '../providers/schedule_providers.dart';

class ClassFormScreen extends ConsumerStatefulWidget {
  const ClassFormScreen({super.key, this.weeklyClass});

  final WeeklyClass? weeklyClass;

  @override
  ConsumerState<ClassFormScreen> createState() => _ClassFormScreenState();
}

class _ClassFormScreenState extends ConsumerState<ClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;
  late final TextEditingController _classLevelController;
  late final TextEditingController _placeController;
  late final TextEditingController _linkController;

  final Set<int> _selectedWeekdays = {1, 3, 5}; // Default: Mon, Wed, Fri
  final Set<String> _selectedStudentIds = {};
  TimeOfDay _startTime = const TimeOfDay(hour: 17, minute: 0);
  int _durationMinutes = 60;
  String _locationType = 'home'; // 'home' | 'online'
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final cls = widget.weeklyClass;
    _titleController = TextEditingController(text: cls?.title ?? '');
    _subjectController = TextEditingController(text: cls?.subject ?? '');
    _classLevelController = TextEditingController(text: cls?.classLevel ?? 'Class 9');
    _placeController = TextEditingController(text: cls?.location.place ?? '');
    _linkController = TextEditingController(text: cls?.location.link ?? '');

    if (cls != null) {
      _selectedWeekdays.clear();
      _selectedWeekdays.addAll(cls.weekdays);
      _selectedStudentIds.addAll(cls.studentIds);
      _durationMinutes = cls.durationMin;
      _locationType = cls.location.type;

      final parts = cls.startTime.split(':');
      if (parts.length == 2) {
        _startTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 17,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _classLevelController.dispose();
    _placeController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day of the week.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? '';
      final now = DateTime.now();

      final existing = widget.weeklyClass;
      final timeStr =
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
      final startDateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final weeklyClass = WeeklyClass(
        id: existing?.id ?? '',
        title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
        subject: _subjectController.text.trim(),
        classLevel: _classLevelController.text.trim(),
        studentIds: _selectedStudentIds.toList(),
        weekdays: _selectedWeekdays.toList()..sort(),
        startTime: timeStr,
        durationMin: _durationMinutes,
        timezone: 'Asia/Karachi',
        startDate: existing?.startDate ?? startDateStr,
        location: ClassLocation(
          type: _locationType,
          place: _locationType == 'home' ? _placeController.text.trim() : null,
          link: _locationType == 'online' ? _linkController.text.trim() : null,
        ),
        active: true,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      final repo = ref.read(classRepositoryProvider);
      if (existing == null) {
        await repo.addClass(uid, weeklyClass);
      } else {
        await repo.updateClass(uid, weeklyClass);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null ? 'Weekly class created!' : 'Class schedule updated!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.weeklyClass != null;
    final studentsState = ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Weekly Class' : 'Add Weekly Class')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppTextField(
                label: 'Subject',
                hint: 'e.g., Mathematics, Physics, Chemistry',
                controller: _subjectController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Class Level',
                hint: 'e.g., Class 9, O Levels',
                controller: _classLevelController,
                textInputAction: TextInputAction.next,
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Custom Title (Optional)',
                hint: 'e.g., Evening Batch A',
                controller: _titleController,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Weekdays Picker
              Text('Recurring Days', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text('Tap to select days of the week', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                children: [
                  _buildWeekdayChip(1, 'Mon', _selectedWeekdays),
                  _buildWeekdayChip(2, 'Tue', _selectedWeekdays),
                  _buildWeekdayChip(3, 'Wed', _selectedWeekdays),
                  _buildWeekdayChip(4, 'Thu', _selectedWeekdays),
                  _buildWeekdayChip(5, 'Fri', _selectedWeekdays),
                  _buildWeekdayChip(6, 'Sat', _selectedWeekdays),
                  _buildWeekdayChip(7, 'Sun', _selectedWeekdays),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Start Time & Duration
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Time', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time_rounded),
                          label: Text(_startTime.format(context)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Duration: $_durationMinutes mins', style: Theme.of(context).textTheme.titleSmall),
                        Slider(
                          value: _durationMinutes.toDouble(),
                          min: 30,
                          max: 180,
                          divisions: 10,
                          label: '$_durationMinutes mins',
                          activeColor: AppColors.primaryTeal,
                          onChanged: (val) => setState(() => _durationMinutes = val.round()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Location Type: Home vs Online
              Text('Location Type', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'home',
                    label: Text('Home Tuition'),
                    icon: Icon(Icons.home_outlined),
                  ),
                  ButtonSegment(
                    value: 'online',
                    label: Text('Online Class'),
                    icon: Icon(Icons.video_call_outlined),
                  ),
                ],
                selected: {_locationType},
                onSelectionChanged: (val) => setState(() => _locationType = val.first),
              ),
              const SizedBox(height: AppSpacing.md),

              if (_locationType == 'home')
                AppTextField(
                  label: 'Home Address / Place (Optional)',
                  hint: 'e.g., DHA Phase 5, House 12',
                  controller: _placeController,
                )
              else
                AppTextField(
                  label: 'Meeting Link (Optional)',
                  hint: 'https://meet.google.com/xyz',
                  controller: _linkController,
                  keyboardType: TextInputType.url,
                ),

              const SizedBox(height: AppSpacing.lg),

              // Enrolled Students Multi-Select Checklist
              Text('Enrolled Students', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              studentsState.when(
                data: (students) {
                  final activeStudents = students.where((s) => s.status.name == 'active').toList();
                  if (activeStudents.isEmpty) {
                    return const Text('No active students available. You can assign students later.');
                  }
                  return Column(
                    children: activeStudents.map((student) {
                      final isSelected = _selectedStudentIds.contains(student.id);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(student.name),
                        subtitle: Text(student.classLevel),
                        activeColor: AppColors.primaryTeal,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedStudentIds.add(student.id);
                            } else {
                              _selectedStudentIds.remove(student.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: AppSpacing.xl),

              AppButton.primary(
                label: _isSaving
                    ? 'Saving Schedule...'
                    : isEditing
                        ? 'Save Changes'
                        : 'Create Class Schedule',
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

  Widget _buildWeekdayChip(int dayNum, String label, Set<int> selectedSet) {
    final isSelected = selectedSet.contains(dayNum);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryTeal.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primaryTeal,
      onSelected: (val) {
        setState(() {
          if (val) {
            selectedSet.add(dayNum);
          } else {
            selectedSet.remove(dayNum);
          }
        });
      },
    );
  }
}
