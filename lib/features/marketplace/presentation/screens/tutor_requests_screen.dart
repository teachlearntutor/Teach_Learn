import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/utils/name_initials.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_staggered_item.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../students/domain/models/student.dart';
import '../../../students/presentation/screens/student_form_screen.dart';
import '../../domain/models/lesson_request.dart';
import '../providers/marketplace_providers.dart';

class TutorRequestsScreen extends ConsumerStatefulWidget {
  const TutorRequestsScreen({super.key});

  @override
  ConsumerState<TutorRequestsScreen> createState() =>
      _TutorRequestsScreenState();
}

class _TutorRequestsScreenState extends ConsumerState<TutorRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    LessonRequest request,
    LessonRequestStatus newStatus,
  ) async {
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.updateRequestStatus(requestId: request.id, status: newStatus);

      if (!context.mounted) return;

      if (newStatus == LessonRequestStatus.accepted) {
        final addStudent = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Request Accepted!'),
            content: Text(
              'Would you like to add ${request.fromName} as a new student now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Add Student'),
              ),
            ],
          ),
        );

        if (addStudent == true && context.mounted) {
          final now = DateTime.now();
          final prefilledStudent = Student(
            id: '',
            code: '',
            name: request.fromName,
            searchName: request.fromName.toLowerCase(),
            classLevel: request.classLevel,
            classSort:
                int.tryParse(
                  RegExp(r'\d+').firstMatch(request.classLevel)?.group(0) ?? '',
                ) ??
                0,
            school: '',
            subjects: request.subjects.isNotEmpty
                ? request.subjects
                : [request.subject],
            parentContact: '',
            startDate:
                '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
            status: StudentStatus.active,
            createdAt: now,
            updatedAt: now,
          );

          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => StudentFormScreen(student: prefilledStudent),
            ),
          );
        }
      } else {
        showAppSnackBar(context, 'Lesson request declined.');
      }
    } catch (e) {
      if (!context.mounted) return;
      final details = formatFirestoreErrorDetails(
        e,
        'lessonRequests/${request.id}',
      );
      showAppSnackBar(
        context,
        formatUserFriendlyError(e),
        isError: true,
        diagnostic: details,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsState = ref.watch(tutorRequestsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Declined'),
          ],
        ),
      ),
      body: requestsState.when(
        data: (allRequests) {
          final pending = allRequests
              .where((r) => r.status == LessonRequestStatus.pending)
              .toList();
          final accepted = allRequests
              .where((r) => r.status == LessonRequestStatus.accepted)
              .toList();
          final declined = allRequests
              .where((r) => r.status == LessonRequestStatus.declined)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRequestList(context, ref, pending, isPendingTab: true),
              _buildRequestList(context, ref, accepted),
              _buildRequestList(context, ref, declined),
            ],
          );
        },
        loading: () => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, _) => AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLoader.skeleton(width: 170, height: 16),
                const SizedBox(height: AppSpacing.md),
                AppLoader.skeleton(width: double.infinity, height: 12),
              ],
            ),
          ),
        ),
        error: (err, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 360,
              child: EmptyStateWidget(
                icon: Icons.shield_outlined,
                title: 'Requests Unavailable',
                description: formatUserFriendlyError(err),
                actionLabel: 'Retry',
                onActionPressed: () =>
                    ref.invalidate(tutorRequestsStreamProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(
    BuildContext context,
    WidgetRef ref,
    List<LessonRequest> requests, {
    bool isPendingTab = false,
  }) {
    if (requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tutorRequestsStreamProvider);
          await ref.read(tutorRequestsStreamProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 360,
              child: EmptyStateWidget(
                icon: Icons.mail_outline_rounded,
                title: 'No requests in this tab',
                description: 'Lesson requests from students will appear here.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tutorRequestsStreamProvider);
        await ref.read(tutorRequestsStreamProvider.future);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final request = requests[index];

          return AppStaggeredItem(
            key: ValueKey(request.id),
            index: index,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary,
                          child: Text(
                            nameInitials(
                              request.learnerName.isNotEmpty
                                  ? request.learnerName
                                  : request.fromName,
                              fallback: 'L',
                            ),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            request.learnerName.isNotEmpty
                                ? request.learnerName
                                : request.fromName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StatusChip.present(
                      label: request.status.name.toUpperCase(),
                    ),
                    if (request.classLevel.isNotEmpty)
                      _RequestDetailLine(
                        label: 'Class',
                        value: request.classLevel,
                      ),
                    finalRequestSubjects(request).isNotEmpty
                        ? _RequestDetailLine(
                            label: 'Subjects',
                            value: finalRequestSubjects(request).join(', '),
                          )
                        : const SizedBox.shrink(),
                    if (request.city.isNotEmpty || request.area.isNotEmpty)
                      _RequestDetailLine(
                        label: 'Location',
                        value: [
                          request.area,
                          request.city,
                        ].where((part) => part.isNotEmpty).join(', '),
                      ),
                    if (request.message.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        request.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (isPendingTab) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.secondary(
                              label: 'Decline',
                              onPressed: () => _updateStatus(
                                context,
                                ref,
                                request,
                                LessonRequestStatus.declined,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppButton.primary(
                              label: 'Accept',
                              onPressed: () => _updateStatus(
                                context,
                                ref,
                                request,
                                LessonRequestStatus.accepted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> finalRequestSubjects(LessonRequest request) {
    if (request.subjects.isNotEmpty) return request.subjects;
    return request.subject.isEmpty ? const [] : [request.subject];
  }
}

class _RequestDetailLine extends StatelessWidget {
  const _RequestDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
