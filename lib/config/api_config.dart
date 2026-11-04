/// Configuration de l'API d'authentification.
///
/// L'URL peut être changée sans modifier le code :
///   flutter run --dart-define=API_URL=https://xxx.trycloudflare.com/login.php
///
/// Par défaut : API PHP lancée en local (`php -S 127.0.0.1:8000 -t api`).
/// Sur un émulateur Android, utiliser http://10.0.2.2:8000/login.php.
class ApiConfig {
  ApiConfig._();

  static const String loginUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000/login.php',
  );

  /// En-tête personnalisé obligatoire du DS.
  static const String studentHeaderName = 'X-Flutter-Student';
  static const String studentHeaderValue = 'M2-2026';

  /// Délai maximal d'attente de la réponse.
  static const Duration timeout = Duration(seconds: 10);

  /// Nombre d'échecs avant le message « Houston ».
  static const int maxFailedAttempts = 3;
}
