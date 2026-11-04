import 'package:flutter/material.dart';

import '../state/auth_controller.dart';
import '../widgets/app_logo.dart';
import '../widgets/profile_info_tile.dart';

/// Écran de profil : affiche les données renvoyées par l'API.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final AuthController controller;

  void _logout(BuildContext context) {
    controller.logout();
    Navigator.pop(context); // Retour à l'écran de connexion
  }

  @override
  Widget build(BuildContext context) {
    final user = controller.user;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Non connecté')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  const AppLogo(size: 72),
                  const SizedBox(height: 16),
                  Text('Bonjour ${user.firstName} 👋',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          ProfileInfoTile(
                              icon: Icons.badge_outlined,
                              label: 'Identifiant',
                              value: '#${user.id}'),
                          ProfileInfoTile(
                              icon: Icons.person_outline,
                              label: 'Nom',
                              value: user.fullName),
                          ProfileInfoTile(
                              icon: Icons.mail_outline,
                              label: 'Email',
                              value: user.email),
                          ProfileInfoTile(
                              icon: Icons.security,
                              label: 'Rôle',
                              value: '${user.roleLabel} (${user.role})'),
                          if (controller.token != null)
                            ProfileInfoTile(
                              icon: Icons.key_outlined,
                              label: 'Token de session',
                              // Seul le début du token est affiché
                              value: '${controller.token!.substring(0, 12)}…',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('Se déconnecter'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
