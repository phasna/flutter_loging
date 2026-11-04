import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fond en dégradé animé avec des bulles décoratives qui flottent lentement.
class GradientBackground extends StatefulWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Accessibilité : pas d'animation en boucle si l'utilisateur a demandé
    // de réduire les animations (réglage système).
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = dark
        ? const [Color(0xFF1A1B4B), Color(0xFF2D1B4E), Color(0xFF0F2A4A)]
        : const [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF2563EB)];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(math.cos(t), math.sin(t)),
              end: Alignment(-math.cos(t), -math.sin(t)),
              colors: colors,
            ),
          ),
          child: Stack(
            children: [
              _bubble(top: -60 + 20 * math.sin(t), left: -40, size: 220),
              _bubble(bottom: -80 + 25 * math.cos(t), right: -60, size: 260),
              _bubble(top: 140 + 15 * math.cos(t), right: 30, size: 70),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }

  Widget _bubble({double? top, double? left, double? right, double? bottom,
      required double size}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }
}
