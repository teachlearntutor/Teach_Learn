import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/models/lesson_request.dart';
import '../../domain/tutor_filter.dart';
import '../providers/marketplace_providers.dart';
import 'tutor_detail_screen.dart';

class FindTutorScreen extends ConsumerStatefulWidget {
  const FindTutorScreen({super.key});

  @override
  ConsumerState<FindTutorScreen> createState() => _FindTutorScreenState();
}

class _FindTutorScreenState extends ConsumerState<FindTutorScreen> {
  final _searchController = TextEditingController();
  String _subjectQuery = '';
  String _cityQuery = '';
  String _modeFilter = 'All';
  String _levelFilter = 'All';
  String? _selectedSubjectChip;
  int _minExperience = 0;
  TutorSortOption _sortOption = TutorSortOption.newest;
  int _autoFetchCount = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _subjectQuery = '';
      _cityQuery = '';
      _modeFilter = 'All';
      _levelFilter = 'All';
      _selectedSubjectChip = null;
      _minExperience = 0;
      _sortOption = TutorSortOption.newest;
      _autoFetchCount = 0;
    });
  }

  void _checkAutoFetch(int filteredLength, PublishedTutorsNotifier notifier, PublishedTutorsState state) {
    if (filteredLength < 10 && state.hasMore && !state.isLoadingMore && _autoFetchCount < 5) {
      _autoFetchCount++;
      Future.microtask(() => notifier.loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publishedTutorsNotifierProvider);
    final notifier = ref.read(publishedTutorsNotifierProvider.notifier);
    final learnerRequestsState = ref.watch(learnerRequestsStreamProvider);
    final learnerRequests = learnerRequestsState.value ?? [];

    final hasActiveFilters = _subjectQuery.isNotEmpty ||
        _cityQuery.isNotEmpty ||
        _modeFilter != 'All' ||
        _levelFilter != 'All' ||
        _selectedSubjectChip != null ||
        _minExperience > 0;

    // Build dynamic class levels list combining defaults and levels from loaded tutors
    final Set<String> dynamicLevels = {'Class 8', 'Class 9', 'Class 10', 'Class 11', 'O Levels', 'A Levels'};
    for (final t in state.tutors) {
      dynamicLevels.addAll(t.levels);
    }
    final levelList = ['All Levels', ...dynamicLevels];

    final filtered = filterTutors(
      tutors: state.tutors,
      subjectQuery: _subjectQuery,
      cityQuery: _cityQuery,
      modeFilter: _modeFilter,
      levelFilter: _levelFilter,
      selectedSubjectChip: _selectedSubjectChip,
      minExperience: _minExperience,
    );

    final sorted = sortTutors(tutors: filtered, sortOption: _sortOption);

    _checkAutoFetch(sorted.length, notifier, state);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _autoFetchCount = 0;
          await notifier.loadInitial();
        },
        child: Column(
          children: [
            // Search & Sort Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Search Tutors',
                      hint: 'Subject, name, or qualification',
                      controller: _searchController,
                      prefixIcon: const Icon(Icons.search_rounded),
                      onChanged: (val) => setState(() => _subjectQuery = val.trim().toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  PopupMenuButton<TutorSortOption>(
                    icon: const Icon(Icons.sort_rounded),
                    tooltip: 'Sort Tutors',
                    onSelected: (opt) => setState(() => _sortOption = opt),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: TutorSortOption.newest, child: Text('Sort by Newest')),
                      PopupMenuItem(value: TutorSortOption.mostExperienced, child: Text('Sort by Experience')),
                    ],
                  ),
                ],
              ),
            ),

            // City Search & Minimum Experience Slider Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Filter by City/Area',
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 16),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) => setState(() => _cityQuery = val.trim()),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  PopupMenuButton<int>(
                    icon: const Icon(Icons.work_outline_rounded),
                    tooltip: 'Min Experience Filter',
                    onSelected: (exp) => setState(() => _minExperience = exp),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 0, child: Text('Any Experience')),
                      PopupMenuItem(value: 2, child: Text('2+ Years Exp')),
                      PopupMenuItem(value: 5, child: Text('5+ Years Exp')),
                      PopupMenuItem(value: 10, child: Text('10+ Years Exp')),
                    ],
                  ),
                  if (hasActiveFilters) ...[
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                      label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),

            // Mode & Class Level Filter Chips Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Modes'),
                    selected: _modeFilter == 'All',
                    onSelected: (_) => setState(() => _modeFilter = 'All'),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('Home'),
                    selected: _modeFilter == 'Home',
                    onSelected: (_) => setState(() => _modeFilter = 'Home'),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('Online'),
                    selected: _modeFilter == 'Online',
                    onSelected: (_) => setState(() => _modeFilter = 'Online'),
                  ),
                  const SizedBox(width: 12),

                  // Dynamic Class Level Chips
                  ...levelList.map((lvl) {
                    final isSel = (lvl == 'All Levels' && _levelFilter == 'All') || _levelFilter == lvl;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(lvl),
                        selected: isSel,
                        onSelected: (val) {
                          setState(() {
                            _levelFilter = val ? (lvl == 'All Levels' ? 'All' : lvl) : 'All';
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.isLoadingInitial) {
                    return const AppLoader.inline();
                  }

                  if (state.error != null) {
                    return Center(
                      child: EmptyStateWidget(
                        icon: Icons.shield_outlined,
                        title: 'Tutors Unavailable',
                        description: 'Could not fetch tutor profiles. Please check security rules or tap retry.',
                        actionLabel: 'Retry',
                        onActionPressed: () => notifier.loadInitial(),
                      ),
                    );
                  }

                  if (sorted.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.person_search_outlined,
                      title: 'No tutors match your search',
                      description: 'Try clearing filters or searching for another subject or city.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: sorted.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == sorted.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(
                            child: AppButton.secondary(
                              label: state.isLoadingMore ? 'Loading More...' : 'Load More Tutors',
                              isLoading: state.isLoadingMore,
                              onPressed: state.isLoadingMore ? null : () => notifier.loadMore(),
                            ),
                          ),
                        );
                      }

                      final tutor = sorted[index];
                      final initials = tutor.displayName.isNotEmpty
                          ? tutor.displayName[0].toUpperCase()
                          : 'T';

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

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => TutorDetailScreen(tutor: tutor),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.primaryTeal,
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tutor.displayName,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        if (tutor.headline.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            tutor.headline,
                                            style: Theme.of(context).textTheme.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (uiState != TutorRequestUiState.none)
                                    StatusChip.present(
                                      label: uiState.name.toUpperCase(),
                                    )
                                  else
                                    StatusChip.present(label: tutor.mode.toUpperCase()),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // Subjects Chips (Max 3 + "+N")
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  ...tutor.subjects.take(3).map((sub) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryTeal.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          sub,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      )),
                                  if (tutor.subjects.length > 3)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.borderLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '+${tutor.subjects.length - 3}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),

                              Text(
                                '${tutor.city} ${tutor.area.isNotEmpty ? "(${tutor.area})" : ""} • ${tutor.experienceYears} Yrs Experience',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
