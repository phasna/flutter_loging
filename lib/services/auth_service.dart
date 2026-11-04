import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/auth_exception.dart';
import '../models/login_response.dart';
import '../models/user.dart';

/// Service d'authentification : appelle l'API REST de connexion.
///
/// Le mot de passe est envoyé tel quel dans le corps de la requête POST :
/// il est protégé par HTTPS pendant le transport, puis vérifié côté serveur
/// avec bcrypt (`password_verify`). Il n'est jamais stocké dans l'application.
class AuthService {
  AuthService({http.Client? client, String? loginUrl})
      : _client = client ?? http.Client(),
        _loginUrl = Uri.parse(loginUrl ?? ApiConfig.loginUrl);

  final http.Client _client;
  final Uri _loginUrl;

  /// Envoie les identifiants à l'API.
  ///
  /// Retourne un [LoginResponse] si la connexion réussit,
  /// lève une [AuthException] sinon.
  Future<LoginResponse> login(String email, String password) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            _loginUrl,
            headers: {
              ApiConfig.studentHeaderName: ApiConfig.studentHeaderValue,
              'Accept': 'application/json',
            },
            // Encodé en application/x-www-form-urlencoded (lu par $_POST en PHP)
            body: {'email': email.trim(), 'password': password},
          )
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const AuthException(
          AuthErrorType.network, 'Le serveur ne répond pas.');
    } on http.ClientException {
      // Pas de réseau, DNS, connexion refusée... (SocketException encapsulée)
      throw const AuthException(
          AuthErrorType.network, 'Impossible de joindre le serveur.');
    }

    // Décodage du JSON (l'API renvoie toujours un objet JSON)
    final Map<String, dynamic> data;
    try {
      data = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } on FormatException {
      throw AuthException(AuthErrorType.server,
          'Réponse invalide du serveur (HTTP ${response.statusCode}).');
    } on TypeError {
      throw AuthException(AuthErrorType.server,
          'Réponse invalide du serveur (HTTP ${response.statusCode}).');
    }

    // Le champ "status" du JSON fait foi (l'API du prof répond toujours HTTP 200)
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
    throw AuthException(
        AuthErrorType.server, 'Erreur du serveur (code $status).');
  }
}
