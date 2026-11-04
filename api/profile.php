<?php
/**
 * GET /profile.php – Route protégée par token
 *
 * En-têtes requis :
 *   X-Flutter-Student: M2-2026
 *   Authorization: Bearer <token reçu lors du login>
 *
 * Succès : {"status":200,"message":"Success","id":…,"firstName":…, …}
 * Token absent/invalide/expiré : {"status":401,"message":"Unauthorized"}
 */

require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/users.php';

requireMethod('GET');
requireStudentHeader();

$token = bearerToken();
$userId = $token !== null ? verifyToken($token) : null;
$user = $userId !== null ? findUserById($userId) : null;

if ($user === null) {
    respond(401, ['status' => 401, 'message' => 'Unauthorized']);
}

respond(200, ['status' => 200, 'message' => 'Success', ...publicUser($user)]);
