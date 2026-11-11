import 'package:flutter/material.dart';

import '../core/constants/app_theme.dart';
import '../services/attendance_location_service.dart';

class LocationStatusCard extends StatelessWidget {
  final bool isWithinRadius;
  final bool isLoading;
  final String message;
  final VoidCallback? onRetry;
  final double? radiusMeters;

  const LocationStatusCard({
    super.key,
    required this.isWithinRadius,
    required this.isLoading,
    required this.message,
    this.onRetry,
    this.radiusMeters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = isWithinRadius
        ? FollowMeTokens.present
        : FollowMeTokens.late;

    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(FollowMeTokens.radiusMedium),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.08),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: statusColor.withValues(alpha: 0.65),
                    ),
                  ),
                Icon(
                  isWithinRadius
                      ? Icons.location_on_rounded
                      : Icons.location_searching_rounded,
                  color: statusColor,
                  size: 23,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isWithinRadius
                      ? 'Di area kerja'
                      : isLoading
                      ? 'Memeriksa lokasi'
                      : 'Lokasi belum sesuai',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Radius absensi ${(radiusMeters ?? AttendanceLocationService.allowedRadiusMeters).round()} m',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              tooltip: 'Perbarui lokasi',
              onPressed: isLoading ? null : onRetry,
              icon: const Icon(Icons.refresh_rounded),
              color: theme.colorScheme.primary,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            ),
        ],
      ),
    );
  }
}
