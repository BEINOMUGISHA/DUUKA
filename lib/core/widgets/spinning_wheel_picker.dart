import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Generic model for wheel items
class WheelPickerItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final String? trailing;
  final IconData? icon;
  final Color? color;

  const WheelPickerItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
    this.color,
  });
}

/// TradingView-inspired 3D Spinning Wheel Scroll List with Haptic Feedback
class SpinningWheelPicker<T> extends StatefulWidget {
  final List<WheelPickerItem<T>> items;
  final int initialIndex;
  final ValueChanged<int> onItemSelected;
  final double height;
  final double itemExtent;
  final double diameterRatio;
  final double perspective;
  final bool enableHaptics;

  const SpinningWheelPicker({
    super.key,
    required this.items,
    required this.onItemSelected,
    this.initialIndex = 0,
    this.height = 260,
    this.itemExtent = 64,
    this.diameterRatio = 1.8,
    this.perspective = 0.004,
    this.enableHaptics = true,
  });

  @override
  State<SpinningWheelPicker<T>> createState() => _SpinningWheelPickerState<T>();
}

class _SpinningWheelPickerState<T> extends State<SpinningWheelPicker<T>> {
  late FixedExtentScrollController _controller;
  late int _selectedIndex;
  int _lastHapticIndex = -1;
  DateTime _lastHapticTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, widget.items.isEmpty ? 0 : widget.items.length - 1);
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
    _lastHapticIndex = _selectedIndex;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerHaptic(int index) {
    if (!widget.enableHaptics) return;

    final now = DateTime.now();
    final timeDiff = now.difference(_lastHapticTime).inMilliseconds;

    // Throttle fast flings if under 40ms to avoid overwhelming vibration motors
    if (timeDiff > 35 && index != _lastHapticIndex) {
      _lastHapticIndex = index;
      _lastHapticTime = now;
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Visual Lens / Selection Highlight Bar
          Container(
            height: widget.itemExtent,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.emeraldNeon.withValues(alpha: 0.12)
                  : AppColors.primaryForest.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.emeraldNeon.withValues(alpha: 0.4)
                    : AppColors.primaryForest.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
          ),

          // 3D ListWheelScrollView
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: widget.itemExtent,
            diameterRatio: widget.diameterRatio,
            perspective: widget.perspective,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
              _triggerHaptic(index);
              widget.onItemSelected(index);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.items.length,
              builder: (context, index) {
                final item = widget.items[index];
                final isSelected = index == _selectedIndex;

                return Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        if (item.icon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (item.color ?? AppColors.primaryForest).withValues(alpha: isSelected ? 0.2 : 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.icon,
                              size: 20,
                              color: item.color ?? (isSelected ? AppColors.primaryForest : AppColors.textMuted),
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: isSelected ? 16 : 14,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                  color: isSelected
                                      ? (isDark ? AppColors.darkTextMain : AppColors.textMain)
                                      : (isDark ? AppColors.darkTextMuted.withValues(alpha: 0.5) : AppColors.textLight),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? (isDark ? AppColors.darkTextMuted : AppColors.textMuted)
                                        : (isDark ? AppColors.darkTextMuted.withValues(alpha: 0.4) : AppColors.textLight),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (item.trailing != null) ...[
                          Text(
                            item.trailing!,
                            style: TextStyle(
                              fontSize: isSelected ? 14 : 12,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              color: isSelected
                                  ? (item.color ?? AppColors.primaryForest)
                                  : AppColors.textLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
