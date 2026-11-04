import 'package:flutter/material.dart';

import '../state/auth_controller.dart';
import '../widgets/app_logo.dart';
import '../widgets/profile_info_tile.dart';
import 'login_screen.dart';

/// Écran de profil : affiche les données renvoyées par l'API et vérifie le
/// token via une requête sécurisée (GET /profile.php avec Authorization: Bearer).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _verifying = false;

  AuthController get _auth => widget.controller;

  @override
  void initState() {
    super.initState();
    // Requête sécurisée dès l'ouverture si le token n'a pas encore été vérifié
    if (_auth.tokenVerifiedAt == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
    }
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    await _auth.verifySession();
    if (mounted) setState(() => _verifying = false);
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    // Retour à l'écran de connexion (en vidant la pile de navigation)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(controller: _auth)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _auth,
          builder: (context, _) {
            final user = _auth.user;
            if (user == null) {
              return const Center(child: Text('Non connecté'));
            }
            return Center(
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TokenStatusCard(
                        token: _auth.token,
                        verifiedAt: _auth.tokenVerifiedAt,
                        error: _auth.lastError,
                        verifying: _verifying,
                        onVerify: _verify,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Se déconnecter'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Carte qui affiche l'état du token et permet de relancer la requête sécurisée.
class _TokenStatusCard extends StatelessWidget {
  const _TokenStatusCard({
    required this.token,
    required this.verifiedAt,
    required this.error,
    required this.verifying,
    required this.onVerify,
  });

  final String? token;
  final DateTime? verifiedAt;
  final String? error;
  final bool verifying;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final verified = verifiedAt != null;
    final time = verified
        ? '${verifiedAt!.hour.toString().padLeft(2, '0')}:'
            '${verifiedAt!.minute.toString().padLeft(2, '0')}'
        : null;

    return Card(
      color: verified ? scheme.primaryContainer : scheme.surfaceContainerLow,
      child: ListTile(
        leading: verifying
            ? const SizedBox(
                width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))
            : Icon(verified ? Icons.verified_user : Icons.key_outlined),
        title: Text(verified ? 'Token vérifié par l\'API' : 'Token de session'),
        subtitle: Text(
          verifying
              ? 'Vérification en cours…'
              : verified
                  ? 'Requête sécurisée OK à $time · ${_short(token)}'
                  : (error ?? _short(token)),
        ),
        trailing: IconButton(
          tooltip: 'Vérifier le token',
          icon: const Icon(Icons.refresh),
          onPressed: verifying ? null : onVerify,
        ),
      ),
    );
  }

  /// Affiche seulement le début du token.
  static String _short(String? t) =>
      t == null ? 'Aucun token' : '${t.substring(0, t.length < 12 ? t.length : 12)}…';
}
