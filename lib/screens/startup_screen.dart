import 'package:flutter/material.dart';

import '../state/auth_controller.dart';
import '../widgets/app_logo.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

/// Écran de démarrage : tente de restaurer la session à partir du token
/// stocké de façon sécurisée, puis affiche le profil ou l'écran de connexion.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final restored = await widget.controller.restoreSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => restored
            ? ProfileScreen(controller: widget.controller)
            : LoginScreen(controller: widget.controller),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(),
            SizedBox(height: 32),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
