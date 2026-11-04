import 'package:flutter/material.dart';

import 'screens/startup_screen.dart';
import 'state/auth_controller.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(LoginApp(controller: AuthController()));
}

/// Point d'entrée de l'application de connexion (DS – authentification API REST).
class LoginApp extends StatelessWidget {
  const LoginApp({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connexion API',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: StartupScreen(controller: controller),
    );
  }
}
