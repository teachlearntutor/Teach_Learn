import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/name_initials.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/class_level_picker.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_staggered_item.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/subject_picker.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../learner/domain/models/learner_preferences.dart';
import '../../../learner/presentation/widgets/learner_preferences_modal.dart';
import '../../domain/device_location_service.dart';
import '../../domain/models/lesson_request.dart';
import '../../domain/models/tutor_profile.dart';
import '../../domain/tutor_filter.dart';
import '../../domain/tutor_location.dart';
import '../../domain/tutor_recommendations.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/location_access_dialog.dart';
import 'tutor_detail_screen.dart';

class FindTutorScreen extends ConsumerStatefulWidget {
  const FindTutorScreen({super.key});

  @override
  ConsumerState<FindTutorScreen> createState() => _FindTutorScreenState();
}

class _FindTutorScreenState extends ConsumerState<FindTutorScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter Sheet Values
  String _cityFilter = 'All';
  String _areaFilter = '';
  String _modeFilter = 'All';
  final Set<String> _levelFilters = {};
  final Set<String> _subjectFilters = {};
  bool _nearMeActive = false;
  GeoCoordinates? _studentLocation;
  double? _radiusKm = 3;
  String? _lastLoggedError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_cityFilter != 'All') count++;
    if (_areaFilter.isNotEmpty) count++;
    if (_modeFilter != 'All') count++;
    if (_levelFilters.isNotEmpty) count++;
    if (_subjectFilters.isNotEmpty) count++;
    if (_nearMeActive) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _cityFilter = 'All';
      _areaFilter = '';
      _modeFilter = 'All';
      _levelFilters.clear();
      _subjectFilters.clear();
      _nearMeActive = false;
      _studentLocation = null;
      _radiusKm = 3;
    });
  }

  void _openFilterBottomSheet() {
    String sheetCity = _cityFilter;
    String sheetMode = _modeFilter;
    final sheetLevels = Set<String>.of(_levelFilters);
    final sheetSubjects = Set<String>.of(_subjectFilters);
    double? sheetRadiusKm = _radiusKm;
    final areaCtrl = TextEditingController(text: _areaFilter);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.sheetBorderRadius,
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Tutors',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          sheetCity = 'All';
                          sheetMode = 'All';
                          sheetLevels.clear();
                          sheetSubjects.clear();
                          sheetRadiusKm = 3;
                          areaCtrl.clear();
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                Text(
                  'Class Level',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                ClassLevelPicker(
                  selectedLevels: sheetLevels,
                  maxSelections: kClassLevelsList.length,
                  onChanged: (levels) => setSheetState(() {
                    sheetLevels
                      ..clear()
                      ..addAll(levels);
                  }),
                ),
                const SizedBox(height: AppSpacing.md),

                // City
                Text('City', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<String>(
                  initialValue: sheetCity,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: ['All Cities', ...kPakistaniCities]
                      .map(
                        (c) => DropdownMenuItem(
                          value: c == 'All Cities' ? 'All' : c,
                          child: Text(c),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => sheetCity = val);
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Area
                AppTextField(
                  label: 'Area / Sector',
                  hint: 'e.g., DHA, Gulberg',
                  controller: areaCtrl,
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Subjects', style: Theme.of(context).textTheme.titleSmall),
                SubjectPicker(
                  selectedSubjects: sheetSubjects,
                  onChanged: (subjects) => setSheetState(() {
                    sheetSubjects
                      ..clear()
                      ..addAll(subjects);
                  }),
                ),
                const SizedBox(height: AppSpacing.md),

                Text(
                  'Near-me radius',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    for (final radius in const [1.0, 3.0, 5.0, 10.0])
                      ChoiceChip(
                        label: Text('${radius.toInt()} km'),
                        selected: sheetRadiusKm == radius,
                        onSelected: (_) =>
                            setSheetState(() => sheetRadiusKm = radius),
                      ),
                    ChoiceChip(
                      label: const Text('Any'),
                      selected: sheetRadiusKm == null,
                      onSelected: (_) =>
                          setSheetState(() => sheetRadiusKm = null),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Mode Segment
                Text(
                  'Tuition Mode',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All')),
                    ButtonSegment(value: 'Home', label: Text('Home')),
                    ButtonSegment(value: 'Online', label: Text('Online')),
                    ButtonSegment(value: 'Both', label: Text('Both')),
                  ],
                  selected: {sheetMode},
                  onSelectionChanged: (val) =>
                      setSheetState(() => sheetMode = val.first),
                ),
                const SizedBox(height: AppSpacing.xl),

                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        label: 'Reset',
                        onPressed: () {
                          setSheetState(() {
                            sheetCity = 'All';
                            sheetMode = 'All';
                            sheetLevels.clear();
                            sheetSubjects.clear();
                            sheetRadiusKm = 3;
                            areaCtrl.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton.primary(
                        label: 'Apply Filters',
                        onPressed: () {
                          setState(() {
                            _cityFilter = sheetCity;
                            _modeFilter = sheetMode;
                            _levelFilters
                              ..clear()
                              ..addAll(sheetLevels);
                            _areaFilter = areaCtrl.text.trim();
                            _subjectFilters
                              ..clear()
                              ..addAll(sheetSubjects);
                            _radiusKm = sheetRadiusKm;
                          });
                          Navigator.pop(sheetContext);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleNearMe(bool selected) async {
    if (!selected) {
      setState(() {
        _nearMeActive = false;
        _studentLocation = null;
      });
      return;
    }

    final consent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Use your location?'),
        content: const Text(
          'Near me is optional. Your location is used only on this device to calculate distances and is never saved or shared. The student location is never stored. Tutor locations are approximate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (!mounted || consent != true) return;

    try {
      final location = await DeviceLocationService.requestCurrentCoordinates();
      if (!mounted) return;
      setState(() {
        _studentLocation = location;
        _nearMeActive = true;
      });
    } on LocationAccessException catch (error) {
      if (mounted) await showLocationAccessDialog(context, error.issue);
    } catch (error) {
      debugPrint('Could not get current location: $error');
      if (mounted) {
        showAppSnackBar(
          context,
          'Could not get your location. You can still search by area or city.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publishedTutorsNotifierProvider);
    final notifier = ref.read(publishedTutorsNotifierProvider.notifier);
    if (state.error == null) _lastLoggedError = null;
    final learnerRequestsState = ref.watch(learnerRequestsStreamProvider);
    final learnerRequests = learnerRequestsState.valueOrNull ?? [];

    final user = ref.watch(currentAuthUserProvider);
    final uid = user?.uid ?? '';
    final userProfileState = uid.isNotEmpty
        ? ref.watch(userProfileProvider(uid))
        : null;
    final userMap = userProfileState?.asData?.value;
    final learnerPrefs = LearnerPreferences.fromMap(userMap);

    final hasActiveFilters = _searchQuery.isNotEmpty || _activeFilterCount > 0;

    // Filter tutors first using real filter function
    final filtered = filterTutors(
      tutors: state.tutors,
      searchQuery: _searchQuery,
      cityFilter: _cityFilter,
      areaFilter: _areaFilter,
      modeFilter: _modeFilter,
      levelFilter: 'All',
      subjectFilter: '',
      levelFilters: _levelFilters,
      subjectFilters: _subjectFilters,
      currentLocation: _nearMeActive ? _studentLocation : null,
      radiusKm: _nearMeActive ? _radiusKm : null,
    );

    // Rank tutors using student class preferences
    final rankedResults = rankRecommendedTutors(
      tutors: filtered,
      preferences: learnerPrefs,
    );
    if (_nearMeActive && _studentLocation != null) {
      rankedResults.sort((first, second) {
        final firstDistance = _distanceToTutor(first.tutor);
        final secondDistance = _distanceToTutor(second.tutor);
        if (firstDistance == null && secondDistance != null) return 1;
        if (firstDistance != null && secondDistance == null) return -1;
        if (firstDistance != null && secondDistance != null) {
          final distanceOrder = firstDistance.compareTo(secondDistance);
          if (distanceOrder != 0) return distanceOrder;
        }
        return second.matchScore.compareTo(first.matchScore);
      });
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await notifier.loadInitial();
        },
        child: Column(
          children: [
            // One Search Box & Filter Button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: AppTextField(
                        label: 'Search by name, city, area, or ID',
                        hint: 'Search by name, city, area, or ID',
                        showLabel: false,
                        controller: _searchController,
                        prefixIcon: const Icon(Icons.search_rounded),
                        onChanged: (val) => setState(
                          () => _searchQuery = val.trim().toLowerCase(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 54),
                      ),
                      onPressed: _openFilterBottomSheet,
                      icon: Badge(
                        isLabelVisible: _activeFilterCount > 0,
                        label: Text('$_activeFilterCount'),
                        child: const Icon(Icons.tune_rounded, size: 18),
                      ),
                      label: const Text('Filters'),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  FilterChip(
                    avatar: const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('Near me'),
                    selected: _nearMeActive,
                    onSelected: _toggleNearMe,
                  ),
                  if (_nearMeActive) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _radiusKm == null
                          ? 'Any distance'
                          : 'Within ${_radiusKm!.toInt()} km',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),

            // Active Filter Chips Row
            if (hasActiveFilters)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 2,
                ),
                child: Row(
                  children: [
                    if (_cityFilter != 'All')
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text(
                            'City: $_cityFilter',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onDeleted: () => setState(() => _cityFilter = 'All'),
                        ),
                      ),
                    if (_levelFilters.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text(
                            'Classes: ${_levelFilters.length}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onDeleted: () =>
                              setState(() => _levelFilters.clear()),
                        ),
                      ),
                    if (_modeFilter != 'All')
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text(
                            'Mode: $_modeFilter',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onDeleted: () => setState(() => _modeFilter = 'All'),
                        ),
                      ),
                    if (_areaFilter.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text(
                            'Area: $_areaFilter',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onDeleted: () => setState(() => _areaFilter = ''),
                        ),
                      ),
                    if (_subjectFilters.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text(
                            'Subjects: ${_subjectFilters.length}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onDeleted: () =>
                              setState(() => _subjectFilters.clear()),
                        ),
                      ),
                    ActionChip(
                      label: Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      onPressed: _clearAllFilters,
                    ),
                  ],
                ),
              ),

            if (state.totalFetched == 100)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Showing first 100 tutors. Use filters to narrow.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

            Expanded(
              child: AnimatedSwitcher(
                duration: MediaQuery.of(context).disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                child: Builder(
                  key: ValueKey(
                    state.isLoadingInitial
                        ? 'loading'
                        : state.error != null
                        ? 'error'
                        : 'loaded',
                  ),
                  builder: (context) {
                    if (state.isLoadingInitial) {
                      return ListView.separated(
                        key: const ValueKey('tutor-list-loading'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: 5,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, _) => AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppLoader.skeleton(width: 170, height: 18),
                              SizedBox(height: AppSpacing.sm),
                              AppLoader.skeleton(
                                width: double.infinity,
                                height: 12,
                              ),
                              SizedBox(height: AppSpacing.sm),
                              AppLoader.skeleton(width: 220, height: 12),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state.error != null) {
                      if (_lastLoggedError != state.error) {
                        debugPrint(
                          'Tutor Finder failed to load profiles: ${state.error}',
                        );
                        _lastLoggedError = state.error;
                      }
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 360,
                            child: EmptyStateWidget(
                              icon: Icons.cloud_off_outlined,
                              title: 'Tutors Unavailable',
                              description: state.error!,
                              actionLabel: 'Retry',
                              onActionPressed: notifier.loadInitial,
                            ),
                          ),
                        ],
                      );
                    }

                    if (rankedResults.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 360,
                            child: EmptyStateWidget(
                              icon: Icons.person_search_outlined,
                              title: hasActiveFilters
                                  ? 'No matching tutors'
                                  : 'No tutors yet',
                              description: hasActiveFilters
                                  ? 'No tutors match your search or filters. Clear filters to see more tutors.'
                                  : 'There are no published tutor profiles yet. Please check back soon.',
                              actionLabel: hasActiveFilters
                                  ? 'Clear filters'
                                  : 'Refresh',
                              onActionPressed: hasActiveFilters
                                  ? _clearAllFilters
                                  : notifier.loadInitial,
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: rankedResults.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == rankedResults.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            child: Center(
                              child: AppButton.secondary(
                                label: state.isLoadingMore
                                    ? 'Loading More...'
                                    : 'Load More Tutors',
                                isLoading: state.isLoadingMore,
                                onPressed: state.isLoadingMore
                                    ? null
                                    : () => notifier.loadMore(),
                              ),
                            ),
                          );
                        }

                        final match = rankedResults[index];
                        final tutor = match.tutor;
                        final initials = nameInitials(tutor.displayName);
                        final isInArea =
                            typedLocationScore(
                              learnerCity: learnerPrefs.city,
                              learnerArea: learnerPrefs.area,
                              tutor: tutor,
                            ) ==
                            3;

                        final existingReq = learnerRequests.firstWhere(
                          (r) => r.toUid == tutor.uid,
                          orElse: () => LessonRequest(
                            id: '',
                            fromUid: '',
                            toUid: '',
                            fromName: '',
                            subject: '',
                            message: '',
                            status: LessonRequestStatus.pending,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );

                        final uiState = tutorRequestUiState(existingReq);
                        final distance = _distanceToTutor(tutor);

                        return AppStaggeredItem(
                          key: ValueKey(tutor.uid),
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        child: Text(
                                          initials,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tutor.displayName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (tutor.headline.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                tutor.headline,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Wrap(
                                    spacing: AppSpacing.xs,
                                    runSpacing: AppSpacing.xs,
                                    children: [
                                      if (uiState != TutorRequestUiState.none)
                                        _smallTutorBadge(
                                          context,
                                          uiState ==
                                                  TutorRequestUiState.accepted
                                              ? 'Accepted'
                                              : uiState.name,
                                        ),
                                      _smallTutorBadge(context, switch (tutor
                                          .mode
                                          .toLowerCase()) {
                                        'online' => 'Online',
                                        'both' => 'Both',
                                        _ => 'Home',
                                      }),
                                      if (isInArea)
                                        _smallTutorBadge(
                                          context,
                                          'In your area',
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: AppSpacing.xs),

                                  // Subjects Chips
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      ...tutor.subjects
                                          .take(3)
                                          .map(
                                            (sub) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                sub,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          ),
                                      if (tutor.subjects.length > 3)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '+${tutor.subjects.length - 3}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),

                                  Text(
                                    'Classes: ${tutor.levels.take(3).join(", ")}${tutor.levels.length > 3 ? " +${tutor.levels.length - 3}" : ""}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${tutor.city} ${tutor.area.isNotEmpty ? "(${tutor.area})" : ""} • ${tutor.experienceYears} Yrs Experience',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  if (_nearMeActive)
                                    Text(
                                      distance == null
                                          ? 'Location not set'
                                          : '${distance.toStringAsFixed(1)} km away',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                TutorDetailScreen(tutor: tutor),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.person_search_outlined,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'View Profile',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallTutorBadge(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  double? _distanceToTutor(TutorProfile tutor) {
    final location = _studentLocation;
    if (location == null || tutor.lat == null || tutor.lng == null) {
      return null;
    }
    return distanceBetweenKm(
      location,
      GeoCoordinates(latitude: tutor.lat!, longitude: tutor.lng!),
    );
  }
}
