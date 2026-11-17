import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/utils/name_initials.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/contact_action_buttons.dart';
import '../../../../core/utils/contact_utils.dart';
import '../../domain/models/lesson_request.dart';
import '../providers/marketplace_providers.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  LessonRequestStatus? _statusFilter;

  Future<void> _cancelRequest(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.updateRequestStatus(
        requestId: requestId,
        status: LessonRequestStatus.cancelled,
      );

      if (!context.mounted) return;
      showAppSnackBar(context, 'Lesson request cancelled.');
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, formatUserFriendlyError(e), isError: true);
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
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
                  onSelected: (_) => setState(
                    () => _statusFilter = LessonRequestStatus.pending,
                  ),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Accepted'),
                  selected: _statusFilter == LessonRequestStatus.accepted,
                  onSelected: (_) => setState(
                    () => _statusFilter = LessonRequestStatus.accepted,
                  ),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Declined'),
                  selected: _statusFilter == LessonRequestStatus.declined,
                  onSelected: (_) => setState(
                    () => _statusFilter = LessonRequestStatus.declined,
                  ),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Cancelled'),
                  selected: _statusFilter == LessonRequestStatus.cancelled,
                  onSelected: (_) => setState(
                    () => _statusFilter = LessonRequestStatus.cancelled,
                  ),
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
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(learnerRequestsStreamProvider);
                      await ref.read(learnerRequestsStreamProvider.future);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 360,
                          child: EmptyStateWidget(
                            icon: Icons.send_outlined,
                            title: 'No requests found',
                            description: 'Lesson requests sent to tutors will appear here.',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(learnerRequestsStreamProvider);
                    await ref.read(learnerRequestsStreamProvider.future);
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final request = filtered[index];
                      final isPending =
                          request.status == LessonRequestStatus.pending;
                      final tutorProfileState = ref.watch(
                        tutorProfileByUidProvider(request.toUid),
                      );
                      final tutorName = request.toName.isNotEmpty
                          ? request.toName
                          : tutorProfileState.valueOrNull?.displayName ??
                                'Tutor';
                      final contactState =
                          request.status == LessonRequestStatus.accepted
                          ? ref.watch(
                              tutorPrivateContactStreamProvider(request.toUid),
                            )
                          : null;
                      final phone = contactState?.valueOrNull?.trim();

                      return Card(
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
                                      nameInitials(tutorName, fallback: 'T'),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tutorName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          request.subject,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              StatusChip.present(
                                label: request.status.name.toUpperCase(),
                              ),
                              const SizedBox(height: 4),
                              if (request.message.isNotEmpty) ...[
                                Text(
                                  request.message,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (request.status ==
                                      LessonRequestStatus.accepted &&
                                  phone != null &&
                                  phone.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                ContactActionButtons(
                                  callLabel: 'Call Tutor',
                                  onCall: () => makePhoneCall(phone),
                                  onWhatsApp: () => launchWhatsAppContact(
                                    rawPhoneNumber: phone,
                                    message: buildTutorContactWhatsAppMessage(
                                      request.toName,
                                    ),
                                  ),
                                ),
                              ],
                              if (isPending) ...[
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => _cancelRequest(
                                      context,
                                      ref,
                                      request.id,
                                    ),
                                    child: Text(
                                      'Cancel Request',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: 4,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppLoader.skeleton(width: 170, height: 16),
                        SizedBox(height: AppSpacing.md),
                        AppLoader.skeleton(width: double.infinity, height: 12),
                      ],
                    ),
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
                          ref.invalidate(learnerRequestsStreamProvider),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
