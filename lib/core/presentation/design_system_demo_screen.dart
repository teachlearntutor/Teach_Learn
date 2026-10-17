import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_text_field.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/status_chip.dart';

class DesignSystemDemoScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ThemeMode currentThemeMode;

  const DesignSystemDemoScreen({
    super.key,
    required this.onThemeModeChanged,
    required this.currentThemeMode,
  });

  @override
  State<DesignSystemDemoScreen> createState() => _DesignSystemDemoScreenState();
}

class _DesignSystemDemoScreenState extends State<DesignSystemDemoScreen> {
  bool _isLoadingButtons = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.currentThemeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('TeachLearn'),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: () {
              widget.onThemeModeChanged(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  'DESIGN PREVIEW',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Learning, thoughtfully matched.',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'A shared visual language for learners, families, and tutors.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                _sectionHeader(context, 'Tutor discovery'),
                const SizedBox(height: AppSpacing.md),
                const AppTextField(
                  label: 'Search tutors',
                  hint: 'Subject, class, or city',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              'AR',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Amina Rahman',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Mathematics · Physics',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.primaryTeal,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Lahore · Gulberg',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'PKR 8,000 - 12,000 / month',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '4.9',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Online · At home',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          AppButton.ghost(
                            label: 'View',
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _sectionHeader(context, 'Buttons and status'),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppButton.primary(
                        label: 'Request a lesson',
                        isLoading: _isLoadingButtons,
                        onPressed: () {},
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton.secondary(
                        label: 'Save tutor',
                        icon: const Icon(
                          Icons.bookmark_border_rounded,
                          size: 20,
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: const [
                          StatusChip(
                            label: 'Pending',
                            type: StatusType.pending,
                          ),
                          StatusChip(
                            label: 'Accepted',
                            type: StatusType.accepted,
                          ),
                          StatusChip(label: 'Paid', type: StatusType.paid),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Preview loading state'),
                        value: _isLoadingButtons,
                        onChanged: (value) =>
                            setState(() => _isLoadingButtons = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _sectionHeader(context, 'Loading and empty states'),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const AppLoader.inline(size: 24),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Loading tutors',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppLoader.skeleton(width: double.infinity, height: 14),
                      const SizedBox(height: AppSpacing.sm),
                      AppLoader.skeleton(width: 180, height: 14),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const EmptyStateWidget(
                  icon: Icons.event_available_outlined,
                  title: 'No lessons scheduled',
                  description: 'Your upcoming lessons will appear here.',
                  actionLabel: 'Explore tutors',
                  onActionPressed: _onExplorePressed,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _onExplorePressed() {}

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.headlineSmall);
  }
}
