<?php
header("Content-Type: application/json; charset=utf-8");

// Liste des utilisateurs (sans base de données)
$users = [
    [
        "id" => 1,
        "firstName" => "Jean",
        "lastName" => "Dupont",
        "email" => "jean@example.com",
        "password" => "1234",
        "role" => 2
    ],
    [
        "id" => 2,
        "firstName" => "Julie",
        "lastName" => "Martin",
        "email" => "julie@example.com",
        "password" => "4321",
        "role" => 1
    ]
];

// Récupération des valeurs envoyées par l'application externe
$email = $_POST["email"] ?? "";
$password = $_POST["password"] ?? "";

// Réponse par défaut : erreur de connexion
$json = [
    "status" => 400,
    "message" => "Error"
];

// Recherche de l'utilisateur
foreach ($users as $user) {
    if ($user["email"] === $email && $user["password"] === $password) {

        // Connexion réussie
        $json = [
            "status" => 200,
            "message" => "Success",
            "id" => $user["id"],
            "firstName" => $user["firstName"],
            "lastName" => $user["lastName"],
            "email" => $user["email"],
            "role" => $user["role"],
            "token" => generateToken()
        ];

        break;
    }
}

// Affichage de la réponse JSON
echo json_encode($json, JSON_UNESCAPED_UNICODE);

// Génération d'un token aléatoire
function generateToken($length = 32) {
    return bin2hex(random_bytes($length));
}
