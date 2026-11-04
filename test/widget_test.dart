import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:login_app/main.dart';
import 'package:login_app/models/auth_exception.dart';
import 'package:login_app/services/auth_service.dart';
import 'package:login_app/services/token_storage.dart';
import 'package:login_app/state/auth_controller.dart';

/// Faux serveur qui imite l'API PHP (jean@example.com / 1234).
const validToken = 'abcdef1234567890abcdef';

MockClient fakeApi({List<http.Request>? log}) => MockClient((req) async {
      log?.add(req);
      if (req.method == 'GET') {
        final ok = req.headers['Authorization'] == 'Bearer $validToken';
        return http.Response(
          json.encode(ok
              ? {'status': 200, 'message': 'Success', 'id': 1, 'firstName': 'Jean',
                 'lastName': 'Dupont', 'email': 'jean@example.com', 'role': 2}
              : {'status': 401, 'message': 'Unauthorized'}),
          ok ? 200 : 401,
        );
      }
      final ok = req.bodyFields['email'] == 'jean@example.com' &&
          req.bodyFields['password'] == '1234';
      return http.Response(
        json.encode(ok
            ? {
                'status': 200,
                'message': 'Success',
                'id': 1,
                'firstName': 'Jean',
                'lastName': 'Dupont',
                'email': 'jean@example.com',
                'role': 2,
                'token': validToken,
              }
            : {'status': 400, 'message': 'Error'}),
        ok ? 200 : 400,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

AuthService serviceWith(http.Client client) => AuthService(
    client: client,
    loginUrl: 'https://test/login.php',
    profileUrl: 'https://test/profile.php');

AuthController controllerWith(http.Client client, {TokenStorage? storage}) =>
    AuthController(
        authService: serviceWith(client),
        tokenStorage: storage ?? MemoryTokenStorage());

Future<void> fillAndSubmit(WidgetTester t, String email, String pass) async {
  await t.enterText(find.widgetWithText(TextFormField, 'Email'), email);
  await t.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), pass);
  await t.tap(find.text('Se connecter'));
  await t.pumpAndSettle();
}

void main() {
  group('AuthService', () {
    test('envoie POST + en-tête X-Flutter-Student + email/password', () async {
      final log = <http.Request>[];
      final res = await AuthService(client: fakeApi(log: log), loginUrl: 'https://test/login.php')
          .login('jean@example.com', '1234');
      expect(res.user.fullName, 'Jean Dupont');
      expect(res.user.role, 2);
      expect(res.token, isNotNull);
      expect(log.single.method, 'POST');
      expect(log.single.headers['X-Flutter-Student'], 'M2-2026');
      expect(log.single.bodyFields, {'email': 'jean@example.com', 'password': '1234'});
    });

    test('mauvais identifiants -> invalidCredentials', () async {
      expect(
        () => AuthService(client: fakeApi(), loginUrl: 'https://test/login.php').login('jean@example.com', 'xxxx'),
        throwsA(isA<AuthException>().having((e) => e.type, 'type', AuthErrorType.invalidCredentials)),
      );
    });

    test('status 400 dans le JSON même si HTTP 200 (API du prof)', () async {
      final client = MockClient((_) async => http.Response('{"status":400,"message":"Error"}', 200));
      expect(
        () => AuthService(client: client, loginUrl: 'https://test/login.php').login('a@b.fr', 'xxxx'),
        throwsA(isA<AuthException>().having((e) => e.type, 'type', AuthErrorType.invalidCredentials)),
      );
    });

    test('erreur réseau -> network', () async {
      final client = MockClient((_) async => throw http.ClientException('offline'));
      expect(
        () => AuthService(client: client, loginUrl: 'https://test/login.php').login('a@b.fr', 'xxxx'),
        throwsA(isA<AuthException>().having((e) => e.type, 'type', AuthErrorType.network)),
      );
    });

    test('réponse non JSON -> server', () async {
      final client = MockClient((_) async => http.Response('<html>500</html>', 500));
      expect(
        () => AuthService(client: client, loginUrl: 'https://test/login.php').login('a@b.fr', 'xxxx'),
        throwsA(isA<AuthException>().having((e) => e.type, 'type', AuthErrorType.server)),
      );
    });
  });

  group('AuthController – compteur', () {
    test('Houston au 3e échec, remise à zéro après succès', () async {
      final c = controllerWith(fakeApi());
      expect(await c.login('jean@example.com', 'bad1'), LoginOutcome.invalidCredentials);
      expect(await c.login('jean@example.com', 'bad2'), LoginOutcome.invalidCredentials);
      expect(await c.login('jean@example.com', 'bad3'), LoginOutcome.houston);
      expect(c.failedAttempts, 3);
      expect(await c.login('jean@example.com', '1234'), LoginOutcome.success);
      expect(c.failedAttempts, 0);
      expect(c.isAuthenticated, isTrue);
    });

    test('une erreur réseau ne compte pas comme tentative incorrecte', () async {
      final c = controllerWith(MockClient((_) async => throw http.ClientException('x')));
      expect(await c.login('jean@example.com', '1234'), LoginOutcome.error);
      expect(c.failedAttempts, 0);
    });
  });

  group('Token', () {
    test('le token est stocké après login et supprimé au logout', () async {
      final storage = MemoryTokenStorage();
      final c = controllerWith(fakeApi(), storage: storage);
      await c.login('jean@example.com', '1234');
      expect(await storage.read(), validToken);
      await c.logout();
      expect(await storage.read(), isNull);
    });

    test('requête sécurisée : Authorization Bearer + en-tête obligatoire', () async {
      final log = <http.Request>[];
      final user = await serviceWith(fakeApi(log: log)).fetchProfile(validToken);
      expect(user.fullName, 'Jean Dupont');
      expect(log.single.method, 'GET');
      expect(log.single.headers['Authorization'], 'Bearer $validToken');
      expect(log.single.headers['X-Flutter-Student'], 'M2-2026');
    });

    test('restoreSession : reconnexion avec un token valide', () async {
      final storage = MemoryTokenStorage()..write(validToken);
      final c = controllerWith(fakeApi(), storage: storage);
      expect(await c.restoreSession(), isTrue);
      expect(c.user?.firstName, 'Jean');
    });

    test('restoreSession : token invalide supprimé', () async {
      final storage = MemoryTokenStorage()..write('faux-token');
      final c = controllerWith(fakeApi(), storage: storage);
      expect(await c.restoreSession(), isFalse);
      expect(await storage.read(), isNull);
    });
  });

  group('Interface', () {
    testWidgets('validation des champs', (t) async {
      await t.pumpWidget(LoginApp(controller: controllerWith(fakeApi())));
      await t.pumpAndSettle();
      await t.tap(find.text('Se connecter'));
      await t.pumpAndSettle();
      expect(find.text('Veuillez entrer votre email'), findsOneWidget);
      expect(find.text('Veuillez entrer votre mot de passe'), findsOneWidget);
    });

    testWidgets('3 échecs -> « Houston, nous avons un problème ! »', (t) async {
      await t.pumpWidget(LoginApp(controller: controllerWith(fakeApi())));
      await t.pumpAndSettle();
      for (var i = 1; i <= 2; i++) {
        await fillAndSubmit(t, 'jean@example.com', 'faux$i');
        expect(find.textContaining('tentative $i/3'), findsOneWidget);
        await t.tap(find.text('OK'));
        await t.pumpAndSettle();
      }
      await fillAndSubmit(t, 'jean@example.com', 'faux3');
      expect(find.text('Houston, nous avons un problème !'), findsWidgets);
    });

    for (final size in const [Size(320, 568), Size(568, 320), Size(1024, 768)]) {
      testWidgets('design réactif sans débordement : $size', (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(LoginApp(controller: controllerWith(fakeApi())));
        await t.pumpAndSettle();
        await t.tap(find.text('Se connecter'));
        await t.pumpAndSettle(); // messages de validation affichés
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('connexion réussie -> profil -> déconnexion', (t) async {
      await t.pumpWidget(LoginApp(controller: controllerWith(fakeApi())));
      await t.pumpAndSettle();
      await fillAndSubmit(t, 'jean@example.com', '1234');
      expect(find.text('Jean Dupont'), findsOneWidget);
      expect(find.text('Utilisateur (2)'), findsOneWidget);
      expect(find.text('Token vérifié par l\'API'), findsOneWidget);
      await t.ensureVisible(find.text('Se déconnecter'));
      await t.pumpAndSettle();
      await t.tap(find.text('Se déconnecter'));
      await t.pumpAndSettle();
      expect(find.text('Bienvenue'), findsOneWidget);
    });
  });
}
