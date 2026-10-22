import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/models/class_session.dart';
import '../providers/schedule_providers.dart';
import 'class_form_screen.dart';

/// Schedule Screen with Week Strip, Timeline Cards, Cancel/Reschedule, Time-Clash Warning.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  bool _hasTimeClash(List<ClassSession> daySessions) {
    if (daySessions.length < 2) return false;
    for (int i = 0; i < daySessions.length; i++) {
      for (int j = i + 1; j < daySessions.length; j++) {
        final a = daySessions[i];
        final b = daySessions[j];
        if (a.status == 'cancelled' || b.status == 'cancelled') continue;
        if (a.startAt.isBefore(b.endAt) && b.startAt.isBefore(a.endAt)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _cancelSessionModal(ClassSession session) async {
    final reasonController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cancel Class Session', style: Theme.of(sheetContext).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text('Subject: ${session.subject} on ${session.date}', style: Theme.of(sheetContext).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Cancellation Reason (Optional)',
              hint: 'e.g., Tutor unwell, Student emergency, Holiday',
              controller: reasonController,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: 'Confirm Cancellation',
              onPressed: () async {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  final uid = user?.uid ?? '';

                  final updated = session.copyWith(
                    status: 'cancelled',
                    cancelReason: reasonController.text.trim().isNotEmpty
                        ? reasonController.text.trim()
                        : 'Cancelled by tutor',
                    updatedAt: DateTime.now(),
                  );

                  await ref.read(sessionRepositoryProvider).saveSessionOverride(uid, updated);

                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Class session cancelled.'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                } catch (e) {
                  if (!sheetContext.mounted) return;
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 14-day expanded range centered on selected date
    final range = DateRange(
      startDate: _selectedDate.subtract(const Duration(days: 7)),
      endDate: _selectedDate.add(const Duration(days: 7)),
    );

    final expandedSessions = ref.watch(expandedSessionsProvider(range));

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final daySessions = expandedSessions.where((s) => s.date == dateStr).toList();
    final timeClash = _hasTimeClash(daySessions);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Header Row with Add Class Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Class Schedule', style: Theme.of(context).textTheme.titleLarge),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const ClassFormScreen()),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Class'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 7-Day Horizontal Week Strip
          _buildWeekStrip(context),
          const SizedBox(height: AppSpacing.lg),

          // Time Clash Warning Banner
          if (timeClash) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warningSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning, width: 1.0),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Time Clash Alert: 2 or more classes overlap in time today!',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Selected Date Header
          Text(
            'Timeline for $dateStr (${daySessions.length} sessions)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),

          if (daySessions.isEmpty)
            const EmptyStateWidget(
              icon: Icons.event_available_rounded,
              title: 'No classes for this day',
              description: 'Select another date or add a new weekly class.',
            )
          else
            ...daySessions.map((session) {
              final isCancelled = session.status == 'cancelled';

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              session.location.type == 'online'
                                  ? Icons.video_call_rounded
                                  : Icons.home_rounded,
                              color: AppColors.primaryTeal,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              session.subject,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                                  ),
                            ),
                          ],
                        ),
                        StatusChip.present(
                          label: session.status.toUpperCase(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Time: ${session.startsAt.hour}:${session.startsAt.minute.toString().padLeft(2, '0')} (${session.durationMinutes} mins)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (session.location.place?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text('Location: ${session.location.place}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                    if (isCancelled && session.cancelReason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Reason: ${session.cancelReason}',
                        style: const TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    if (!isCancelled)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _cancelSessionModal(session),
                          icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.danger),
                          label: const Text('Cancel Session', style: TextStyle(color: AppColors.danger)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeekStrip(BuildContext context) {
    final now = _selectedDate;
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = monday.add(Duration(days: index));
        final isSelected = day.year == _selectedDate.year &&
            day.month == _selectedDate.month &&
            day.day == _selectedDate.day;

        const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = DateTime(day.year, day.month, day.day)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryTeal : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primaryTeal : AppColors.borderLight,
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                Text(
                  dayNames[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white70 : AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
