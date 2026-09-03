import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Offline Sync Indicator Widget as specified in Showcase Item #10.
/// Displays a subtle ivory/soft sage banner with connection status,
/// pending queue count badge, and a manual sync trigger.
class OfflineSyncIndicator extends StatelessWidget {
  final bool isOffline;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final VoidCallback? onSyncPressed;

  const OfflineSyncIndicator({
    super.key,
    required this.isOffline,
    this.pendingCount = 0,
    this.lastSyncTime,
    this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOffline
              ? AppColors.alertAmber.withValues(alpha: 0.5)
              : AppColors.softSage,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cloud / Status Icon
          Icon(
            isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
            size: 20,
            color: isOffline ? AppColors.alertAmber : AppColors.emerald,
          ),
          const SizedBox(width: 10),

          // Message & Last Sync Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOffline
                      ? 'Offline'
                      : 'Sync Complete',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextMain
                        : AppColors.textMain,
                  ),
                ),
                Text(
                  isOffline
                      ? 'Changes will sync when you\'re back online.'
                      : (lastSyncTime != null
                          ? 'Last synced ${_formatTime(lastSyncTime!)}'
                          : 'All changes saved safely.'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Pending Count Pill Badge
          if (pendingCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentGold, width: 0.5),
              ),
              child: Text(
                '$pendingCount pending',
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Refresh / Sync Button Action
          InkWell(
            onTap: onSyncPressed,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
