import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/auth_exception.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Résultat d'une tentative de connexion, utilisé par l'écran pour réagir.
enum LoginOutcome { success, invalidCredentials, houston, error }

/// Gestion d'état de l'authentification (ChangeNotifier).
///
/// Centralise : chargement en cours, utilisateur connecté, token de session,
/// compteur d'échecs et dernier message d'erreur.
class AuthController extends ChangeNotifier {
  AuthController({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  bool _isLoading = false;
  User? _user;
  String? _token;
  int _failedAttempts = 0;
  String? _lastError;

  bool get isLoading => _isLoading;
  User? get user => _user;
  String? get token => _token;
  int get failedAttempts => _failedAttempts;
  String? get lastError => _lastError;
  bool get isAuthenticated => _user != null;

  /// Tente une connexion et met à jour l'état.
  Future<LoginOutcome> login(String email, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _user = response.user;
      _token = response.token;
      _failedAttempts = 0; // Remise à zéro après une connexion réussie
      return LoginOutcome.success;
    } on AuthException catch (e) {
      _lastError = e.message;
      if (e.type == AuthErrorType.invalidCredentials) {
        _failedAttempts++;
        return _failedAttempts >= ApiConfig.maxFailedAttempts
            ? LoginOutcome.houston
            : LoginOutcome.invalidCredentials;
      }
      return LoginOutcome.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Déconnexion : on oublie l'utilisateur et le token.
  void logout() {
    _user = null;
    _token = null;
    notifyListeners();
  }
}
