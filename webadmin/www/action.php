<?php
define('WSB2_APP', true);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/exec_helper.php';
require_once __DIR__ . '/data.php';

wsb2_require_login();

// Student creation copies WordPress and creates a DB — can take over 30s.
set_time_limit(300);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: dashboard.php');
    exit;
}

wsb2_csrf_verify();

$act = $_POST['action'] ?? '';
$ok  = false;
$msg = 'Неизвестное действие';

switch ($act) {

    case 'add_group':
        $g = strtolower(trim($_POST['group'] ?? ''));
        $r = wsb2_exec('wa-addgroup.sh', [$g]);
        $ok  = $r['ok'];
        $msg = $ok ? "Группа «$g» создана" : $r['output'];
        break;

    case 'del_group':
        $g = strtolower(trim($_POST['group'] ?? ''));
        // Server-side safety check: refuse if group still has students
        if (wsb2_get_students($g)) {
            $ok = false; $msg = "Группа «$g» не пуста — сначала удалите всех студентов";
            break;
        }
        $r = wsb2_exec('wa-delgroup.sh', [$g]);
        $ok  = $r['ok'];
        $msg = $ok ? "Группа «$g» удалена" : $r['output'];
        break;

    case 'add_student':
        $g = strtolower(trim($_POST['group']   ?? ''));
        $s = strtolower(trim($_POST['student'] ?? ''));
        $r = wsb2_exec('wa-newstudent.sh', [$g, $s]);
        $ok  = $r['ok'];
        $msg = $ok ? "Студент «$s» добавлен в группу «$g»" : $r['output'];
        break;

    case 'del_student':
        $s = strtolower(trim($_POST['student'] ?? ''));
        $r = wsb2_exec('wa-delstudent.sh', [$s]);
        $ok  = $r['ok'];
        $msg = $ok ? "Студент «$s» удалён" : $r['output'];
        break;

    case 'toggle_site':
        $s  = strtolower(trim($_POST['student'] ?? ''));
        $on = wsb2_site_enabled($s);
        $r  = wsb2_exec($on ? 'wa-offsite.sh' : 'wa-onsite.sh', [$s]);
        $ok  = $r['ok'];
        $msg = $ok
            ? ('Сайт «' . $s . '» ' . ($on ? 'выключен' : 'включён'))
            : $r['output'];
        break;
}

$_SESSION['flash'] = ['ok' => $ok, 'msg' => $msg];
header('Location: dashboard.php');
exit;
