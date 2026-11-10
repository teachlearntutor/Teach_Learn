import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/contact_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/tutor_profile.dart';
import '../providers/marketplace_providers.dart';

const List<String> _kSuggestedSubjects = [
  'Mathematics',
  'Physics',
  'Chemistry',
  'Biology',
  'English',
  'Computer Science',
  'Urdu',
  'Accounting',
];

const List<String> _kSuggestedLevels = [
  'Class 6',
  'Class 7',
  'Class 8',
  'Class 9',
  'Class 10',
  'O Levels',
  'A Levels',
  'FSc',
];

class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({super.key});

  @override
  ConsumerState<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _headlineController;
  late final TextEditingController _bioController;
  late final TextEditingController _cityController;
  late final TextEditingController _areaController;
  late final TextEditingController _phoneController;

  final Set<String> _selectedSubjects = {};
  final Set<String> _selectedLevels = {};
  final Set<String> _selectedDays = {};
  String _mode = 'both'; // 'home' | 'online' | 'both'
  int _experienceYears = 1;
  bool _isPublished = false;

  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _headlineController = TextEditingController();
    _bioController = TextEditingController();
    _cityController = TextEditingController();
    _areaController = TextEditingController();
    _phoneController = TextEditingController();
  }

  void _initFields(TutorProfile? profile) {
    if (_isInitialized) return;
    if (profile != null) {
      _headlineController.text = profile.headline;
      _bioController.text = profile.bio;
      _cityController.text = profile.city;
      _areaController.text = profile.area;
      _mode = profile.mode;
      _experienceYears = profile.experienceYears;
      _isPublished = profile.isPublished;
      _selectedSubjects.addAll(profile.subjects);
      _selectedLevels.addAll(profile.levels);
      _selectedDays.addAll(profile.availableDays);
    }
    _isInitialized = true;
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int get _completeness {
    int score = 0;
    if (_headlineController.text.trim().isNotEmpty) score += 20;
    if (_bioController.text.trim().isNotEmpty) score += 20;
    if (_selectedSubjects.isNotEmpty) score += 20;
    if (_selectedLevels.isNotEmpty) score += 20;
    if (_cityController.text.trim().isNotEmpty && _areaController.text.trim().isNotEmpty) score += 20;
    return score;
  }

  bool get _canPublish => _completeness == 100;

  void _showAddCustomDialog(String title, ValueChanged<String> onAdd) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add Custom $title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter $title name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                onAdd(val);
                setState(() {});
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showPreviewModal(String displayName) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.sheetBorderRadius,
      ),
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.75,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile Preview (Student View)', style: Theme.of(sheetContext).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            const Text('This is how your profile will appear to students and parents.'),
            const SizedBox(height: AppSpacing.md),

            Expanded(
              child: SingleChildScrollView(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primaryTeal,
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(displayName, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 2),
                                Text(
                                  _headlineController.text.isNotEmpty
                                      ? _headlineController.text
                                      : 'Tutor Headline',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          StatusChip.present(label: _mode.toUpperCase()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Subjects: ${_selectedSubjects.join(", ")}'),
                      const SizedBox(height: 4),
                      Text('Classes: ${_selectedLevels.join(", ")}'),
                      const SizedBox(height: 4),
                      Text('Location: ${_cityController.text} (${_areaController.text})'),
                      const SizedBox(height: 4),
                      Text('Experience: $_experienceYears Years'),
                      const SizedBox(height: AppSpacing.md),
                      Text('Bio:', style: Theme.of(context).textTheme.titleSmall),
                      Text(_bioController.text.isNotEmpty ? _bioController.text : 'No bio provided yet.'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.primary(
              label: 'Close Preview',
              isFullWidth: true,
              onPressed: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjects.isEmpty || _selectedLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 Subject and 1 Class Level.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

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
        subjects: _selectedSubjects.toList(),
        levels: _selectedLevels.toList(),
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        mode: _mode,
        experienceYears: _experienceYears,
        availableDays: _selectedDays.toList(),
        isPublished: _isPublished && _canPublish,
        createdAt: now,
        updatedAt: now,
      );

      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.saveTutorProfile(profile);

      if (_phoneController.text.trim().isNotEmpty) {
        final normalizedPhone = normalizePakistaniPhoneNumber(_phoneController.text.trim());
        await repo.saveTutorPrivateContact(uid: uid, phone: normalizedPhone);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPublished ? 'Public Profile Published in Tutor Finder!' : 'Profile saved (Hidden from search).'),
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
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Tutor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Tutor Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined),
            tooltip: 'Preview Profile',
            onPressed: () => _showPreviewModal(displayName),
          ),
        ],
      ),
      body: profileState.when(
        data: (profile) {
          _initFields(profile);
          final pct = _completeness;

          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Profile Completeness Progress Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Profile Completeness', style: Theme.of(context).textTheme.titleSmall),
                              Text('$pct%', style: TextStyle(fontWeight: FontWeight.bold, color: pct == 100 ? AppColors.success : AppColors.warning)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          LinearProgressIndicator(
                            value: pct / 100.0,
                            backgroundColor: AppColors.borderLight,
                            color: pct == 100 ? AppColors.success : AppColors.warning,
                          ),
                          if (pct < 100) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Complete 100% of all fields to publish in Tutor Finder.',
                              style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Visibility Switch Tile
                  Card(
                    color: _isPublished ? AppColors.primaryTeal.withValues(alpha: 0.1) : AppColors.surfaceLight,
                    child: SwitchListTile(
                      activeThumbColor: AppColors.primaryTeal,
                      title: const Text('Visible in Tutor Finder', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_canPublish
                          ? (_isPublished ? 'Profile is visible to searching students.' : 'Profile is complete and ready to publish.')
                          : 'Complete all required fields first to enable visibility.'),
                      value: _isPublished && _canPublish,
                      onChanged: _canPublish
                          ? (val) => setState(() => _isPublished = val)
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    label: 'Headline',
                    hint: 'e.g., Experienced O/A Level Math & Physics Specialist',
                    controller: _headlineController,
                    validator: _required,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    label: 'Bio / Teaching Background',
                    hint: 'Describe your qualification, teaching style, and past results...',
                    controller: _bioController,
                    validator: _required,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    label: 'Private Contact Phone (Optional)',
                    hint: '03xx-xxxxxxx (Shown ONLY after accepting a request)',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Subjects Interactive Chip Picker
                  Text('Subjects Taught', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ..._kSuggestedSubjects.map((sub) {
                        final isSel = _selectedSubjects.contains(sub);
                        return FilterChip(
                          label: Text(sub),
                          selected: isSel,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedSubjects.add(sub);
                              } else {
                                _selectedSubjects.remove(sub);
                              }
                            });
                          },
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: const Text('Custom Subject'),
                        onPressed: () => _showAddCustomDialog('Subject', (val) => _selectedSubjects.add(val)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Classes / Levels Chip Picker
                  Text('Classes / Levels Taught', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ..._kSuggestedLevels.map((lvl) {
                        final isSel = _selectedLevels.contains(lvl);
                        return FilterChip(
                          label: Text(lvl),
                          selected: isSel,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedLevels.add(lvl);
                              } else {
                                _selectedLevels.remove(lvl);
                              }
                            });
                          },
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: const Text('Custom Level'),
                        onPressed: () => _showAddCustomDialog('Level', (val) => _selectedLevels.add(val)),
                      ),
                    ],
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
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppTextField(
                          label: 'Area / Sector',
                          hint: 'e.g., DHA Phase 5',
                          controller: _areaController,
                          validator: _required,
                          onChanged: (_) => setState(() {}),
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
