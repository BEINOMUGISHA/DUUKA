import 'dart:math' as math;

import 'package:flutter/material.dart';

class AuthCapitalFlowBackground extends StatefulWidget {
  const AuthCapitalFlowBackground({super.key});

  @override
  State<AuthCapitalFlowBackground> createState() =>
      _AuthCapitalFlowBackgroundState();
}

class _AuthCapitalFlowBackgroundState extends State<AuthCapitalFlowBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _CapitalFlowPainter(_controller),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _CapitalFlowPainter extends CustomPainter {
  final Animation<double> animation;
  late final List<_Star> _stars;
  late final List<_OrbitingAsset> _assets;

  _CapitalFlowPainter(this.animation) : super(repaint: animation) {
    final random = math.Random(42);
    _stars = List.generate(
      150,
      (_) => _Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: 0.4 + random.nextDouble() * 1.6,
        phase: random.nextDouble() * math.pi * 2,
      ),
    );
    _assets = List.generate(18, (index) {
      final isNote = index < 12;
      return _OrbitingAsset(
        isNote: isNote,
        orbit: 0.31 + random.nextDouble() * 0.18,
        phase: random.nextDouble() * math.pi * 2,
        tilt: (random.nextDouble() - 0.5) * 1.1,
        speed: (isNote ? 0.7 : 0.95) * (random.nextDouble() < 0.5 ? 1 : -1),
        scale: isNote ? 0.8 + random.nextDouble() * 0.45 : 0.8,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.62, size.height * 0.5);
    final earthRadius = math.min(size.width, size.height) * 0.24;
    final time = animation.value * math.pi * 2;

    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF010509));
    _paintStars(canvas, size, time);
    _paintOrbit(canvas, center, earthRadius, math.pi * 0.12, 0.24);
    _paintOrbit(canvas, center, earthRadius, -math.pi * 0.2, 0.33);
    _paintEarth(canvas, center, earthRadius);

    for (final asset in _assets) {
      final angle = time * asset.speed + asset.phase;
      final orbitRadius = earthRadius * (1.95 + asset.orbit);
      final x = math.cos(angle) * orbitRadius;
      final y = math.sin(angle) * orbitRadius * (0.36 + asset.orbit * 0.28);
      final position = center + Offset(x, y);
      _paintAsset(canvas, position, asset, angle);
    }

    final vignette = RadialGradient(
      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
      stops: const [0.48, 1],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = vignette);
  }

  void _paintStars(Canvas canvas, Size size, double time) {
    for (final star in _stars) {
      final twinkle = 0.45 + 0.55 * math.sin(time * 1.3 + star.phase);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        Paint()..color = Colors.white.withValues(alpha: twinkle * 0.65),
      );
    }
  }

  void _paintOrbit(
      Canvas canvas, Offset center, double radius, double tilt, double scale) {
    final rect = Rect.fromCenter(
      center: center,
      width: radius * (2 + scale),
      height: radius * (0.58 + scale * 0.3),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = const Color(0xFF6FA8FF).withValues(alpha: 0.2),
    );
    canvas.restore();
  }

  void _paintEarth(Canvas canvas, Offset center, double radius) {
    final atmosphere = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2F91D2).withValues(alpha: 0.1),
          const Color(0xFF5FB2FF).withValues(alpha: 0.4),
          Colors.transparent,
        ],
        stops: const [0.78, 0.93, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.16));
    canvas.drawCircle(center, radius * 1.16, atmosphere);

    final earthPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 1.1,
        colors: const [Color(0xFF477C96), Color(0xFF143C5A), Color(0xFF061522)],
        stops: const [0, 0.52, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, earthPaint);

    final landPaint = Paint()
      ..color = const Color(0xFF3D765E).withValues(alpha: 0.65);
    final land = Path()
      ..moveTo(center.dx - radius * 0.65, center.dy - radius * 0.08)
      ..quadraticBezierTo(center.dx - radius * 0.25, center.dy - radius * 0.65,
          center.dx + radius * 0.12, center.dy - radius * 0.25)
      ..quadraticBezierTo(center.dx + radius * 0.5, center.dy + radius * 0.05,
          center.dx + radius * 0.2, center.dy + radius * 0.4)
      ..quadraticBezierTo(center.dx - radius * 0.2, center.dy + radius * 0.18,
          center.dx - radius * 0.65, center.dy - radius * 0.08)
      ..close();
    canvas.drawPath(land, landPaint);

    final shine = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withValues(alpha: 0.22), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, shine);
  }

  void _paintAsset(
      Canvas canvas, Offset position, _OrbitingAsset asset, double angle) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(asset.tilt + angle * 0.35);
    final opacity = asset.isNote ? 0.88 : 0.95;
    if (asset.isNote) {
      final noteRect = Rect.fromCenter(
        center: Offset.zero,
        width: 46 * asset.scale,
        height: 21 * asset.scale,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(noteRect, const Radius.circular(2)),
        Paint()..color = const Color(0xFFE8E2C8).withValues(alpha: opacity),
      );
      canvas.drawRect(
        noteRect.deflate(3 * asset.scale),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF2E5E3E).withValues(alpha: opacity),
      );
      canvas.drawCircle(Offset.zero, 5 * asset.scale,
          Paint()..color = const Color(0xFF2E5E3E).withValues(alpha: 0.6));
    } else {
      final radius = 9 * asset.scale;
      canvas.drawCircle(
          Offset.zero, radius, Paint()..color = const Color(0xFF8A6412));
      canvas.drawCircle(
          Offset.zero, radius * 0.8, Paint()..color = const Color(0xFFE2B04A));
      canvas.drawCircle(
        Offset.zero,
        radius * 0.62,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF6B4C0A),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CapitalFlowPainter oldDelegate) => false;
}

class _Star {
  final double x;
  final double y;
  final double radius;
  final double phase;

  const _Star(
      {required this.x,
      required this.y,
      required this.radius,
      required this.phase});
}

class _OrbitingAsset {
  final bool isNote;
  final double orbit;
  final double phase;
  final double tilt;
  final double speed;
  final double scale;

  const _OrbitingAsset({
    required this.isNote,
    required this.orbit,
    required this.phase,
    required this.tilt,
    required this.speed,
    required this.scale,
  });
}
