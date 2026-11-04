<?php
/**
 * "Base de données" des utilisateurs (sans SGBD, comme le script d'origine).
 * Les mots de passe ne sont JAMAIS stockés en clair : uniquement des hash bcrypt.
 * Générer un hash : php -r 'echo password_hash("1234", PASSWORD_BCRYPT), PHP_EOL;'
 */

function users(): array
{
    return [
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
}

function findUserById(int $id): ?array
{
    foreach (users() as $user) {
        if ($user['id'] === $id) {
            return $user;
        }
    }
    return null;
}

/** Données publiques d'un utilisateur (sans le hash). */
function publicUser(array $user): array
{
    return [
        'id' => $user['id'],
        'firstName' => $user['firstName'],
        'lastName' => $user['lastName'],
        'email' => $user['email'],
        'role' => $user['role'],
    ];
}
