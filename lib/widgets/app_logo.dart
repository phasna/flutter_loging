import 'package:flutter/material.dart';

/// Logo animé (apparition en fondu + zoom) avec un halo.
/// Utilise un [Hero] pour une transition fluide entre les écrans.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.onGradient = false});

  final double size;

  /// true quand le logo est posé sur le fond en dégradé (fond blanc + halo).
  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.scale(scale: value, child: child),
      ),
      child: Hero(
        tag: 'app-logo',
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.22),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onGradient ? Colors.white : scheme.primaryContainer,
            boxShadow: [
              BoxShadow(
                blurRadius: 30,
                spreadRadius: onGradient ? 6 : 0,
                color: onGradient
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.black12,
              ),
            ],
          ),
          child: Image.asset('assets/images/logo.png'),
        ),
      ),
    );
  }
}
