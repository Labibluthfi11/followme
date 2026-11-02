import 'package:flutter/material.dart';
import '../theme/followme_design_tokens.dart';

enum StatusBadgeVariant { success, warning, danger, info, neutral }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.neutral,
  });

  final String label;
  final StatusBadgeVariant variant;

  Color get _backgroundColor {
    switch (variant) {
      case StatusBadgeVariant.success:
        return FollowMeDesign.greenBadgeBg;
      case StatusBadgeVariant.warning:
        return FollowMeDesign.warningBg;
      case StatusBadgeVariant.danger:
        return const Color(0xFFFEE2E2);
      case StatusBadgeVariant.info:
        return const Color(0xFFE0F2FE);
      case StatusBadgeVariant.neutral:
        return const Color(0xFFE2E8F0);
    }
  }

  Color get _foregroundColor {
    switch (variant) {
      case StatusBadgeVariant.success:
        return FollowMeDesign.greenBadgeText;
      case StatusBadgeVariant.warning:
        return FollowMeDesign.warningText;
      case StatusBadgeVariant.danger:
        return const Color(0xFF991B1B);
      case StatusBadgeVariant.info:
        return const Color(0xFF075985);
      case StatusBadgeVariant.neutral:
        return FollowMeDesign.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _foregroundColor,
        ),
      ),
    );
  }
}
