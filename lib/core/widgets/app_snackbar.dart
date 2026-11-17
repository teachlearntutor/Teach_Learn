import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

OverlayEntry? _activeToast;

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isSuccess = false,
  String? diagnostic,
  Duration duration = const Duration(milliseconds: 2500),
  String? actionLabel,
  VoidCallback? onActionPressed,
}) {
  if (!context.mounted) return;
  clearAppSnackBars(context);

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final mediaQuery = MediaQuery.of(context);

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      bottom: mediaQuery.padding.bottom + mediaQuery.viewInsets.bottom + 90,
      left: 16,
      right: 16,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _AppToast(
            message: message,
            isError: isError,
            isSuccess: isSuccess,
            diagnostic: diagnostic,
            duration: duration,
            actionLabel: actionLabel,
            onActionPressed: onActionPressed,
            onDismiss: () {
              if (identical(_activeToast, entry)) {
                entry.remove();
                _activeToast = null;
              }
            },
          ),
        ),
      ),
    ),
  );
  _activeToast = entry;
  overlay.insert(entry);
}

void clearAppSnackBars(BuildContext context) {
  if (!context.mounted) return;
  final toast = _activeToast;
  _activeToast = null;
  toast?.remove();
}

void clearActiveAppToast() {
  final toast = _activeToast;
  _activeToast = null;
  toast?.remove();
}

class AppToastNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    clearActiveAppToast();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    clearActiveAppToast();
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    clearActiveAppToast();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class _AppToast extends StatefulWidget {
  const _AppToast({
    required this.message,
    required this.isError,
    required this.isSuccess,
    required this.diagnostic,
    required this.duration,
    required this.actionLabel,
    required this.onActionPressed,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final bool isSuccess;
  final String? diagnostic;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final VoidCallback onDismiss;

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  double _dragDistance = 0;

  IconData get _icon {
    if (widget.isError) return Icons.error_outline_rounded;
    if (widget.isSuccess) return Icons.check_circle_outline_rounded;
    return Icons.info_outline_rounded;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 180),
    )..forward();
    final easeOut = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(easeOut);
    _fadeAnimation = easeOut;
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted ||
        _animationController.status == AnimationStatus.dismissed ||
        _animationController.status == AnimationStatus.reverse) {
      return;
    }
    _timer?.cancel();
    _animationController.reverse().whenCompleteOrCancel(widget.onDismiss);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = widget.isError
        ? theme.colorScheme.error
        : widget.isSuccess
        ? (isDark ? AppColors.darkSuccessText : AppColors.success)
        : theme.colorScheme.primary;
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        _dragDistance += details.delta.dx;
        if (_dragDistance.abs() > 36) _dismiss();
      },
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -8) _dismiss();
      },
      child: reduceMotion
          ? _buildMaterial(theme, accentColor)
          : SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildMaterial(theme, accentColor),
              ),
            ),
    );
  }

  Widget _buildMaterial(ThemeData theme, Color accentColor) {
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.14),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(_icon, color: accentColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.diagnostic != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.diagnostic!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.actionLabel != null &&
                widget.onActionPressed != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  widget.onActionPressed!();
                  _dismiss();
                },
                style: TextButton.styleFrom(
                  foregroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(widget.actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
