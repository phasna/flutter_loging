<?php
/**
 * API d'authentification – DS Flutter (Option B)
 *
 * Adaptation du script fourni (login_tst_local.original.php) :
 *  - mots de passe stockés hachés avec bcrypt (password_hash / password_verify)
 *    au lieu d'être en clair ;
 *  - méthode POST obligatoire (405 sinon) ;
 *  - en-tête X-Flutter-Student obligatoire (valeur M2-2026) ;
 *  - validation des entrées (email valide, mot de passe non vide) ;
 *  - codes HTTP cohérents avec le champ "status" du JSON ;
 *  - accepte les paramètres en form-urlencoded ($_POST) ou en JSON ;
 *  - génère un token de session aléatoire en cas de succès.
 *
 * Contrat de réponse :
 *  Succès : {"status":200,"message":"Success","id":1,"firstName":"Jean",
 *            "lastName":"Dupont","email":"jean@example.com","role":2,"token":"..."}
 *  Erreur : {"status":400,"message":"Error"}
 */

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');

const REQUIRED_HEADER_VALUE = 'M2-2026';

/** Envoie une réponse JSON avec le code HTTP correspondant puis termine. */
function respond(int $status, array $payload): void
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit;
}

/** Génère un token aléatoire (64 caractères hexadécimaux). */
function generateToken(int $length = 32): string
{
    return bin2hex(random_bytes($length));
}

// --- 1. Méthode HTTP -------------------------------------------------------
if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    header('Allow: POST');
    respond(405, ['status' => 405, 'message' => 'Method Not Allowed']);
}

// --- 2. En-tête personnalisé obligatoire -----------------------------------
$studentHeader = $_SERVER['HTTP_X_FLUTTER_STUDENT'] ?? '';
if ($studentHeader !== REQUIRED_HEADER_VALUE) {
    respond(403, ['status' => 403, 'message' => 'Forbidden']);
}

// --- 3. Lecture des paramètres (form ou JSON) ------------------------------
$email = $_POST['email'] ?? null;
$password = $_POST['password'] ?? null;

if ($email === null && $password === null) {
    $body = json_decode(file_get_contents('php://input') ?: '', true);
    if (is_array($body)) {
        $email = $body['email'] ?? null;
        $password = $body['password'] ?? null;
    }
}

$email = is_string($email) ? trim($email) : '';
$password = is_string($password) ? $password : '';

// --- 4. Validation des entrées ---------------------------------------------
if ($email === '' || $password === ''
    || strlen($email) > 254 || strlen($password) > 128
    || filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
    respond(400, ['status' => 400, 'message' => 'Error']);
}

// --- 5. Utilisateurs (mots de passe hachés en bcrypt, jamais en clair) -----
// Hashes générés avec : php -r 'echo password_hash("1234", PASSWORD_BCRYPT);'
$users = [
    [
        'id' => 1,
        'firstName' => 'Jean',
        'lastName' => 'Dupont',
        'email' => 'jean@example.com',
        'passwordHash' => '$2y$12$sPP68BGe6FJojr1oABM7t.Ke2m.YhN6onI.ugRNvkBv1jg6q3k7.2', // 1234
        'role' => 2,
    ],
    [
        'id' => 2,
        'firstName' => 'Julie',
        'lastName' => 'Martin',
        'email' => 'julie@example.com',
        'passwordHash' => '$2y$12$.9cBeFe2PtwTYLZ.dzltweAdb4R/EWtQujeogTTCqdTdMWX8OYl8S', // 4321
        'role' => 1,
    ],
];

// --- 6. Vérification des identifiants -------------------------------------
foreach ($users as $user) {
    if (hash_equals($user['email'], strtolower($email))
        && password_verify($password, $user['passwordHash'])) {
        respond(200, [
            'status' => 200,
            'message' => 'Success',
            'id' => $user['id'],
            'firstName' => $user['firstName'],
            'lastName' => $user['lastName'],
            'email' => $user['email'],
            'role' => $user['role'],
            'token' => generateToken(),
        ]);
    }
}

// Message volontairement générique : on ne dit pas si c'est l'email
// ou le mot de passe qui est faux.
respond(400, ['status' => 400, 'message' => 'Error']);
