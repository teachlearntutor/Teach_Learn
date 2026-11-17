import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/contact_utils.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../attendance/presentation/widgets/student_attendance_calendar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/academic_test.dart';
import '../../domain/models/student.dart';
import '../providers/academic_test_providers.dart';
import '../providers/student_providers.dart';
import 'student_form_screen.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  Future<void> _deleteStudent(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Delete Student?'),
          content: Text(
            'Are you sure you want to permanently delete ${student.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !context.mounted) return;

    final uid = ref.read(currentAuthUserProvider)?.uid ?? '';
    try {
      await ref.read(studentRepositoryProvider).deleteStudent(uid, student.id);

      if (!context.mounted) return;
      Navigator.pop(context);
      showAppSnackBar(context, '${student.name} deleted.', isError: true);
    } catch (e) {
      if (!context.mounted) return;
      final details = formatFirestoreErrorDetails(
        e,
        'users/$uid/students/${student.id}',
      );
      showAppSnackBar(
        context,
        formatUserFriendlyError(e),
        isError: true,
        diagnostic: details,
      );
    }
  }

  static Future<void> showAddTestModal(
    BuildContext context,
    WidgetRef ref,
    Student student, {
    AcademicTest? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final totalCtrl = TextEditingController(
      text: existing?.totalMarks.toStringAsFixed(0) ?? '100',
    );
    final obtainedCtrl = TextEditingController(
      text: existing?.obtainedMarks.toStringAsFixed(0) ?? '',
    );
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.sheetBorderRadius,
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null ? 'Add Test Record' : 'Edit Test Record',
                  style: Theme.of(sheetContext).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Test Title / Subject',
                  hint: 'e.g., Math Monthly Test, Midterm',
                  controller: titleCtrl,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Enter test title'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Total Marks',
                        controller: totalCtrl,
                        keyboardType: TextInputType.number,
                        validator: (val) =>
                            (double.tryParse(val ?? '') ?? 0) <= 0
                            ? 'Invalid'
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        label: 'Obtained Marks',
                        controller: obtainedCtrl,
                        keyboardType: TextInputType.number,
                        validator: (val) => double.tryParse(val ?? '') == null
                            ? 'Invalid'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Note (Optional)',
                  hint: 'e.g. Needs revision on Chapter 4',
                  controller: noteCtrl,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton.primary(
                  label: 'Save Test Record',
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final user = ref.read(currentAuthUserProvider);
                    final uid = user?.uid ?? '';
                    final now = DateTime.now();

                    final test = AcademicTest(
                      id: existing?.id ?? '',
                      title: titleCtrl.text.trim(),
                      date:
                          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                      totalMarks: double.parse(totalCtrl.text.trim()),
                      obtainedMarks: double.parse(obtainedCtrl.text.trim()),
                      note: noteCtrl.text.trim().isNotEmpty
                          ? noteCtrl.text.trim()
                          : null,
                      createdAt: existing?.createdAt ?? now,
                    );

                    final repo = ref.read(academicTestRepositoryProvider);
                    try {
                      await repo.saveAcademicTest(uid, student.id, test);
                    } catch (error) {
                      if (!sheetContext.mounted) return;
                      final details = formatFirestoreErrorDetails(
                        error,
                        'users/$uid/students/${student.id}/tests',
                      );
                      showAppSnackBar(
                        sheetContext,
                        formatUserFriendlyError(error),
                        isError: true,
                        diagnostic: details,
                      );
                      return;
                    }

                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsState = ref.watch(studentsProvider);

    return studentsState.when(
      data: (allStudents) {
        final now = DateTime.now();
        final student = allStudents.firstWhere(
          (s) => s.id == studentId,
          orElse: () => Student(
            id: studentId,
            code: 'S-4K2P',
            name: 'Unknown Student',
            searchName: 'unknown student',
            classLevel: 'Class 9',
            classSort: 9,
            school: '',
            subjects: const [],
            parentContact: '',
            startDate: '',
            status: StudentStatus.active,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final schoolText = student.schoolName.isNotEmpty
            ? ' • ${student.schoolName}'
            : '';
        final hasContact = student.parentContact?.isNotEmpty == true;
        final percentage = ref.watch(
          studentAttendancePercentageProvider(student.id),
        );
        final testsState = ref.watch(
          studentAcademicTestsStreamProvider(student.id),
        );
        final academicAverage = ref.watch(
          studentAcademicAverageProvider(student.id),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(student.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Student',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => StudentFormScreen(student: student),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                tooltip: 'Delete Student',
                onPressed: () => _deleteStudent(context, ref, student),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.read(studentsNotifierProvider.notifier).loadInitial(),
                ref.refresh(allAttendanceStreamProvider.future),
                ref.refresh(
                  studentAcademicTestsStreamProvider(student.id).future,
                ),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Student Profile Card
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          student.name.isNotEmpty
                              ? student.name[0].toUpperCase()
                              : 'S',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
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
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${student.classLevel}$schoolText',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                StatusChip.present(
                                  label: student.status.name.toUpperCase(),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${percentage.toStringAsFixed(0)}% Attendance',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: percentage >= 75
                                          ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                          : Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Contact & Subjects Card with Call & WhatsApp
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.phone_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('Parent Contact'),
                        subtitle: Text(
                          hasContact ? student.parentContact! : 'Not provided',
                        ),
                        trailing: hasContact
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.phone_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                    tooltip: 'Call Parent',
                                    onPressed: () =>
                                        makePhoneCall(student.parentContact!),
                                  ),
                                  IconButton(
                                    icon: FaIcon(
                                      FontAwesomeIcons.whatsapp,
                                      color: AppColors.whatsAppGreen,
                                    ),
                                    tooltip: 'WhatsApp Parent',
                                    onPressed: () => launchWhatsAppContact(
                                      rawPhoneNumber: student.parentContact!,
                                      message:
                                          'Hello, this is Teach Learn regarding ${student.name}\'s tuition class. Please let me know if you have an inquiry.',
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.menu_book_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('Enrolled Subjects'),
                        subtitle: Text(
                          student.subjects.isNotEmpty
                              ? student.subjects.join(', ')
                              : 'All Subjects',
                        ),
                      ),
                      if (student.notes != null &&
                          student.notes!.isNotEmpty) ...[
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.note_alt_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('Private Notes'),
                          subtitle: Text(student.notes!),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Academic Record & Test Score Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Academic Test Record',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      onPressed: () => showAddTestModal(context, ref, student),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Test'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                testsState.when(
                  data: (tests) {
                    if (tests.isEmpty) {
                      return const EmptyStateWidget(
                        icon: Icons.quiz_outlined,
                        title: 'No academic tests recorded',
                        description: 'Track test marks, monthly exam scores, and progress here.',
                      );
                    }

                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Average Score:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${academicAverage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...tests.map((testItem) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: AppCard(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    child: Text(
                                      '${testItem.percentage.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
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
                                          testItem.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Marks: ${testItem.obtainedMarks.toStringAsFixed(0)} / ${testItem.totalMarks.toStringAsFixed(0)} (${testItem.date})',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        if (testItem.note != null &&
                                            testItem.note!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Note: ${testItem.note}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      size: 20,
                                    ),
                                    onSelected: (action) async {
                                      final user = ref.read(
                                        currentAuthUserProvider,
                                      );
                                      final uid = user?.uid ?? '';
                                      if (action == 'edit') {
                                        showAddTestModal(
                                          context,
                                          ref,
                                          student,
                                          existing: testItem,
                                        );
                                      } else if (action == 'delete') {
                                        try {
                                          await ref
                                              .read(
                                                academicTestRepositoryProvider,
                                              )
                                              .deleteAcademicTest(
                                                uid,
                                                student.id,
                                                testItem.id,
                                              );
                                        } catch (error) {
                                          if (!context.mounted) return;
                                          final details =
                                              formatFirestoreErrorDetails(
                                                error,
                                                'users/$uid/students/${student.id}/tests/${testItem.id}',
                                              );
                                          showAppSnackBar(
                                            context,
                                            formatUserFriendlyError(error),
                                            isError: true,
                                            diagnostic: details,
                                          );
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: const Text('Edit Test'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'Delete Test',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                  loading: () => const AppLoader.inline(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Real Monthly Attendance Calendar & Breakdown
                StudentMonthlyAttendanceCalendar(
                  studentId: student.id,
                  studentName: student.name,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const Scaffold(
        body: EmptyStateWidget(
          title: 'Student unavailable',
          description: 'Could not load student profile.',
        ),
      ),
    );
  }
}
