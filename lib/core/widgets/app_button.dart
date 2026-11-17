import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import 'app_loader.dart';

enum AppButtonVariant { primary, accent, secondary, ghost }

/// Premium button with scale tap motion & inline loader.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = false,
  });

  const factory AppButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading,
    Widget? icon,
    bool isFullWidth,
  }) = _PrimaryButton;

  const factory AppButton.accent({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading,
    Widget? icon,
    bool isFullWidth,
  }) = _AccentButton;

  const factory AppButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading,
    Widget? icon,
    bool isFullWidth,
  }) = _SecondaryButton;

  const factory AppButton.ghost({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading,
    Widget? icon,
    bool isFullWidth,
  }) = _GhostButton;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final borderColor = theme.brightness == Brightness.dark
        ? colors.outlineVariant
        : colors.outlineVariant.withValues(alpha: 0.45);
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    Color backgroundColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        backgroundColor = isDisabled
            ? colors.surfaceContainerHighest
            : colors.primary;
        textColor = isDisabled ? colors.onSurfaceVariant : colors.onPrimary;
        break;

      case AppButtonVariant.accent:
        backgroundColor = isDisabled
            ? colors.surfaceContainerHighest
            : colors.secondary;
        textColor = isDisabled ? colors.onSurfaceVariant : colors.onSecondary;
        break;

      case AppButtonVariant.secondary:
        backgroundColor = colors.surface;
        textColor = isDisabled ? colors.onSurfaceVariant : colors.onSurface;
        borderSide = BorderSide(color: borderColor);
        break;

      case AppButtonVariant.ghost:
        backgroundColor = _isPressed
            ? colors.surfaceContainerHighest
            : Colors.transparent;
        textColor = isDisabled ? colors.onSurfaceVariant : colors.onSurface;
        break;
    }

    final label = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
    );

    final buttonContent = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          AppLoader.inline(size: 18, color: textColor),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: 8),
        ],
        if (widget.isFullWidth)
          Expanded(child: label)
        else
          Flexible(child: label),
      ],
    );

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed && !reduceMotion ? 0.98 : 1.0,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          child: Material(
            color: backgroundColor,
            borderRadius: AppRadii.buttonBorderRadius,
            child: InkWell(
              onTap: isDisabled ? null : widget.onPressed,
              borderRadius: AppRadii.buttonBorderRadius,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadii.buttonBorderRadius,
                  border: borderSide != BorderSide.none
                      ? Border.fromBorderSide(borderSide)
                      : null,
                ),
                child: buttonContent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends AppButton {
  const _PrimaryButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.isLoading,
    super.icon,
    super.isFullWidth,
  }) : super(variant: AppButtonVariant.primary);
}

class _AccentButton extends AppButton {
  const _AccentButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.isLoading,
    super.icon,
    super.isFullWidth,
  }) : super(variant: AppButtonVariant.accent);
}

class _SecondaryButton extends AppButton {
  const _SecondaryButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.isLoading,
    super.icon,
    super.isFullWidth,
  }) : super(variant: AppButtonVariant.secondary);
}

class _GhostButton extends AppButton {
  const _GhostButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.isLoading,
    super.icon,
    super.isFullWidth,
  }) : super(variant: AppButtonVariant.ghost);
}
