import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/tutor_profile.dart';
import '../providers/marketplace_providers.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({super.key});

  @override
  ConsumerState<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _headlineController;
  late final TextEditingController _bioController;
  late final TextEditingController _subjectsController;
  late final TextEditingController _levelsController;
  late final TextEditingController _cityController;
  late final TextEditingController _areaController;

  String _mode = 'both'; // 'home' | 'online' | 'both'
  int _experienceYears = 3;
  bool _isPublished = false;
  final Set<String> _selectedDays = {'Mon', 'Wed', 'Fri'};
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _headlineController = TextEditingController();
    _bioController = TextEditingController();
    _subjectsController = TextEditingController();
    _levelsController = TextEditingController();
    _cityController = TextEditingController(text: 'Lahore');
    _areaController = TextEditingController();
  }

  void _initFields(TutorProfile? profile) {
    if (_isInitialized) return;
    if (profile != null) {
      _headlineController.text = profile.headline;
      _bioController.text = profile.bio;
      _subjectsController.text = profile.subjects.join(', ');
      _levelsController.text = profile.levels.join(', ');
      _cityController.text = profile.city.isNotEmpty ? profile.city : 'Lahore';
      _areaController.text = profile.area;
      _mode = profile.mode;
      _experienceYears = profile.experienceYears;
      _isPublished = profile.isPublished;
      _selectedDays.clear();
      _selectedDays.addAll(profile.availableDays);
    }
    _isInitialized = true;
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _bioController.dispose();
    _subjectsController.dispose();
    _levelsController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? '';
      final displayName = user?.displayName ?? 'Tutor';
      final now = DateTime.now();

      final profileState = uid.isNotEmpty ? ref.read(userProfileProvider(uid)) : null;
      final publicId = profileState?.asData?.value?['publicId'] as String? ?? '';

      final profile = TutorProfile(
        uid: uid,
        displayName: displayName,
        publicId: publicId,
        headline: _headlineController.text.trim(),
        bio: _bioController.text.trim(),
        subjects: _subjectsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        levels: _levelsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        mode: _mode,
        experienceYears: _experienceYears,
        availableDays: _selectedDays.toList(),
        isPublished: _isPublished,
        createdAt: now,
        updatedAt: now,
      );

      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.saveTutorProfile(profile);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPublished ? 'Public Profile Published in Tutor Finder!' : 'Profile saved (Hidden from Tutor Finder).'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _required(String? val) =>
      val == null || val.trim().isEmpty ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(currentTutorProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Public Tutor Profile')),
      body: profileState.when(
        data: (profile) {
          _initFields(profile);

          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Visibility Switch Tile
                  Card(
                    color: _isPublished ? AppColors.primaryTeal.withValues(alpha: 0.1) : AppColors.surfaceLight,
                    child: SwitchListTile(
                      activeThumbColor: AppColors.primaryTeal,
                      title: const Text('Visible in Tutor Finder', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_isPublished
                          ? 'Your profile is visible to students and parents searching for tutors.'
                          : 'Your profile is hidden from public search.'),
                      value: _isPublished,
                      onChanged: (val) => setState(() => _isPublished = val),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    label: 'Headline',
                    hint: 'e.g., Experienced O/A Level Math & Physics Specialist',
                    controller: _headlineController,
                    validator: _required,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    label: 'Bio / Teaching Background',
                    hint: 'Describe your qualification, teaching style, and past results...',
                    controller: _bioController,
                    validator: _required,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    label: 'Subjects Taught (comma separated)',
                    hint: 'e.g., Mathematics, Physics, Chemistry',
                    controller: _subjectsController,
                    validator: _required,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    label: 'Classes / Grade Levels (comma separated)',
                    hint: 'e.g., Class 8, Class 9, Class 10, O Levels',
                    controller: _levelsController,
                    validator: _required,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'City',
                          hint: 'e.g., Lahore',
                          controller: _cityController,
                          validator: _required,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppTextField(
                          label: 'Area / Sector',
                          hint: 'e.g., DHA Phase 5',
                          controller: _areaController,
                          validator: _required,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Text('Teaching Mode', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'home', label: Text('Home')),
                      ButtonSegment(value: 'online', label: Text('Online')),
                      ButtonSegment(value: 'both', label: Text('Both')),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (val) => setState(() => _mode = val.first),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Text('Experience: $_experienceYears Years', style: Theme.of(context).textTheme.titleSmall),
                  Slider(
                    value: _experienceYears.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: '$_experienceYears Years',
                    activeColor: AppColors.primaryTeal,
                    onChanged: (val) => setState(() => _experienceYears = val.round()),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Text('Availability Days', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                      final isSel = _selectedDays.contains(day);
                      return FilterChip(
                        label: Text(day),
                        selected: isSel,
                        selectedColor: AppColors.primaryTeal.withValues(alpha: 0.2),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedDays.add(day);
                            } else {
                              _selectedDays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  AppButton.primary(
                    label: _isSaving ? 'Saving Profile...' : 'Save Public Profile',
                    isLoading: _isSaving,
                    isFullWidth: true,
                    onPressed: _isSaving ? null : _save,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
        loading: () => const AppLoader.inline(),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
