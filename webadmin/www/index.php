<?php
define('WSB2_APP', true);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth.php';

if (wsb2_is_logged_in()) {
    header('Location: dashboard.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    wsb2_csrf_verify();

    $now = time();
    if (($_SESSION['fail_count'] ?? 0) >= 5 && ($now - ($_SESSION['fail_time'] ?? 0)) < 60) {
        $error = 'Слишком много неверных попыток. Подождите минуту.';
    } elseif (password_verify($_POST['password'] ?? '', WSB2_PASSWORD_HASH)) {
        session_regenerate_id(true);
        $_SESSION['wsb2_auth'] = true;
        $_SESSION['fail_count'] = 0;
        header('Location: dashboard.php');
        exit;
    } else {
        $_SESSION['fail_count'] = ($_SESSION['fail_count'] ?? 0) + 1;
        $_SESSION['fail_time']  = $now;
        $error = 'Неверный пароль';
    }
}

$csrf = wsb2_csrf_token();
?>
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>WSB2 — Вход</title>
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{font:14px/1.5 system-ui,sans-serif;background:#f0f2f5;display:flex;
     align-items:center;justify-content:center;min-height:100vh}
.box{background:#fff;border-radius:10px;box-shadow:0 4px 24px rgba(0,0,0,.12);
     padding:40px;width:320px}
h1{font-size:22px;text-align:center;margin-bottom:4px;color:#1a1a2e}
.sub{text-align:center;color:#9ba3c2;font-size:12px;margin-bottom:28px}
.err{background:#fdecea;color:#c62828;border-radius:6px;padding:8px 12px;
     font-size:13px;margin-bottom:16px}
label{display:block;font-size:12px;color:#555;margin-bottom:4px}
input[type=password]{width:100%;padding:9px 12px;border:1px solid #d0d3e0;
                     border-radius:6px;font-size:14px;margin-bottom:20px}
input[type=password]:focus{outline:none;border-color:#4f6ef7}
button{width:100%;padding:10px;background:#4f6ef7;color:#fff;border:none;
       border-radius:6px;font-size:14px;font-weight:600;cursor:pointer}
button:hover{background:#3a5ae8}
</style>
</head>
<body>
<div class="box">
  <h1>WSB2</h1>
  <div class="sub">Управление сайтами</div>
  <?php if ($error): ?>
    <div class="err"><?= htmlspecialchars($error, ENT_QUOTES) ?></div>
  <?php endif ?>
  <form method="post">
    <input type="hidden" name="csrf" value="<?= htmlspecialchars($csrf, ENT_QUOTES) ?>">
    <label>Пароль</label>
    <input type="password" name="password" autofocus autocomplete="current-password">
    <button type="submit">Войти</button>
  </form>
</div>
</body>
</html>
