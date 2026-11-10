import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/models/lesson_request.dart';
import '../providers/marketplace_providers.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  LessonRequestStatus? _statusFilter;

  Future<void> _cancelRequest(BuildContext context, WidgetRef ref, String requestId) async {
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.updateRequestStatus(
        requestId: requestId,
        status: LessonRequestStatus.cancelled,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson request cancelled.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsState = ref.watch(learnerRequestsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Lesson Requests')),
      body: Column(
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _statusFilter == null,
                  onSelected: (_) => setState(() => _statusFilter = null),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Pending'),
                  selected: _statusFilter == LessonRequestStatus.pending,
                  onSelected: (_) => setState(() => _statusFilter = LessonRequestStatus.pending),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Accepted'),
                  selected: _statusFilter == LessonRequestStatus.accepted,
                  onSelected: (_) => setState(() => _statusFilter = LessonRequestStatus.accepted),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Declined'),
                  selected: _statusFilter == LessonRequestStatus.declined,
                  onSelected: (_) => setState(() => _statusFilter = LessonRequestStatus.declined),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Cancelled'),
                  selected: _statusFilter == LessonRequestStatus.cancelled,
                  onSelected: (_) => setState(() => _statusFilter = LessonRequestStatus.cancelled),
                ),
              ],
            ),
          ),

          Expanded(
            child: requestsState.when(
              data: (requests) {
                final filtered = _statusFilter == null
                    ? requests
                    : requests.where((r) => r.status == _statusFilter).toList();

                if (filtered.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.send_outlined,
                    title: 'No requests found',
                    description: 'Lesson requests sent to tutors will appear here.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final request = filtered[index];
                    final isPending = request.status == LessonRequestStatus.pending;

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
                                  request.subject,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                StatusChip.present(label: request.status.name.toUpperCase()),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (request.message.isNotEmpty) ...[
                              Text('"${request.message}"', style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 8),
                            ],
                            if (isPending) ...[
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _cancelRequest(context, ref, request.id),
                                  child: const Text('Cancel Request', style: TextStyle(color: AppColors.danger)),
                                ),
                              ),
                            ],
                          ],
                        ),
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
