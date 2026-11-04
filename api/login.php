<?php
/**
 * POST /login.php – Authentification (DS Flutter, option B)
 *
 * Adaptation du script fourni (login_tst_local.original.php) :
 *  - mots de passe hachés avec bcrypt (password_hash / password_verify),
 *    jamais stockés en clair ;
 *  - méthode POST obligatoire (405 sinon) ;
 *  - en-tête X-Flutter-Student: M2-2026 obligatoire (403 sinon) ;
 *  - validation des entrées (email valide, longueurs max) ;
 *  - paramètres acceptés en form-urlencoded ($_POST) ou en JSON ;
 *  - token signé (HMAC-SHA256, expire après 1 h) utilisable sur /profile.php.
 *
 * Succès : {"status":200,"message":"Success","id":1,"firstName":"Jean",
 *           "lastName":"Dupont","email":"jean@example.com","role":2,"token":"…"}
 * Erreur : {"status":400,"message":"Error"}
 */

require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/users.php';

requireMethod('POST');
requireStudentHeader();

// --- Lecture des paramètres (form ou JSON) ---------------------------------
$email = $_POST['email'] ?? null;
$password = $_POST['password'] ?? null;

if ($email === null && $password === null) {
    $body = json_decode(file_get_contents('php://input') ?: '', true);
    if (is_array($body)) {
        $email = $body['email'] ?? null;
        $password = $body['password'] ?? null;
    }
}

$email = is_string($email) ? strtolower(trim($email)) : '';
$password = is_string($password) ? $password : '';

// --- Validation des entrées -----------------------------------------------
if ($email === '' || $password === ''
    || strlen($email) > 254 || strlen($password) > 128
    || filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
    respond(400, ['status' => 400, 'message' => 'Error']);
}

// --- Vérification des identifiants (bcrypt) --------------------------------
foreach (users() as $user) {
    if (hash_equals($user['email'], $email)
        && password_verify($password, $user['passwordHash'])) {
        respond(200, [
            'status' => 200,
            'message' => 'Success',
            ...publicUser($user),
            'token' => createToken($user['id']),
        ]);
    }
}

// Message générique : ne révèle pas si l'email ou le mot de passe est faux.
respond(400, ['status' => 400, 'message' => 'Error']);
