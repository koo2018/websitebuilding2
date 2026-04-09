<?php
define('WSB2_APP', true);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    wsb2_csrf_verify();
}

session_destroy();
header('Location: index.php');
exit;
