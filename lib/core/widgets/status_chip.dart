import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

enum StatusType {
  paid,
  unpaid,
  partial,
  present,
  absent,
  late,
  active,
  paused,
  left,
  pending,
  accepted,
  declined,
}

/// Status chip used across attendance and student management.
class StatusChip extends StatelessWidget {
  final String label;
  final StatusType type;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.label,
    required this.type,
    this.onTap,
  });

  const StatusChip.paid({Key? key, String label = "Paid", VoidCallback? onTap})
    : this(key: key, label: label, type: StatusType.paid, onTap: onTap);

  const StatusChip.unpaid({
    Key? key,
    String label = "Unpaid",
    VoidCallback? onTap,
  }) : this(key: key, label: label, type: StatusType.unpaid, onTap: onTap);

  const StatusChip.partial({
    Key? key,
    String label = "Partial",
    VoidCallback? onTap,
  }) : this(key: key, label: label, type: StatusType.partial, onTap: onTap);

  const StatusChip.present({
    Key? key,
    String label = "Present",
    VoidCallback? onTap,
  }) : this(key: key, label: label, type: StatusType.present, onTap: onTap);

  const StatusChip.absent({
    Key? key,
    String label = "Absent",
    VoidCallback? onTap,
  }) : this(key: key, label: label, type: StatusType.absent, onTap: onTap);

  const StatusChip.late({Key? key, String label = "Late", VoidCallback? onTap})
    : this(key: key, label: label, type: StatusType.late, onTap: onTap);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;

    switch (type) {
      case StatusType.paid:
      case StatusType.present:
      case StatusType.active:
      case StatusType.accepted:
        bg = isDark ? AppColors.darkSuccessSurface : AppColors.successSurface;
        fg = AppColors.success;
        break;

      case StatusType.unpaid:
      case StatusType.absent:
      case StatusType.left:
      case StatusType.declined:
        bg = isDark ? AppColors.darkDangerSurface : AppColors.dangerSurface;
        fg = AppColors.danger;
        break;

      case StatusType.partial:
      case StatusType.late:
      case StatusType.paused:
      case StatusType.pending:
        bg = isDark ? AppColors.darkWarningSurface : AppColors.warningSurface;
        fg = AppColors.warning;
        break;
    }

    final chipContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.chipBorderRadius,
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: chipContent);
    }

    return chipContent;
  }
}
