import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/models/student.dart';
import '../providers/student_providers.dart';
import 'student_detail_screen.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: AppTextField(
            label: 'Search students',
            hint: 'Name, class, school, or subject',
            prefixIcon: const Icon(Icons.search_rounded),
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: ref
              .watch(studentsProvider)
              .when(
                loading: _buildLoading,
                error: (error, stackTrace) => Center(
                  child: EmptyStateWidget(
                    icon: Icons.cloud_off_outlined,
                    title: 'Students are unavailable',
                    description: 'Try loading your student list again.',
                    actionLabel: 'Retry',
                    onActionPressed: () => ref.invalidate(studentsProvider),
                  ),
                ),
                data: (students) {
                  final filtered = students.where(_matchesQuery).toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: EmptyStateWidget(
                        icon: Icons.person_search_outlined,
                        title: _query.isEmpty
                            ? 'No students yet'
                            : 'No matches found',
                        description: _query.isEmpty
                            ? 'Add your first student to start organizing lessons.'
                            : 'Try a different name, class, school, or subject.',
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      96,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => _StudentTile(
                      student: filtered[index],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StudentDetailScreen(
                            studentId: filtered[index].id,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  bool _matchesQuery(Student student) {
    if (_query.isEmpty) return true;
    final searchable = [
      student.name,
      student.classLevel,
      student.schoolName,
      ...student.subjects,
    ].join(' ').toLowerCase();
    return searchable.contains(_query);
  }

  Widget _buildLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 5,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => AppCard(
        child: Row(
          children: [
            AppLoader.skeleton(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLoader.skeleton(width: 160, height: 14),
                  const SizedBox(height: AppSpacing.sm),
                  AppLoader.skeleton(width: 110, height: 11),
                ],
              ),
            ),
            AppLoader.skeleton(width: 58, height: 24),
          ],
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.onTap});

  final Student student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = student.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(context).colorScheme.primary
                .withValues(alpha: 0.1),
            child: Text(
              initials,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${student.classLevel} · ${student.subjects.join(', ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusChip(
            label: _statusLabel(student.status),
            type: _statusType(student.status),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(StudentStatus status) => switch (status) {
  StudentStatus.active => 'Active',
  StudentStatus.paused => 'Paused',
  StudentStatus.left => 'Left',
};

StatusType _statusType(StudentStatus status) => switch (status) {
  StudentStatus.active => StatusType.active,
  StudentStatus.paused => StatusType.paused,
  StudentStatus.left => StatusType.left,
};
