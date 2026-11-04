import 'package:flutter/material.dart';

import '../state/auth_controller.dart';
import '../models/user.dart';
import '../widgets/fade_slide_in.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        automaticallyImplyLeading: false,
        // Même couleur que le haut du dégradé de l'en-tête : raccord invisible
        backgroundColor: _ProfileHeader.topColor,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _auth,
        builder: (context, _) {
          final user = _auth.user;
          if (user == null) {
            return const Center(child: Text('Non connecté'));
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                _ProfileHeader(user: user),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        children: [
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 150),
                            child: Card(
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
                          ),
                          const SizedBox(height: 16),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 300),
                            child: _TokenStatusCard(
                              token: _auth.token,
                              verifiedAt: _auth.tokenVerifiedAt,
                              error: _auth.lastError,
                              verifying: _verifying,
                              onVerify: _verify,
                            ),
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// En-tête du profil : dégradé, avatar avec initiales, salutation et rôle.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  static const Color topColor = Color(0xFF4F46E5);

  final User user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = '${user.firstName.isNotEmpty ? user.firstName[0] : ''}'
            '${user.lastName.isNotEmpty ? user.lastName[0] : ''}'
        .toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'app-logo',
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 2),
                ],
                color: Colors.white,
              ),
              child: CircleAvatar(
                radius: 42,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(initials,
                    style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Bonjour ${user.firstName} 👋',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(user.email,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(user.role == 1 ? Icons.star : Icons.person,
                    size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(user.roleLabel,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
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
