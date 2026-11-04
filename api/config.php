<?php
/**
 * Configuration commune de l'API.
 *
 * TOKEN_SECRET : clé de signature des tokens (HMAC-SHA256).
 * En production, la définir via une variable d'environnement :
 *   TOKEN_SECRET="une-longue-cle-aleatoire" php -S 127.0.0.1:8000 -t api
 */

const REQUIRED_HEADER_VALUE = 'M2-2026';
const TOKEN_TTL_SECONDS = 3600; // durée de validité d'un token : 1 h

function tokenSecret(): string
{
    $secret = getenv('TOKEN_SECRET');
    // Valeur de développement uniquement (à remplacer en production)
    return ($secret !== false && $secret !== '') ? $secret : 'dev-secret-change-me-ds-flutter-2026';
}
