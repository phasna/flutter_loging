<?php
/**
 * Fonctions utilitaires : réponses JSON, en-tête obligatoire, tokens signés.
 */

require_once __DIR__ . '/config.php';

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');

/** Envoie une réponse JSON avec le code HTTP correspondant puis termine. */
function respond(int $status, array $payload): void
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit;
}

/** Vérifie la méthode HTTP attendue (405 sinon). */
function requireMethod(string $method): void
{
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== $method) {
        header('Allow: ' . $method);
        respond(405, ['status' => 405, 'message' => 'Method Not Allowed']);
    }
}

/** Vérifie l'en-tête personnalisé obligatoire X-Flutter-Student (403 sinon). */
function requireStudentHeader(): void
{
    if (($_SERVER['HTTP_X_FLUTTER_STUDENT'] ?? '') !== REQUIRED_HEADER_VALUE) {
        respond(403, ['status' => 403, 'message' => 'Forbidden']);
    }
}

function base64UrlEncode(string $data): string
{
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function base64UrlDecode(string $data): string|false
{
    return base64_decode(strtr($data, '-_', '+/'), true);
}

/**
 * Crée un token signé : base64url(payload JSON) . "." . base64url(HMAC-SHA256)
 * Le payload contient l'id utilisateur (sub), la date d'émission et d'expiration,
 * et un identifiant aléatoire (jti) : le token est infalsifiable sans la clé.
 */
function createToken(int $userId): string
{
    $now = time();
    $payload = base64UrlEncode(json_encode([
        'sub' => $userId,
        'iat' => $now,
        'exp' => $now + TOKEN_TTL_SECONDS,
        'jti' => bin2hex(random_bytes(16)),
    ]));
    $signature = base64UrlEncode(hash_hmac('sha256', $payload, tokenSecret(), true));
    return $payload . '.' . $signature;
}

/**
 * Vérifie un token (signature + expiration).
 * Retourne l'id utilisateur, ou null si le token est invalide ou expiré.
 */
function verifyToken(string $token): ?int
{
    $parts = explode('.', $token);
    if (count($parts) !== 2) {
        return null;
    }
    [$payload, $signature] = $parts;
    $expected = base64UrlEncode(hash_hmac('sha256', $payload, tokenSecret(), true));
    if (!hash_equals($expected, $signature)) {
        return null; // signature falsifiée
    }
    $data = json_decode(base64UrlDecode($payload) ?: '', true);
    if (!is_array($data) || !isset($data['sub'], $data['exp']) || $data['exp'] < time()) {
        return null; // contenu invalide ou token expiré
    }
    return (int) $data['sub'];
}

/** Lit le token de l'en-tête "Authorization: Bearer <token>". */
function bearerToken(): ?string
{
    $header = $_SERVER['HTTP_AUTHORIZATION']
        ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
        ?? (function_exists('getallheaders') ? (getallheaders()['Authorization'] ?? '') : '');
    if (preg_match('/^Bearer\s+(\S+)$/i', $header, $m)) {
        return $m[1];
    }
    return null;
}
