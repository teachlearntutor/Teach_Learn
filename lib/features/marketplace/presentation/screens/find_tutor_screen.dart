import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/models/tutor_profile.dart';
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
  String _cityFilter = 'All';
  String _modeFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilters(TutorProfile tutor) {
    if (_cityFilter != 'All' && tutor.city.toLowerCase() != _cityFilter.toLowerCase()) {
      return false;
    }
    if (_modeFilter != 'All' && tutor.mode != 'both' && tutor.mode != _modeFilter.toLowerCase()) {
      return false;
    }
    if (_subjectQuery.isNotEmpty) {
      final subjectMatch = tutor.subjects.any((s) => s.toLowerCase().contains(_subjectQuery));
      final headlineMatch = tutor.headline.toLowerCase().contains(_subjectQuery);
      final nameMatch = tutor.displayName.toLowerCase().contains(_subjectQuery);
      return subjectMatch || headlineMatch || nameMatch;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final tutorsState = ref.watch(publishedTutorsStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          // Search & Filters Header
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
            child: AppTextField(
              label: 'Search Tutors',
              hint: 'Subject, name, or qualification',
              prefixIcon: const Icon(Icons.search_rounded),
              onChanged: (val) => setState(() => _subjectQuery = val.trim().toLowerCase()),
            ),
          ),

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _cityFilter,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Cities')),
                    DropdownMenuItem(value: 'Lahore', child: Text('Lahore')),
                    DropdownMenuItem(value: 'Karachi', child: Text('Karachi')),
                    DropdownMenuItem(value: 'Islamabad', child: Text('Islamabad')),
                  ],
                  onChanged: (val) => setState(() => _cityFilter = val ?? 'All'),
                ),
                const SizedBox(width: AppSpacing.md),
                FilterChip(
                  label: const Text('All Modes'),
                  selected: _modeFilter == 'All',
                  onSelected: (_) => setState(() => _modeFilter = 'All'),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Home Tuition'),
                  selected: _modeFilter == 'Home',
                  onSelected: (_) => setState(() => _modeFilter = 'Home'),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Online'),
                  selected: _modeFilter == 'Online',
                  onSelected: (_) => setState(() => _modeFilter = 'Online'),
                ),
              ],
            ),
          ),

          Expanded(
            child: tutorsState.when(
              data: (tutors) {
                final filtered = tutors.where(_matchesFilters).toList();

                if (filtered.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.person_search_outlined,
                    title: 'No tutors found',
                    description: 'Try adjusting your subject search or city filters.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final tutor = filtered[index];
                    final initials = tutor.displayName.isNotEmpty
                        ? tutor.displayName[0].toUpperCase()
                        : 'T';

                    return AppCard(
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
                              StatusChip.present(label: tutor.mode.toUpperCase()),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Subjects Chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: tutor.subjects.map((sub) => Container(
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
                            )).toList(),
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          Text(
                            '${tutor.city} (${tutor.area}) • ${tutor.experienceYears} Yrs Experience',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const AppLoader.inline(),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
