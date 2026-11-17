import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/contact_utils.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/utils/name_initials.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/class_level_picker.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/subject_picker.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/tutor_profile.dart';
import '../../domain/device_location_service.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/location_access_dialog.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({super.key});

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
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
  String _mode = 'home';
  int _experienceYears = 1;
  bool _isPublished = false;

  bool _isSaving = false;
  bool _isLocationLoading = false;
  bool _isInitialized = false;
  TutorProfile? _existingProfile;
  double? _latitude;
  double? _longitude;

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
    _existingProfile = profile;
    if (profile != null) {
      _headlineController.text = profile.headline;
      _bioController.text = profile.bio;
      _cityController.text = profile.city;
      _areaController.text = profile.area;
      _mode = const {'home', 'online', 'both'}.contains(profile.mode)
          ? profile.mode
          : 'home';
      _experienceYears = profile.experienceYears;
      _isPublished = profile.isPublished;
      _latitude = profile.lat;
      _longitude = profile.lng;
      _selectedSubjects.addAll(profile.subjects);
      _selectedLevels.addAll(profile.levels);
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
    if (_cityController.text.trim().isNotEmpty &&
        _areaController.text.trim().isNotEmpty) {
      score += 20;
    }
    return score;
  }

  bool get _canPublish => _completeness == 100;

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
            Text(
              'Profile Preview (Student View)',
              style: Theme.of(sheetContext).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'This is how your profile will appear to students and parents.',
            ),
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
                            backgroundColor: Theme.of(sheetContext)
                                .colorScheme
                                .primary,
                            child: Text(
                              nameInitials(displayName),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(sheetContext)
                                    .colorScheme
                                    .onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
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
                      const Text(
                        'Approximate area only. Never your exact address.',
                      ),
                      const SizedBox(height: 4),
                      Text('Experience: $_experienceYears Years'),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Bio:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        _bioController.text.isNotEmpty
                            ? _bioController.text
                            : 'No bio provided yet.',
                      ),
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
    if (_selectedSubjects.length > 10 || _selectedLevels.length > 10) {
      showAppSnackBar(
        context,
        'Tutor profiles can include up to 10 subjects and 10 class levels.',
        isError: true,
      );
      return;
    }
    if (_selectedSubjects.isEmpty || _selectedLevels.isEmpty) {
      showAppSnackBar(
        context,
        'Please select at least 1 Subject and 1 Class Level.',
        isError: true,
      );
      return;
    }

    await _persistProfile(
      latitude: _latitude,
      longitude: _longitude,
      closeAfterSave: true,
    );
  }

  Future<bool> _persistProfile({
    required double? latitude,
    required double? longitude,
    bool closeAfterSave = false,
    bool savePrivateContact = true,
    String? successMessage,
  }) async {
    setState(() => _isSaving = true);
    var errorPath = 'tutorProfiles';
    try {
      final user = ref.read(currentAuthUserProvider);
      final uid = user?.uid ?? '';
      if (uid.isEmpty) throw StateError('Sign in to save your profile.');
      errorPath = 'tutorProfiles/$uid';
      final now = DateTime.now();
      final profileState = ref.read(userProfileProvider(uid));
      final publicId = profileState.asData?.value?['publicId'] as String? ?? '';
      final profile = TutorProfile(
        uid: uid,
        displayName: user?.displayName ?? 'Tutor',
        publicId: publicId,
        headline: _headlineController.text.trim(),
        bio: _bioController.text.trim(),
        subjects: _selectedSubjects.toList(),
        levels: _selectedLevels.toList(),
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        mode: _mode,
        lat: latitude,
        lng: longitude,
        experienceYears: _experienceYears,
        availableDays: const [],
        isPublished: _isPublished && _canPublish,
        createdAt: _existingProfile?.createdAt ?? now,
        updatedAt: now,
      );

      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.saveTutorProfile(profile);
      if (savePrivateContact && _phoneController.text.trim().isNotEmpty) {
        errorPath = 'tutorProfiles/$uid/private/contact';
        final normalizedPhone = normalizePakistaniPhoneNumber(
          _phoneController.text.trim(),
        );
        await repo.saveTutorPrivateContact(uid: uid, phone: normalizedPhone);
      }

      if (!mounted) return true;
      setState(() {
        _existingProfile = profile;
        _latitude = latitude;
        _longitude = longitude;
      });
      if (successMessage != null) {
        showAppSnackBar(context, successMessage, isSuccess: true);
      } else if (closeAfterSave) {
        showAppSnackBar(
          context,
          _isPublished
              ? 'Public Profile Published in Tutor Finder!'
              : 'Profile saved (Hidden from search).',
          isSuccess: true,
        );
      }
      if (closeAfterSave) Navigator.pop(context);
      return true;
    } catch (error) {
      if (mounted) {
        final details = formatFirestoreErrorDetails(error, errorPath);
        showAppSnackBar(
          context,
          formatUserFriendlyError(error),
          isError: true,
          diagnostic: details,
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _setCurrentLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      final coordinates =
          await DeviceLocationService.requestCurrentCoordinates();
      final roundedLatitude =
          (coordinates.latitude * 100).roundToDouble() / 100;
      final roundedLongitude =
          (coordinates.longitude * 100).roundToDouble() / 100;
      final previousLatitude = _latitude;
      final previousLongitude = _longitude;
      setState(() {
        _latitude = roundedLatitude;
        _longitude = roundedLongitude;
      });
      final saved = await _persistProfile(
        latitude: roundedLatitude,
        longitude: roundedLongitude,
        savePrivateContact: false,
        successMessage: 'Approximate location saved.',
      );
      if (!saved && mounted) {
        setState(() {
          _latitude = previousLatitude;
          _longitude = previousLongitude;
        });
      }
    } on LocationAccessException catch (error) {
      if (mounted) await showLocationAccessDialog(context, error.issue);
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, formatUserFriendlyError(error), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  Future<void> _clearCurrentLocation() async {
    final previousLatitude = _latitude;
    final previousLongitude = _longitude;
    setState(() {
      _latitude = null;
      _longitude = null;
    });
    final saved = await _persistProfile(
      latitude: null,
      longitude: null,
      savePrivateContact: false,
      successMessage: 'Approximate location cleared.',
    );
    if (!saved && mounted) {
      setState(() {
        _latitude = previousLatitude;
        _longitude = previousLongitude;
      });
    }
  }

  String? _requiredHeadline(String? value) =>
      value == null || value.trim().isEmpty
      ? 'Add a short headline.'
      : value.trim().length > 80
      ? 'Keep the headline under 80 characters.'
      : null;

  String? _requiredBio(String? value) => value == null || value.trim().isEmpty
      ? 'Add a short bio.'
      : value.trim().length > 300
      ? 'Keep the bio under 300 characters.'
      : null;

  String? _requiredLocation(String? value) =>
      value == null || value.trim().isEmpty ? 'Enter this location.' : null;

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(currentTutorProfileProvider);
    final user = ref.watch(currentAuthUserProvider);
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
          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Card(
                    color: _isPublished
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surface,
                    child: SwitchListTile(
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      title: const Text(
                        'Visible in Tutor Finder',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Your phone stays private until you accept a request.',
                      ),
                      value: _isPublished,
                      onChanged: (value) {
                        if (value && !_canPublish) {
                          showAppSnackBar(
                            context,
                            'Add your headline, subjects, classes, location, and bio first.',
                          );
                          return;
                        }
                        setState(() => _isPublished = value);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'About your teaching',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  AppTextField(
                    label: 'Headline',
                    hint: 'A few words about what you teach',
                    controller: _headlineController,
                    validator: _requiredHeadline,
                    maxLength: 80,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Text(
                    'Subjects',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Text('Choose the subjects you teach.'),
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

                  Text(
                    'Class levels',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Text('Choose the classes you teach.'),
                  const SizedBox(height: AppSpacing.xs),
                  ClassLevelPicker(
                    selectedLevels: _selectedLevels,
                    onChanged: (levels) => setState(() {
                      _selectedLevels
                        ..clear()
                        ..addAll(levels);
                    }),
                    maxSelections: 10,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: 'City',
                    hint: 'Enter your city',
                    controller: _cityController,
                    validator: _requiredLocation,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Area',
                    hint: 'Enter your area or sector',
                    controller: _areaController,
                    validator: _requiredLocation,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _latitude != null && _longitude != null
                                    ? 'Location set (approximate)'
                                    : 'Approximate location not set',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            if (_latitude != null || _longitude != null)
                              TextButton(
                                onPressed: _isSaving
                                    ? null
                                    : _clearCurrentLocation,
                                child: const Text('Clear'),
                              ),
                          ],
                        ),
                        const Text(
                          'Approximate area only. Never your exact address.',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: _isSaving || _isLocationLoading
                              ? null
                              : _setCurrentLocation,
                          icon: _isLocationLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded),
                          label: const Text('Use my current location'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Text(
                    'Teaching details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Mode', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'home', label: Text('Home')),
                      ButtonSegment(value: 'online', label: Text('Online')),
                      ButtonSegment(value: 'both', label: Text('Both')),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (values) =>
                        setState(() => _mode = values.first),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Experience: $_experienceYears years',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Slider(
                    value: _experienceYears.toDouble(),
                    min: 0,
                    max: 40,
                    divisions: 40,
                    label: '$_experienceYears years',
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) =>
                        setState(() => _experienceYears = val.round()),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    label: 'Short bio',
                    hint: 'Briefly describe your teaching experience',
                    controller: _bioController,
                    validator: _requiredBio,
                    maxLines: 3,
                    maxLength: 300,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'Private contact',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: 'Phone number',
                    hint: 'Only shared after you accept a request',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  AppButton.primary(
                    label: _isSaving
                        ? 'Saving Profile...'
                        : 'Save Public Profile',
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
        error: (err, _) => Center(
          child: EmptyStateWidget(
            icon: Icons.shield_outlined,
            title: 'Profile Unavailable',
            description: formatUserFriendlyError(err),
            actionLabel: 'Retry',
            onActionPressed: () => ref.invalidate(currentTutorProfileProvider),
          ),
        ),
      ),
    );
  }
}
