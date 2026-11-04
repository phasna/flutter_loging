import 'user.dart';

/// Réponse de succès de l'API : l'utilisateur et son token de session.
class LoginResponse {
  final User user;
  final String? token;

  const LoginResponse({required this.user, this.token});
}
