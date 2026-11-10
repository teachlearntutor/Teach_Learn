import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../students/domain/models/student.dart';
import '../../../students/presentation/screens/student_form_screen.dart';
import '../../domain/models/lesson_request.dart';
import '../providers/marketplace_providers.dart';

class TutorRequestsScreen extends ConsumerStatefulWidget {
  const TutorRequestsScreen({super.key});

  @override
  ConsumerState<TutorRequestsScreen> createState() => _TutorRequestsScreenState();
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
      await repo.updateRequestStatus(
        requestId: request.id,
        status: newStatus,
      );

      if (!context.mounted) return;

      if (newStatus == LessonRequestStatus.accepted) {
        final addStudent = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Request Accepted!'),
            content: Text('Would you like to add ${request.fromName} as a new student now?'),
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
            classLevel: 'Class 9',
            classSort: 9,
            school: '',
            subjects: [request.subject],
            parentContact: '',
            startDate: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson request declined.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
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
          final pending = allRequests.where((r) => r.status == LessonRequestStatus.pending).toList();
          final accepted = allRequests.where((r) => r.status == LessonRequestStatus.accepted).toList();
          final declined = allRequests.where((r) => r.status == LessonRequestStatus.declined).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRequestList(context, ref, pending, isPendingTab: true),
              _buildRequestList(context, ref, accepted),
              _buildRequestList(context, ref, declined),
            ],
          );
        },
        loading: () => const AppLoader.inline(),
        error: (err, _) => Center(child: Text('Error: $err')),
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
      return const EmptyStateWidget(
        icon: Icons.mail_outline_rounded,
        title: 'No requests in this tab',
        description: 'Lesson requests from students will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final request = requests[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      request.fromName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    StatusChip.present(label: request.status.name.toUpperCase()),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Subject: ${request.subject}', style: Theme.of(context).textTheme.bodySmall),
                if (request.message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('"${request.message}"', style: Theme.of(context).textTheme.bodyMedium),
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
        );
      },
    );
  }
}
