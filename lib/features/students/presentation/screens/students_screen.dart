import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
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

  Future<void> _softRemoveStudent(Student student) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final repo = ref.read(studentRepositoryProvider);

    final updated = student.copyWith(
      status: StudentStatus.left,
      leftAt: DateTime.now(),
    );

    await repo.updateStudent(uid, updated);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${student.name} marked as "Left"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await repo.updateStudent(uid, student);
            },
          ),
        ),
      );
  }

  Future<void> _deleteStudentWithUndo(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Student?'),
        content: Text('Are you sure you want to permanently delete ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final repo = ref.read(studentRepositoryProvider);

    await repo.deleteStudent(uid, student.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${student.name} deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await repo.addStudent(uid, student);
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  prefixIcon: const Icon(Icons.search_rounded),
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All Status'),
                selected: _statusFilter == null,
                onSelected: (_) => setState(() => _statusFilter = null),
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Active'),
                selected: _statusFilter == StudentStatus.active,
                onSelected: (_) => setState(() => _statusFilter = StudentStatus.active),
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Paused'),
                selected: _statusFilter == StudentStatus.paused,
                onSelected: (_) => setState(() => _statusFilter = StudentStatus.paused),
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Left'),
                selected: _statusFilter == StudentStatus.left,
                onSelected: (_) => setState(() => _statusFilter = StudentStatus.left),
              ),
            ],
          ),
        ),

        Expanded(
          child: ref.watch(studentsProvider).when(
            loading: _buildLoading,
            error: (error, stackTrace) => Center(
              child: EmptyStateWidget(
                icon: Icons.cloud_off_outlined,
                title: 'Students are unavailable',
                description: 'Try loading your student list again.',
                actionLabel: 'Retry',
                onActionPressed: () => ref.invalidate(studentsStreamProvider),
              ),
            ),
            data: (students) {
              final filtered = students.where(_matchesQuery).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: EmptyStateWidget(
                    icon: Icons.person_search_outlined,
                    title: _query.isEmpty ? 'No students yet' : 'No matches found',
                    description: _query.isEmpty
                        ? 'Add your first student to start organizing lessons.'
                        : 'Try a different name, class, school, or subject.',
                    actionLabel: _query.isEmpty ? 'Add Student' : null,
                    onActionPressed: _query.isEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const StudentFormScreen(),
                              ),
                            );
                          }
                        : null,
                  ),
                );
              }

              // Apply Sorting
              filtered.sort((a, b) {
                switch (_sortOption) {
                  case StudentSortOption.name:
                    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
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
                itemCount: classKeys.length,
                itemBuilder: (context, index) {
                  final className = classKeys[index];
                  final classStudents = groupedByClass[className]!;

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1.0,
                      ),
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      title: Text(
                        '$className (${classStudents.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      children: classStudents.map((student) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          child: _StudentTile(
                            student: student,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => StudentDetailScreen(
                                  studentId: student.id,
                                ),
                              ),
                            ),
                            onSoftRemove: () => _softRemoveStudent(student),
                            onDelete: () => _deleteStudentWithUndo(student),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
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
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              initials,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
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
              const PopupMenuItem(
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
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Delete Permanently', style: TextStyle(color: AppColors.danger)),
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
