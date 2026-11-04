import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/auth_exception.dart';
import '../models/login_response.dart';
import '../models/user.dart';

/// Service d'authentification : appels HTTP à l'API REST.
///
/// Le mot de passe est envoyé dans le corps de la requête POST (jamais dans
/// l'URL) : il est protégé par HTTPS pendant le transport, puis vérifié côté
/// serveur avec bcrypt. Il n'est jamais stocké dans l'application.
class AuthService {
  AuthService({http.Client? client, String? loginUrl, String? profileUrl})
      : _client = client ?? http.Client(),
        _loginUrl = Uri.parse(loginUrl ?? ApiConfig.loginUrl),
        _profileUrl = Uri.parse(profileUrl ?? ApiConfig.profileUrl);

  final http.Client _client;
  final Uri _loginUrl;
  final Uri _profileUrl;

  /// En-têtes communs à toutes les requêtes (dont l'en-tête obligatoire).
  Map<String, String> get _baseHeaders => {
        ApiConfig.studentHeaderName: ApiConfig.studentHeaderValue,
        'Accept': 'application/json',
      };

  /// POST /login.php : envoie les identifiants.
  ///
  /// Retourne un [LoginResponse] (utilisateur + token) en cas de succès,
  /// lève une [AuthException] sinon.
  Future<LoginResponse> login(String email, String password) async {
    final response = await _send(() => _client.post(
          _loginUrl,
          headers: _baseHeaders,
          // Encodé en application/x-www-form-urlencoded (lu par $_POST en PHP)
          body: {'email': email.trim(), 'password': password},
        ));
    final data = _decode(response);

    // Le champ "status" du JSON fait foi (certaines API répondent toujours HTTP 200)
    final status = (data['status'] as num?)?.toInt() ?? response.statusCode;
    if (status == 200 && data['message'] == 'Success') {
      return LoginResponse(
        user: User.fromJson(data),
        token: data['token'] as String?,
      );
    }
    if (status == 400) {
      throw const AuthException(
          AuthErrorType.invalidCredentials, 'Email ou mot de passe incorrect.');
    }
    throw AuthException(AuthErrorType.server, 'Erreur du serveur (code $status).');
  }

  /// GET /profile.php : requête sécurisée par le token (Authorization: Bearer).
  ///
  /// Permet de vérifier qu'un token est toujours valide et de récupérer
  /// l'utilisateur correspondant (ex. reconnexion automatique au démarrage).
  Future<User> fetchProfile(String token) async {
    final response = await _send(() => _client.get(
          _profileUrl,
          headers: {..._baseHeaders, 'Authorization': 'Bearer $token'},
        ));
    final data = _decode(response);
    final status = (data['status'] as num?)?.toInt() ?? response.statusCode;
    if (status == 200) {
      return User.fromJson(data);
    }
    if (status == 401) {
      throw const AuthException(
          AuthErrorType.unauthorized, 'Session expirée, reconnectez-vous.');
    }
    throw AuthException(AuthErrorType.server, 'Erreur du serveur (code $status).');
  }

  /// Exécute la requête avec un délai maximal et traduit les erreurs réseau.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const AuthException(AuthErrorType.network, 'Le serveur ne répond pas.');
    } on http.ClientException {
      // Pas de réseau, DNS, connexion refusée... (SocketException encapsulée)
      throw const AuthException(
          AuthErrorType.network, 'Impossible de joindre le serveur.');
    }
  }

  /// Décode le corps JSON de la réponse.
  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // traité ci-dessous
    }
    throw AuthException(AuthErrorType.server,
        'Réponse invalide du serveur (HTTP ${response.statusCode}).');
  }
}
