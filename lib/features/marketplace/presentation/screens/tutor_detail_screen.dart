import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/contact_utils.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/utils/name_initials.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/contact_action_buttons.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../learner/domain/models/learner_preferences.dart';
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
  Future<void> _showSendRequestModal(
    bool isResend,
    LearnerPreferences learnerPrefs,
    String learnerName,
  ) async {
    final pageContext = context;
    final subjectController = TextEditingController(
      text: widget.tutor.subjects.isNotEmpty
          ? widget.tutor.subjects.first
          : 'Mathematics',
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
              Text(
                isResend ? 'Re-send Lesson Request' : 'Send Lesson Request',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'To: ${widget.tutor.displayName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Subject Requested',
                controller: subjectController,
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Message / Details',
                hint: 'Share a short note for the tutor',
                controller: messageController,
                maxLines: 3,
                maxLength: 240,
              ),
              const SizedBox(height: AppSpacing.lg),

              AppButton.primary(
                label: isSending
                    ? 'Sending Request...'
                    : (isResend ? 'Re-send Request' : 'Send Request'),
                isLoading: isSending,
                isFullWidth: true,
                onPressed: isSending
                    ? null
                    : () async {
                        final nav = Navigator.of(sheetContext);
                        setSheetState(() => isSending = true);
                        final fromUid =
                            ref.read(currentAuthUserProvider)?.uid ?? '';
                        try {
                          final now = DateTime.now();

                          final request = LessonRequest(
                            id: '${fromUid}_${widget.tutor.uid}',
                            fromUid: fromUid,
                            toUid: widget.tutor.uid,
                            toName: widget.tutor.displayName,
                            fromName: learnerName,
                            learnerName: learnerName,
                            classLevel: learnerPrefs.classLevel,
                            subject: subjectController.text.trim(),
                            subjects: learnerPrefs.neededSubjects,
                            city: learnerPrefs.city,
                            area: learnerPrefs.area,
                            mode: learnerPrefs.preferredMode,
                            message: messageController.text.trim(),
                            status: LessonRequestStatus.pending,
                            createdAt: now,
                            updatedAt: now,
                          );

                          final repo = ref.read(marketplaceRepositoryProvider);
                          if (isResend) {
                            await repo.resendLessonRequestAfterCancel(request);
                          } else {
                            await repo.createLessonRequest(request);
                          }

                          if (!pageContext.mounted) return;
                          if (sheetContext.mounted) nav.pop();
                          showAppSnackBar(
                            pageContext,
                            'Lesson request sent to tutor!',
                            isSuccess: true,
                          );
                        } catch (e) {
                          if (!pageContext.mounted) return;
                          if (sheetContext.mounted) {
                            setSheetState(() => isSending = false);
                          }
                          final details = formatFirestoreErrorDetails(
                            e,
                            'lessonRequests/${fromUid}_${widget.tutor.uid}',
                          );
                          showAppSnackBar(
                            pageContext,
                            formatUserFriendlyError(e),
                            isError: true,
                            diagnostic: details,
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
    subjectController.dispose();
    messageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final learner = ref.watch(currentAuthUserProvider);
    final learnerProfileState = learner == null
        ? null
        : ref.watch(userProfileProvider(learner.uid));
    final learnerProfile = learnerProfileState?.asData?.value;
    final learnerPrefs = LearnerPreferences.fromMap(learnerProfile);
    final profileName = learnerProfile?['displayName'] as String? ?? '';
    final learnerName = profileName.trim().isNotEmpty
        ? profileName.trim()
        : learner?.displayName?.trim().isNotEmpty == true
        ? learner!.displayName!.trim()
        : 'Learner';
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

    final isAccepted =
        existingRequest.id.isNotEmpty &&
        existingRequest.status == LessonRequestStatus.accepted;
    final isPending =
        existingRequest.id.isNotEmpty &&
        existingRequest.status == LessonRequestStatus.pending;
    final isCancelled =
        existingRequest.id.isNotEmpty &&
        existingRequest.status == LessonRequestStatus.cancelled;

    final privatePhoneState = isAccepted
        ? ref.watch(tutorPrivateContactStreamProvider(widget.tutor.uid))
        : null;
    final phone = privatePhoneState?.asData?.value;

    final initials = nameInitials(widget.tutor.displayName);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tutor.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Header Card
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 28,
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
                        widget.tutor.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (widget.tutor.headline.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.tutor.headline,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusChip.present(
                          label:
                              '${switch (widget.tutor.mode.toLowerCase()) {
                                'online' => 'ONLINE',
                                'both' => 'BOTH',
                                _ => 'HOME',
                              }} MODE',
                        ),
                      ),
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
                  title: const Text('Location'),
                  subtitle: const Text(
                    'Approximate area only. Never your exact address.',
                  ),
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
              child: Text(
                widget.tutor.bio,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Contact Details (Only visible if request is accepted)
          if (isAccepted) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSuccessSurface
                    : AppColors.successSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSuccessText
                      : AppColors.success,
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Accepted!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkSuccessText
                          : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone != null && phone.isNotEmpty
                        ? 'Tutor Contact: $phone'
                        : 'Contact details released by tutor.',
                  ),
                  if (phone != null && phone.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    ContactActionButtons(
                      callLabel: 'Call Tutor',
                      onCall: () => makePhoneCall(phone),
                      onWhatsApp: () => launchWhatsAppContact(
                        rawPhoneNumber: phone,
                        message: buildTutorContactWhatsAppMessage(
                          widget.tutor.displayName,
                        ),
                      ),
                    ),
                  ],
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
              label: isCancelled
                  ? 'Re-send Lesson Request'
                  : 'Send Lesson Request',
              isFullWidth: true,
              onPressed: () =>
                  _showSendRequestModal(isCancelled, learnerPrefs, learnerName),
            ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
