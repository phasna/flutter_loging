import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fait « trembler » son enfant horizontalement (ex. mauvais mot de passe).
/// Usage : `final key = GlobalKey<ShakeWidgetState>(); ... key.currentState?.shake();`
class ShakeWidget extends StatefulWidget {
  const ShakeWidget({super.key, required this.child});

  final Widget child;

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  void shake() => _controller.forward(from: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Oscillation amortie : 3 allers-retours qui diminuent
        final v = _controller.value;
        final dx = math.sin(v * math.pi * 6) * 14 * (1 - v);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
