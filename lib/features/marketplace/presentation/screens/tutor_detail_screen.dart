import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/models/lesson_request.dart';
import '../../domain/models/tutor_profile.dart';
import '../providers/marketplace_providers.dart';

class TutorDetailScreen extends ConsumerStatefulWidget {
  const TutorDetailScreen({super.key, required this.tutor});

  final TutorProfile tutor;

  @override
  ConsumerState<TutorDetailScreen> createState() => _TutorDetailScreenState();
}

class _TutorDetailScreenState extends ConsumerState<TutorDetailScreen> {
  Future<void> _showSendRequestModal() async {
    final subjectController = TextEditingController(
      text: widget.tutor.subjects.isNotEmpty ? widget.tutor.subjects.first : 'Mathematics',
    );
    final messageController = TextEditingController();
    bool isSending = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.sheetBorderRadius,
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Send Lesson Request', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text('To: ${widget.tutor.displayName}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Subject Requested',
                controller: subjectController,
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Message / Details',
                hint: 'e.g., Looking for home tuition for Class 9 Mathematics in DHA Phase 5...',
                controller: messageController,
              ),
              const SizedBox(height: AppSpacing.lg),

              AppButton.primary(
                label: isSending ? 'Sending Request...' : 'Send Request',
                isLoading: isSending,
                isFullWidth: true,
                onPressed: isSending
                    ? null
                    : () async {
                        final nav = Navigator.of(sheetContext);
                        final messenger = ScaffoldMessenger.of(context);
                        setSheetState(() => isSending = true);
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          final fromUid = user?.uid ?? '';
                          final fromName = user?.displayName ?? 'Learner';
                          final now = DateTime.now();

                          final request = LessonRequest(
                            id: '${fromUid}_${widget.tutor.uid}',
                            fromUid: fromUid,
                            toUid: widget.tutor.uid,
                            fromName: fromName,
                            subject: subjectController.text.trim(),
                            message: messageController.text.trim(),
                            status: LessonRequestStatus.pending,
                            createdAt: now,
                            updatedAt: now,
                          );

                          final repo = ref.read(marketplaceRepositoryProvider);
                          await repo.sendLessonRequest(request);

                          nav.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Lesson request sent to tutor!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } catch (e) {
                          setSheetState(() => isSending = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final learnerRequestsState = ref.watch(learnerRequestsStreamProvider);
    final requests = learnerRequestsState.value ?? [];

    final existingRequest = requests.firstWhere(
      (r) => r.toUid == widget.tutor.uid,
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

    final isAccepted = existingRequest.id.isNotEmpty && existingRequest.status == LessonRequestStatus.accepted;
    final isPending = existingRequest.id.isNotEmpty && existingRequest.status == LessonRequestStatus.pending;

    final initials = widget.tutor.displayName.isNotEmpty
        ? widget.tutor.displayName[0].toUpperCase()
        : 'T';

    return Scaffold(
      appBar: AppBar(title: Text(widget.tutor.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Header Card
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryTeal,
                  child: Text(
                    initials,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.tutor.displayName, style: Theme.of(context).textTheme.headlineSmall),
                      if (widget.tutor.headline.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(widget.tutor.headline, style: Theme.of(context).textTheme.bodySmall),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      StatusChip.present(label: '${widget.tutor.mode.toUpperCase()} MODE'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Details Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Location & Area'),
                  subtitle: Text('${widget.tutor.city} (${widget.tutor.area})'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.work_outline_rounded),
                  title: const Text('Teaching Experience'),
                  subtitle: Text('${widget.tutor.experienceYears} Years'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.menu_book_rounded),
                  title: const Text('Subjects Taught'),
                  subtitle: Text(widget.tutor.subjects.join(', ')),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('Classes / Levels'),
                  subtitle: Text(widget.tutor.levels.join(', ')),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Bio Section
          if (widget.tutor.bio.isNotEmpty) ...[
            Text('About & Bio', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Text(widget.tutor.bio, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Contact Details (Only visible if request is accepted)
          if (isAccepted) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Request Accepted!',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                  const SizedBox(height: 4),
                  const Text('You can now contact your tutor directly.'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Action Button
          if (isPending)
            AppButton.secondary(
              label: 'Request Pending',
              isFullWidth: true,
              onPressed: null,
            )
          else if (!isAccepted)
            AppButton.primary(
              label: 'Send Lesson Request',
              isFullWidth: true,
              onPressed: _showSendRequestModal,
            ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
