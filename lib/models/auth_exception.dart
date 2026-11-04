/// Types d'erreurs possibles lors de l'authentification.
enum AuthErrorType {
  /// Email ou mot de passe incorrect (réponse {"status":400}).
  invalidCredentials,

  /// Token absent, invalide ou expiré (réponse {"status":401}).
  unauthorized,

  /// Réponse inattendue du serveur (403, 405, 500, JSON invalide...).
  server,

  /// Pas de réseau, serveur injoignable ou délai dépassé.
  network,
}

/// Exception levée par [AuthService] en cas d'échec de connexion.
class AuthException implements Exception {
  final AuthErrorType type;
  final String message;

  const AuthException(this.type, this.message);

  @override
  String toString() => 'AuthException($type): $message';
}
