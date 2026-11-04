import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/auth_exception.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';

/// Résultat d'une tentative de connexion, utilisé par l'écran pour réagir.
enum LoginOutcome { success, invalidCredentials, houston, error }

/// Gestion d'état de l'authentification (ChangeNotifier).
///
/// Centralise : chargement en cours, utilisateur connecté, token de session
/// (stocké de façon sécurisée), compteur d'échecs et dernier message d'erreur.
class AuthController extends ChangeNotifier {
  AuthController({AuthService? authService, TokenStorage? tokenStorage})
      : _authService = authService ?? AuthService(),
        _tokenStorage = tokenStorage ?? SecureTokenStorage();

  final AuthService _authService;
  final TokenStorage _tokenStorage;

  bool _isLoading = false;
  User? _user;
  String? _token;
  int _failedAttempts = 0;
  String? _lastError;
  DateTime? _tokenVerifiedAt;

  bool get isLoading => _isLoading;
  User? get user => _user;
  String? get token => _token;
  int get failedAttempts => _failedAttempts;
  String? get lastError => _lastError;
  bool get isAuthenticated => _user != null;

  /// Date de la dernière vérification réussie du token auprès de l'API.
  DateTime? get tokenVerifiedAt => _tokenVerifiedAt;

  /// Tente une connexion et met à jour l'état.
  Future<LoginOutcome> login(String email, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _user = response.user;
      _token = response.token;
      _tokenVerifiedAt = null;
      _failedAttempts = 0; // Remise à zéro après une connexion réussie
      if (_token != null) {
        await _tokenStorage.write(_token!); // Stockage sécurisé du token
      }
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

  /// Au démarrage : si un token est stocké et toujours valide côté serveur,
  /// l'utilisateur est reconnecté automatiquement. Retourne true si c'est le cas.
  Future<bool> restoreSession() async {
    try {
      final stored = await _tokenStorage.read();
      if (stored == null) return false;
      _user = await _authService.fetchProfile(stored);
      _token = stored;
      _tokenVerifiedAt = DateTime.now();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      if (e.type == AuthErrorType.unauthorized) {
        await _tokenStorage.delete(); // token expiré ou invalide
      }
      return false;
    } catch (_) {
      return false; // stockage indisponible : on affiche simplement le login
    }
  }

  /// Requête sécurisée : vérifie le token auprès de l'API (GET /profile.php)
  /// et rafraîchit les données de l'utilisateur.
  Future<bool> verifySession() async {
    final current = _token;
    if (current == null) return false;
    try {
      _user = await _authService.fetchProfile(current);
      _tokenVerifiedAt = DateTime.now();
      _lastError = null;
      return true;
    } on AuthException catch (e) {
      _lastError = e.message;
      _tokenVerifiedAt = null;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Déconnexion : on oublie l'utilisateur et on supprime le token stocké.
  Future<void> logout() async {
    _user = null;
    _token = null;
    _tokenVerifiedAt = null;
    notifyListeners();
    try {
      await _tokenStorage.delete();
    } catch (_) {
      // Rien à faire si le stockage est indisponible
    }
  }
}
