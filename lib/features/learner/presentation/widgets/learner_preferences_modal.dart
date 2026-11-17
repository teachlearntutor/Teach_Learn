import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/class_level_picker.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/subject_picker.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/learner_preferences.dart';

export '../../../../core/widgets/class_level_picker.dart'
    show kClassLevelsList;

const List<String> kPakistaniCities = [
  'Lahore',
  'Karachi',
  'Islamabad',
  'Rawalpindi',
  'Faisalabad',
  'Multan',
  'Peshawar',
  'Quetta',
  'Sialkot',
  'Gujranwala',
  'Other',
];

class LearnerPreferencesModal extends ConsumerStatefulWidget {
  const LearnerPreferencesModal({super.key, this.initialPreferences});

  final LearnerPreferences? initialPreferences;

  @override
  ConsumerState<LearnerPreferencesModal> createState() =>
      _LearnerPreferencesModalState();
}

class _LearnerPreferencesModalState
    extends ConsumerState<LearnerPreferencesModal> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedClass;
  late String _selectedCity;
  late final TextEditingController _areaController;
  final Set<String> _selectedSubjects = {};
  String _preferredMode = 'both';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialPreferences;
    _selectedClass = init?.classLevel ?? '';
    _selectedCity = init?.city ?? '';
    _areaController = TextEditingController(text: init?.area ?? '');
    _preferredMode = init?.preferredMode ?? 'both';
    if (init != null) _selectedSubjects.addAll(init.neededSubjects);
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = ref.read(currentAuthUserProvider);
      final uid = user?.uid ?? '';

      final prefs = LearnerPreferences(
        classLevel: _selectedClass,
        neededSubjects: _selectedSubjects.toList(),
        city: _selectedCity,
        area: _areaController.text.trim(),
        preferredMode: _preferredMode,
      );

      if (uid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(prefs.toMap(), SetOptions(merge: true));
        ref.invalidate(userProfileProvider(uid));
      }

      if (!mounted) return;
      Navigator.pop(context, prefs);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find Tutors For Your Class',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Set your grade level and location once to get personalized tutor recommendations.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Class / Grade Level',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              ClassLevelPicker(
                singleSelection: true,
                selectedLevels: _selectedClass.isEmpty
                    ? <String>{}
                    : {_selectedClass},
                onChanged: (levels) => setState(
                  () => _selectedClass = levels.isEmpty ? '' : levels.first,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Subjects Needed',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              SubjectPicker(
                selectedSubjects: _selectedSubjects,
                onChanged: (subjects) => setState(() {
                  _selectedSubjects
                    ..clear()
                    ..addAll(subjects);
                }),
              ),
              const SizedBox(height: AppSpacing.md),

              // City Dropdown & Area Field Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'City',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCity,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Select city'),
                            ),
                            if (_selectedCity.isNotEmpty &&
                                !kPakistaniCities.contains(_selectedCity))
                              DropdownMenuItem(
                                value: _selectedCity,
                                child: Text(_selectedCity),
                              ),
                            ...kPakistaniCities.map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCity = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      label: 'Area / Sector',
                      hint: 'e.g., DHA Phase 5',
                      controller: _areaController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Preferred Tuition Mode',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'home', label: Text('Home')),
                  ButtonSegment(value: 'online', label: Text('Online')),
                  ButtonSegment(value: 'both', label: Text('Both')),
                ],
                selected: {_preferredMode},
                onSelectionChanged: (val) =>
                    setState(() => _preferredMode = val.first),
              ),
              const SizedBox(height: AppSpacing.xl),

              AppButton.primary(
                label: _isSaving
                    ? 'Saving Preferences...'
                    : 'Save & Show Recommended Tutors',
                isLoading: _isSaving,
                isFullWidth: true,
                onPressed: _isSaving ? null : _savePreferences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
