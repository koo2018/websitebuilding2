<?php
define('WSB2_APP', true);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth.php';

http_response_code(wsb2_is_logged_in() ? 200 : 401);
