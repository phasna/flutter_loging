import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../state/auth_controller.dart';
import '../widgets/app_logo.dart';
import '../widgets/attempts_banner.dart';
import '../widgets/loading_button.dart';
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
    if (!_formKey.currentState!.validate()) return;

    final outcome =
        await _auth.login(_emailController.text, _passwordController.text);
    if (!mounted) return;

    switch (outcome) {
      case LoginOutcome.success:
        _passwordController.clear();
        // Le profil remplace l'écran de connexion (retour impossible)
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(controller: _auth),
          ),
        );
      case LoginOutcome.houston:
        _showDialog(
          icon: Icons.rocket_launch,
          title: 'Houston, nous avons un problème !',
          message: '${_auth.failedAttempts} tentatives de connexion incorrectes.',
        );
      case LoginOutcome.invalidCredentials:
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
        icon: Icon(icon),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        // Design réactif : défilement sur petit écran / paysage,
        // largeur limitée sur tablette.
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListenableBuilder(
                listenable: _auth,
                builder: (context, _) => Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo(),
                      const SizedBox(height: 24),
                      Text('Bienvenue',
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Connectez-vous pour continuer',
                          style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 32),
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
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre email';
                          }
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(value.trim())) {
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
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
