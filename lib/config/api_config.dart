/// Configuration de l'API d'authentification.
///
/// L'adresse du serveur peut être changée sans modifier le code :
///   flutter run --dart-define=API_BASE_URL=https://xxx.trycloudflare.com
///
/// Par défaut : API PHP lancée en local
///   php -S 127.0.0.1:8000 -t api api/router.php
/// Sur un émulateur Android, utiliser http://10.0.2.2:8000.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// POST : authentification (email, password).
  static String get loginUrl => '$baseUrl/login.php';

  /// GET : profil, protégé par le token (Authorization: Bearer).
  static String get profileUrl => '$baseUrl/profile.php';

  /// En-tête personnalisé obligatoire du DS.
  static const String studentHeaderName = 'X-Flutter-Student';
  static const String studentHeaderValue = 'M2-2026';

  /// Délai maximal d'attente de la réponse.
  static const Duration timeout = Duration(seconds: 10);

  /// Nombre d'échecs avant le message « Houston ».
  static const int maxFailedAttempts = 3;
}
