import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_staggered_item.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/models/student.dart';
import '../providers/student_providers.dart';
import 'student_detail_screen.dart';
import 'student_form_screen.dart';

enum StudentSortOption { name, classLevel, newest }

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  StudentStatus? _statusFilter;
  StudentSortOption _sortOption = StudentSortOption.classLevel;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearchAndFilters() {
    setState(() {
      _searchController.clear();
      _query = '';
      _statusFilter = null;
      _sortOption = StudentSortOption.classLevel;
    });
  }

  Future<void> _softRemoveStudent(Student student) async {
    final notifier = ref.read(studentsNotifierProvider.notifier);

    final updated = student.copyWith(
      status: StudentStatus.left,
      leftAt: DateTime.now(),
    );

    await notifier.updateStudent(updated);

    if (!mounted) return;

    showAppSnackBar(
      context,
      '${student.name} marked as "Left"',
      actionLabel: 'Undo',
      onActionPressed: () async => notifier.updateStudent(student),
    );
  }

  Future<void> _deleteStudentWithUndo(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Student?'),
        content: Text(
          'Are you sure you want to permanently delete ${student.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final notifier = ref.read(studentsNotifierProvider.notifier);
    await notifier.deleteStudent(student.id);

    if (!mounted) return;

    showAppSnackBar(
      context,
      '${student.name} deleted',
      actionLabel: 'Undo',
      onActionPressed: () async => notifier.addStudent(student),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentsNotifierProvider);
    final notifier = ref.read(studentsNotifierProvider.notifier);

    final hasActiveFilters = _query.isNotEmpty || _statusFilter != null;

    return RefreshIndicator(
      onRefresh: () async {
        await notifier.loadInitial();
      },
      child: Column(
        children: [
          // Search & Filter Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Search students',
                    hint: 'Name, class, school, or subject',
                    controller: _searchController,
                    prefixIcon: const Icon(Icons.search_rounded),
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                  ),
                ),
                if (hasActiveFilters) ...[
                  IconButton(
                    icon: const Icon(Icons.clear_all_rounded, size: 20),
                    tooltip: 'Reset Filters',
                    onPressed: _clearSearchAndFilters,
                  ),
                ],
                const SizedBox(width: AppSpacing.xs),
                PopupMenuButton<StudentSortOption>(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'Sort Students',
                  onSelected: (option) => setState(() => _sortOption = option),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: StudentSortOption.classLevel,
                      child: Text('Sort by Class Level'),
                    ),
                    PopupMenuItem(
                      value: StudentSortOption.name,
                      child: Text('Sort by Name (A-Z)'),
                    ),
                    PopupMenuItem(
                      value: StudentSortOption.newest,
                      child: Text('Sort by Newest'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.s8,
            ),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Status'),
                  selected: _statusFilter == null,
                  onSelected: (_) => setState(() => _statusFilter = null),
                ),
                const SizedBox(width: AppSpacing.s8),
                FilterChip(
                  label: const Text('Active'),
                  selected: _statusFilter == StudentStatus.active,
                  onSelected: (_) =>
                      setState(() => _statusFilter = StudentStatus.active),
                ),
                const SizedBox(width: AppSpacing.s8),
                FilterChip(
                  label: const Text('Paused'),
                  selected: _statusFilter == StudentStatus.paused,
                  onSelected: (_) =>
                      setState(() => _statusFilter = StudentStatus.paused),
                ),
                const SizedBox(width: AppSpacing.s8),
                FilterChip(
                  label: const Text('Left'),
                  selected: _statusFilter == StudentStatus.left,
                  onSelected: (_) =>
                      setState(() => _statusFilter = StudentStatus.left),
                ),
              ],
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
                      : 'students-content',
                ),
                builder: (context) {
                  if (state.isLoadingInitial) {
                    return _buildLoading();
                  }

                  if (state.error != null) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 360,
                          child: EmptyStateWidget(
                            icon: Icons.cloud_off_outlined,
                            title: 'Students Unavailable',
                            description: formatUserFriendlyError(state.error),
                            diagnostic: formatFirestoreErrorDetails(
                              state.error,
                              'users/${notifier.uid}/students',
                            ),
                            actionLabel: 'Retry',
                            onActionPressed: () => notifier.loadInitial(),
                          ),
                        ),
                      ],
                    );
                  }

                  final filtered = state.students.where(_matchesQuery).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 360,
                          child: EmptyStateWidget(
                            icon: Icons.person_search_outlined,
                            title: _query.isEmpty
                                ? 'No students yet'
                                : 'No matches found',
                            description: _query.isEmpty
                                ? 'Add your first student to start organizing lessons.'
                                : 'Try a different name, class, school, or subject.',
                            actionLabel: _query.isEmpty
                                ? 'Add Student'
                                : 'Reset Search',
                            onActionPressed: _query.isEmpty
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const StudentFormScreen(),
                                      ),
                                    );
                                  }
                                : _clearSearchAndFilters,
                          ),
                        ),
                      ],
                    );
                  }

                  // Apply Sorting
                  filtered.sort((a, b) {
                    switch (_sortOption) {
                      case StudentSortOption.name:
                        return a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        );
                      case StudentSortOption.newest:
                        return b.createdAt.compareTo(a.createdAt);
                      case StudentSortOption.classLevel:
                        final comp = a.classSort.compareTo(b.classSort);
                        return comp != 0 ? comp : a.name.compareTo(b.name);
                    }
                  });

                  // Group class-wise in collapsible sections
                  final Map<String, List<Student>> groupedByClass = {};
                  for (final s in filtered) {
                    groupedByClass.putIfAbsent(s.classLevel, () => []).add(s);
                  }

                  final classKeys = groupedByClass.keys.toList();

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      96,
                    ),
                    itemCount: classKeys.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == classKeys.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Center(
                            child: AppButton.secondary(
                              label: state.isLoadingMore
                                  ? 'Loading More...'
                                  : 'Load More Students',
                              isLoading: state.isLoadingMore,
                              onPressed: state.isLoadingMore
                                  ? null
                                  : () => notifier.loadMore(),
                            ),
                          ),
                        );
                      }

                      final className = classKeys[index];
                      final classStudents = groupedByClass[className]!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: AppRadii.cardBorderRadius,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1.0,
                          ),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadii.cardBorderRadius,
                          ),
                          title: Text(
                            '$className (${classStudents.length})',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          children: [
                            for (
                              var studentIndex = 0;
                              studentIndex < classStudents.length;
                              studentIndex++
                            )
                              AppStaggeredItem(
                                key: ValueKey(classStudents[studentIndex].id),
                                index: studentIndex,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 2,
                                  ),
                                  child: _StudentTile(
                                    student: classStudents[studentIndex],
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => StudentDetailScreen(
                                          studentId:
                                              classStudents[studentIndex].id,
                                        ),
                                      ),
                                    ),
                                    onSoftRemove: () => _softRemoveStudent(
                                      classStudents[studentIndex],
                                    ),
                                    onDelete: () => _deleteStudentWithUndo(
                                      classStudents[studentIndex],
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
    );
  }

  bool _matchesQuery(Student student) {
    if (_statusFilter != null && student.status != _statusFilter) {
      return false;
    }

    if (_query.isEmpty) return true;
    final searchable = [
      student.name,
      student.classLevel,
      student.schoolName,
      student.code,
      ...student.subjects,
    ].join(' ').toLowerCase();
    return searchable.contains(_query);
  }

  Widget _buildLoading() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
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
  const _StudentTile({
    required this.student,
    required this.onTap,
    required this.onSoftRemove,
    required this.onDelete,
  });

  final Student student;
  final VoidCallback onTap;
  final VoidCallback onSoftRemove;
  final VoidCallback onDelete;

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
          const SizedBox(width: AppSpacing.xs),
          StatusChip(
            label: _statusLabel(student.status),
            type: _statusType(student.status),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => StudentFormScreen(student: student),
                  ),
                );
              } else if (value == 'left') {
                onSoftRemove();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Student'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'left',
                child: Row(
                  children: [
                    Icon(Icons.person_remove_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Mark as "Left"'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Delete Permanently',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
