import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../state/auth_controller.dart';
import '../widgets/app_logo.dart';
import '../widgets/attempts_banner.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/gradient_background.dart';
import '../widgets/loading_button.dart';
import '../widgets/shake_widget.dart';
import 'profile_screen.dart';

/// Écran de connexion : formulaire validé + appel à l'API via [AuthController].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  AuthController get _auth => widget.controller;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus(); // Fermer le clavier
    if (!_formKey.currentState!.validate()) {
      _shakeKey.currentState?.shake();
      return;
    }

    final outcome =
        await _auth.login(_emailController.text, _passwordController.text);
    if (!mounted) return;

    switch (outcome) {
      case LoginOutcome.success:
        _passwordController.clear();
        // Le profil remplace l'écran de connexion (retour impossible)
        await Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, _, _) => ProfileScreen(controller: _auth),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      case LoginOutcome.houston:
        _shakeKey.currentState?.shake();
        _showDialog(
          icon: Icons.rocket_launch,
          title: 'Houston, nous avons un problème !',
          message: '${_auth.failedAttempts} tentatives de connexion incorrectes.',
        );
      case LoginOutcome.invalidCredentials:
        _shakeKey.currentState?.shake();
        _showDialog(
          icon: Icons.lock_outline,
          title: 'Erreur',
          message: 'Email ou mot de passe incorrect '
              '(tentative ${_auth.failedAttempts}/${ApiConfig.maxFailedAttempts}).',
        );
      case LoginOutcome.error:
        _showDialog(
          icon: Icons.cloud_off,
          title: 'Connexion impossible',
          message: _auth.lastError ?? 'Une erreur est survenue.',
        );
    }
  }

  void _showDialog({
    required IconData icon,
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(icon, size: 36),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          // Design réactif : défilement sur petit écran / paysage,
          // largeur limitée sur tablette.
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: ListenableBuilder(
                  listenable: _auth,
                  builder: (context, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo(onGradient: true),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: Text('Bienvenue',
                            style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                      const SizedBox(height: 4),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 250),
                        child: Text('Connectez-vous pour continuer',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: Colors.white70)),
                      ),
                      const SizedBox(height: 28),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 350),
                        child: ShakeWidget(
                          key: _shakeKey,
                          child: _buildFormCard(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 500),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock, size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Connexion sécurisée · ESGI M2 2026',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Carte blanche contenant le formulaire.
  Widget _buildFormCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AttemptsBanner(
              failedAttempts: _auth.failedAttempts,
              max: ApiConfig.maxFailedAttempts,
            ),
            // Champ Email
            TextFormField(
              controller: _emailController,
              enabled: !_auth.isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'nom@exemple.com',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer votre email';
                }
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
                  return 'Veuillez entrer un email valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Champ Mot de passe
            TextFormField(
              controller: _passwordController,
              enabled: !_auth.isLoading,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Afficher le mot de passe'
                      : 'Masquer le mot de passe',
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre mot de passe';
                }
                if (value.length < 4) {
                  return 'Le mot de passe doit contenir au moins 4 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            LoadingButton(
              label: 'Se connecter',
              icon: Icons.login,
              isLoading: _auth.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
