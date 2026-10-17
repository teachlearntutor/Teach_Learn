import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Color backgroundColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        backgroundColor = isDisabled
            ? (isDark ? AppColors.surfaceDark : AppColors.borderLight)
            : (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal);
        textColor = isDisabled
            ? (isDark ? AppColors.darkInkMuted : AppColors.inkMuted)
            : Colors.white;
        break;

      case AppButtonVariant.accent:
        backgroundColor = isDisabled
            ? (isDark ? AppColors.surfaceDark : AppColors.borderLight)
            : AppColors.accentTeal;
        textColor = isDisabled
            ? (isDark ? AppColors.darkInkMuted : AppColors.inkMuted)
            : AppColors.ink;
        break;

      case AppButtonVariant.secondary:
        backgroundColor = isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight;
        textColor = isDisabled
            ? (isDark ? AppColors.darkInkMuted : AppColors.inkMuted)
            : (isDark ? AppColors.darkInk : AppColors.ink);
        borderSide = BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.0,
        );
        break;

      case AppButtonVariant.ghost:
        backgroundColor = _isPressed
            ? (isDark
                  ? AppColors.surfaceDark
                  : AppColors.borderLight.withValues(alpha: 0.5))
            : Colors.transparent;
        textColor = isDisabled
            ? (isDark ? AppColors.darkInkMuted : AppColors.inkMuted)
            : (isDark ? AppColors.darkInk : AppColors.ink);
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
        if (widget.isFullWidth) Expanded(child: label) else label,
      ],
    );

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
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
