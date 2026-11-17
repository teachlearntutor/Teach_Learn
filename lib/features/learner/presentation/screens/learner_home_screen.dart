import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/contact_utils.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/utils/name_initials.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_staggered_item.dart';
import '../../../../core/widgets/contact_action_buttons.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/theme_mode_toggle.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../marketplace/domain/models/lesson_request.dart';
import '../../../marketplace/domain/models/tutor_profile.dart';
import '../../../marketplace/domain/tutor_location.dart';
import '../../../marketplace/presentation/providers/marketplace_providers.dart';
import '../../../marketplace/presentation/screens/find_tutor_screen.dart';
import '../../../marketplace/presentation/screens/my_requests_screen.dart';
import '../../../marketplace/presentation/screens/tutor_detail_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../domain/models/learner_preferences.dart';

class LearnerHomeScreen extends ConsumerStatefulWidget {
  const LearnerHomeScreen({super.key, this.onThemeModeChanged});

  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  ConsumerState<LearnerHomeScreen> createState() => _LearnerHomeScreenState();
}

class _LearnerHomeScreenState extends ConsumerState<LearnerHomeScreen> {
  int _selectedIndex = 0;
  final _pageController = PageController();

  void _navigateToTab(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    if (MediaQuery.of(context).disableAnimations) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = ref.watch(currentAuthUserProvider);

    final uid = user?.uid ?? '';
    final profileState = uid.isNotEmpty
        ? ref.watch(userProfileProvider(uid))
        : null;
    final userMap = profileState?.asData?.value;
    final authDisplayName = user?.displayName?.trim() ?? '';
    final displayName = authDisplayName.isNotEmpty
        ? authDisplayName
        : (userMap?['displayName'] as String? ?? 'Student');
    final role = userMap?['role'] as String? ?? 'student';
    final learnerPrefs = LearnerPreferences.fromMap(userMap);

    final isParent = role == 'parent';
    final spaceTitle = isParent
        ? 'Teach Learn Parent Space'
        : 'Teach Learn Student Space';
    final learnerRequestsState = ref.watch(learnerRequestsStreamProvider);
    final learnerRequests = learnerRequestsState.valueOrNull ?? [];
    final pendingRequests = learnerRequests
        .where((request) => request.status == LessonRequestStatus.pending)
        .toList();
    final acceptedRequests = learnerRequests
        .where((r) => r.status == LessonRequestStatus.accepted)
        .toList();
    final publishedTutorsState = ref.watch(publishedTutorsNotifierProvider);
    final hasPreferences =
        learnerPrefs.classLevel.isNotEmpty ||
        learnerPrefs.city.isNotEmpty ||
        learnerPrefs.area.isNotEmpty ||
        learnerPrefs.neededSubjects.isNotEmpty;
    final nearbyTutors = hasPreferences
        ? publishedTutorsState.tutors.where((tutor) {
            final sameCity =
                learnerPrefs.city.isNotEmpty &&
                tutor.city.trim().toLowerCase() ==
                    learnerPrefs.city.trim().toLowerCase();
            final sameArea =
                learnerPrefs.area.isNotEmpty &&
                (learnerPrefs.city.isEmpty || sameCity) &&
                normalizeTutorArea(tutor.area) ==
                    normalizeTutorArea(learnerPrefs.area);
            return sameCity || sameArea;
          }).toList()
        : <TutorProfile>[];
    nearbyTutors.sort((first, second) {
      final firstInArea =
          learnerPrefs.area.isNotEmpty &&
          (learnerPrefs.city.isEmpty ||
              first.city.trim().toLowerCase() ==
                  learnerPrefs.city.trim().toLowerCase()) &&
          normalizeTutorArea(first.area) ==
              normalizeTutorArea(learnerPrefs.area);
      final secondInArea =
          learnerPrefs.area.isNotEmpty &&
          (learnerPrefs.city.isEmpty ||
              second.city.trim().toLowerCase() ==
                  learnerPrefs.city.trim().toLowerCase()) &&
          normalizeTutorArea(second.area) ==
              normalizeTutorArea(learnerPrefs.area);
      if (firstInArea != secondInArea) return firstInArea ? -1 : 1;
      return first.displayName.compareTo(second.displayName);
    });

    final tabs = [
      // Home Tab
      RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(publishedTutorsNotifierProvider.notifier).loadInitial(),
            ref.refresh(learnerRequestsStreamProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Greeting & Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        isParent
                            ? Icons.family_restroom_rounded
                            : Icons.person_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, $displayName',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            AppButton.primary(
              label: 'Find Tutors',
              icon: Icon(
                Icons.search_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              isFullWidth: true,
              onPressed: () => _navigateToTab(1),
            ),
            if (nearbyTutors.isNotEmpty ||
                (hasPreferences && publishedTutorsState.isLoadingInitial)) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Near you', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              AnimatedSwitcher(
                duration: MediaQuery.of(context).disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                child: SizedBox(
                  key: ValueKey(publishedTutorsState.isLoadingInitial),
                  height: 132,
                  child: publishedTutorsState.isLoadingInitial
                      ? ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 2,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (_, _) => SizedBox(
                            width: 180,
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppLoader.skeleton(width: 120, height: 16),
                                  const SizedBox(height: AppSpacing.md),
                                  AppLoader.skeleton(
                                    width: double.infinity,
                                    height: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: nearbyTutors.length > 3
                              ? 3
                              : nearbyTutors.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final tutor = nearbyTutors[index];
                            final tutorLocation = [tutor.area, tutor.city]
                                .where((part) => part.trim().isNotEmpty)
                                .join(', ');
                            return AppStaggeredItem(
                              key: ValueKey(tutor.uid),
                              index: index,
                              child: SizedBox(
                                width: 180,
                                child: AppCard(
                                  padding: const EdgeInsets.all(12),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          TutorDetailScreen(tutor: tutor),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            child: Text(
                                              nameInitials(tutor.displayName),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Expanded(
                                            child: Text(
                                              tutor.displayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        tutor.subjects.take(2).join(', '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                      const SizedBox(height: 6),
                                      _TutorInfoChip(
                                        icon: Icons.location_on_outlined,
                                        label: tutorLocation.isEmpty
                                            ? 'Area unavailable'
                                            : tutorLocation,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
            if (!hasPreferences)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'Add your area and class to see tutors near you.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),

            // "My Tutors" Section (Accepted Requests)
            Text(
              'My Confirmed Tutors',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),

            if (acceptedRequests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'No confirmed tutors yet.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              Column(
                children: acceptedRequests.map((req) {
                  return Consumer(
                    builder: (context, ref, _) {
                      final tutorState = ref.watch(
                        tutorProfileByUidProvider(req.toUid),
                      );
                      final contactState = ref.watch(
                        tutorPrivateContactStreamProvider(req.toUid),
                      );
                      final tutorName = tutorState.when(
                        data: (profile) => req.toName.isNotEmpty
                            ? req.toName
                            : profile?.displayName ?? 'Tutor',
                        loading: () => 'Tutor',
                        error: (_, _) => 'Tutor',
                      );
                      final profile = tutorState.valueOrNull;
                      final phone = contactState.valueOrNull?.trim();
                      final location = [
                        req.area.isNotEmpty ? req.area : profile?.area ?? '',
                        req.city.isNotEmpty ? req.city : profile?.city ?? '',
                      ].where((part) => part.trim().isNotEmpty).join(', ');
                      final mode = req.mode.isNotEmpty
                          ? req.mode.toLowerCase()
                          : (profile?.mode ?? '').toLowerCase();
                      final modeLabel = switch (mode) {
                        'home' => 'Home',
                        'online' => 'Online',
                        'both' => 'Home / Online',
                        _ => mode.isEmpty ? 'Mode unavailable' : mode,
                      };
                      final subjects = req.subjects.isNotEmpty
                          ? req.subjects.join(', ')
                          : req.subject;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    child: Text(
                                      nameInitials(tutorName),
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
                                        const SizedBox(height: 2),
                                        Text(
                                          subjects,
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
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 140,
                                      ),
                                      child: _TutorInfoChip(
                                        icon: Icons.location_on_outlined,
                                        label: location.isEmpty
                                            ? 'Area unavailable'
                                            : location,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    _TutorInfoChip(
                                      label: modeLabel,
                                      icon: switch (mode) {
                                        'online' => Icons.wifi_rounded,
                                        'both' => Icons.home_work_outlined,
                                        _ => Icons.home_outlined,
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    const _TutorInfoChip(
                                      label: 'Accepted',
                                      icon: Icons.check_circle_outline_rounded,
                                    ),
                                  ],
                                ),
                              ),
                              if (phone != null && phone.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                ContactActionButtons(
                                  callLabel: 'Call Tutor',
                                  onCall: () => makePhoneCall(phone),
                                  onWhatsApp: () => launchWhatsAppContact(
                                    rawPhoneNumber: phone,
                                    message: buildTutorContactWhatsAppMessage(
                                      displayName,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: AppSpacing.lg),

            if (learnerRequestsState.hasError)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_outlined),
                  title: const Text('Requests unavailable'),
                  subtitle: Text(
                    formatUserFriendlyError(learnerRequestsState.error!),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'Retry',
                    onPressed: () =>
                        ref.invalidate(learnerRequestsStreamProvider),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
              ),
            if (pendingRequests.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Recent Requests',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Column(
                children: List.generate(pendingRequests.take(3).length, (
                  index,
                ) {
                  final request = pendingRequests[index];
                  return AppStaggeredItem(
                    key: ValueKey(request.id),
                    index: index,
                    child: Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        title: Text(
                          request.toName.isNotEmpty
                              ? request.toName
                              : request.subject,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          request.message.isNotEmpty
                              ? '${request.subject} · ${request.message}'
                              : request.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const StatusChip.present(label: 'PENDING'),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),

      // Find Tutor Tab
      const FindTutorScreen(),

      // My Requests Tab
      const MyRequestsScreen(),

      // Profile Tab
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(spaceTitle),
        actions: const [ThemeModeToggle()],
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            if (_selectedIndex != index) {
              setState(() => _selectedIndex = index);
            }
          },
          children: tabs,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _navigateToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Find Tutor',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outline_rounded),
            selectedIcon: Icon(Icons.mail_rounded),
            label: 'My Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _TutorInfoChip extends StatelessWidget {
  const _TutorInfoChip({this.icon, required this.label});

  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
