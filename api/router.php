<?php
// Routeur pour le serveur intégré : php -S 127.0.0.1:8000 api/router.php
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
if (in_array($path, ['/login.php', '/profile.php'], true)) {
    return false; // laisse PHP servir le fichier
}
http_response_code(404);
header('Content-Type: application/json; charset=utf-8');
echo json_encode(['status' => 404, 'message' => 'Not Found']);
