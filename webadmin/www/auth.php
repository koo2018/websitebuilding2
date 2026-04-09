<?php
if (!defined('WSB2_APP')) die();

session_set_cookie_params([
    'lifetime' => 0,
    'path'     => '/sitemanagement/',
    'httponly' => true,
    'samesite' => 'Strict',
]);
session_name(WSB2_SESSION_NAME);
session_start();

function wsb2_is_logged_in(): bool {
    return !empty($_SESSION['wsb2_auth']);
}

function wsb2_require_login(): void {
    if (!wsb2_is_logged_in()) {
        header('Location: index.php');
        exit;
    }
}

function wsb2_csrf_token(): string {
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf'];
}

function wsb2_csrf_verify(): void {
    $token = $_POST['csrf'] ?? '';
    if (!hash_equals($_SESSION['csrf'] ?? '', $token)) {
        http_response_code(403);
        die('CSRF verification failed');
    }
}
