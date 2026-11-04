import 'package:flutter/material.dart';

/// Logo animé (apparition en fondu + zoom) affiché en haut de l'écran.
/// Utilise un [Hero] pour une transition fluide vers l'écran de profil.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
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
          padding: EdgeInsets.all(size * 0.2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primaryContainer,
            boxShadow: const [
              BoxShadow(blurRadius: 12, color: Colors.black12, offset: Offset(0, 4)),
            ],
          ),
          child: Image.asset('assets/images/logo.png'),
        ),
      ),
    );
  }
}
