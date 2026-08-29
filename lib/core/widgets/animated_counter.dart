import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

enum CounterFormat { currency, integer, percentage, decimal }

class AnimatedCounter extends StatelessWidget {
  final double value;
  final CounterFormat format;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.format = CounterFormat.currency,
    this.style,
    this.duration = const Duration(milliseconds: 750),
    this.curve = Curves.easeOutCubic,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, val, child) {
        String formatted;
        switch (format) {
          case CounterFormat.currency:
            formatted = CurrencyFormatter.format(val);
            break;
          case CounterFormat.integer:
            formatted = val.toInt().toString();
            break;
          case CounterFormat.percentage:
            formatted = '${val.toInt()}%';
            break;
          case CounterFormat.decimal:
            formatted = val.toStringAsFixed(1);
            break;
        }

        final displayText = '${prefix ?? ''}$formatted${suffix ?? ''}';
        return Text(displayText, style: style);
      },
    );
  }
}
