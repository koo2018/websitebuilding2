<?php
define('WSB2_APP', true);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/data.php';

wsb2_require_login();

$flash = $_SESSION['flash'] ?? null;
unset($_SESSION['flash']);

$csrf   = wsb2_csrf_token();
$domain = WSB2_DOMAIN;

// Build data for rendering
$groups_data = [];
foreach (wsb2_get_groups() as $g) {
    $students = [];
    foreach (wsb2_get_students($g) as $s) {
        $students[] = ['name' => $s, 'on' => wsb2_site_enabled($s)];
    }
    $groups_data[] = ['name' => $g, 'students' => $students];
}

function h(string $s): string {
    return htmlspecialchars($s, ENT_QUOTES, 'UTF-8');
}
?>
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>WSB2 — Управление сайтами</title>
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{font:14px/1.5 system-ui,sans-serif;background:#f0f2f5;color:#1a1a2e}

/* topbar */
.topbar{background:#1a1a2e;color:#fff;display:flex;align-items:center;
        justify-content:space-between;padding:0 24px;height:52px;
        position:sticky;top:0;z-index:10}
.topbar-left{display:flex;align-items:center;gap:12px}
.topbar h1{font-size:15px;font-weight:600;letter-spacing:.3px}
.topbar .domain{font-size:11px;color:#9ba3c2}
.btn-logout{background:transparent;color:#9ba3c2;border:1px solid #3a3d5c;
            padding:5px 14px;border-radius:5px;cursor:pointer;font-size:12px}
.btn-logout:hover{color:#fff;border-color:#fff}

/* layout */
.main{max-width:960px;margin:24px auto;padding:0 16px 40px}

/* flash */
.flash{padding:10px 16px;border-radius:7px;margin-bottom:20px;font-size:13px;font-weight:500}
.flash.ok {background:#d4edda;color:#155724;border:1px solid #c3e6cb}
.flash.err{background:#f8d7da;color:#721c24;border:1px solid #f5c6cb}

/* cards */
.card{background:#fff;border-radius:8px;box-shadow:0 1px 4px rgba(0,0,0,.09);
      margin-bottom:20px;overflow:hidden}
.card-head{display:flex;align-items:center;justify-content:space-between;
           padding:12px 18px;background:#f8f9ff;border-bottom:1px solid #e8eaf2}
.card-head h2{font-size:14px;font-weight:600}
.card-head .count{font-weight:400;color:#9ba3c2;font-size:12px;margin-left:6px}
.card-body{padding:14px 18px}

/* table */
table{width:100%;border-collapse:collapse;font-size:13px}
th{text-align:left;padding:6px 10px;color:#666;font-weight:500;
   border-bottom:1px solid #e8eaf2;white-space:nowrap}
td{padding:9px 10px;border-bottom:1px solid #f0f2f5;vertical-align:middle}
tr:last-child td{border-bottom:none}
.site-url{font-size:11px;color:#9ba3c2;text-decoration:none}
.site-url:hover{color:#4f6ef7}

/* badges */
.badge{display:inline-block;padding:2px 9px;border-radius:20px;font-size:11px;font-weight:600}
.badge.on {background:#d4edda;color:#155724}
.badge.off{background:#f8d7da;color:#721c24}

/* buttons */
.btn{display:inline-block;padding:5px 13px;border-radius:5px;font-size:12px;
     font-weight:500;border:none;cursor:pointer;white-space:nowrap}
.btn-sm{padding:3px 10px;font-size:11px}
.btn-primary{background:#4f6ef7;color:#fff}
.btn-primary:hover{background:#3a5ae8}
.btn-success{background:#28a745;color:#fff}
.btn-success:hover{background:#218838}
.btn-warning{background:#ffc107;color:#212529}
.btn-warning:hover{background:#e0a800}
.btn-danger{background:#dc3545;color:#fff}
.btn-danger:hover{background:#c82333}

/* add form */
.add-form{display:flex;gap:8px;margin-top:14px;padding-top:14px;
          border-top:1px solid #f0f2f5}
.add-form input[type=text]{flex:1;padding:6px 10px;border:1px solid #d0d3e0;
                            border-radius:5px;font-size:13px}
.add-form input[type=text]:focus{outline:none;border-color:#4f6ef7}

.empty-note{color:#aaa;font-size:13px;padding:4px 0 10px}
.empty-state{text-align:center;color:#aaa;padding:40px;font-size:14px}

/* actions cell: prevent wrapping */
td.actions{white-space:nowrap}
td.actions form{display:inline}
td.actions form+form{margin-left:4px}
</style>
</head>
<body>

<div class="topbar">
  <div class="topbar-left">
    <h1>WSB2 — Управление сайтами</h1>
    <span class="domain"><?= h($domain) ?></span>
  </div>
  <form method="post" action="logout.php">
    <input type="hidden" name="csrf" value="<?= h($csrf) ?>">
    <button class="btn-logout">Выйти</button>
  </form>
</div>

<div class="main">

  <?php if ($flash): ?>
    <div class="flash <?= $flash['ok'] ? 'ok' : 'err' ?>"><?= h($flash['msg']) ?></div>
  <?php endif ?>

  <?php if (!$groups_data): ?>
    <div class="empty-state">Групп пока нет. Создайте первую группу ниже.</div>
  <?php endif ?>

  <?php foreach ($groups_data as $g): ?>
  <div class="card">
    <div class="card-head">
      <h2>
        <?= h($g['name']) ?>
        <span class="count">(<?= count($g['students']) ?> студ.)</span>
      </h2>
      <?php if (!$g['students']): ?>
      <form method="post" action="action.php">
        <input type="hidden" name="csrf"   value="<?= h($csrf) ?>">
        <input type="hidden" name="action" value="del_group">
        <input type="hidden" name="group"  value="<?= h($g['name']) ?>">
        <button class="btn btn-sm btn-danger"
                onclick="return confirm('Удалить группу «<?= h($g['name']) ?>»?')">
          Удалить группу
        </button>
      </form>
      <?php endif ?>
    </div>
    <div class="card-body">

      <?php if ($g['students']): ?>
      <table>
        <thead>
          <tr>
            <th>Студент</th>
            <th>Сайт</th>
            <th>Статус</th>
            <th>Действия</th>
          </tr>
        </thead>
        <tbody>
        <?php foreach ($g['students'] as $s): ?>
          <tr>
            <td><strong><?= h($s['name']) ?></strong></td>
            <td>
              <a class="site-url"
                 href="http://<?= h($s['name']) ?>.<?= h($domain) ?>"
                 target="_blank">
                <?= h($s['name']) ?>.<?= h($domain) ?>
              </a>
            </td>
            <td>
              <span class="badge <?= $s['on'] ? 'on' : 'off' ?>">
                <?= $s['on'] ? 'включён' : 'выключен' ?>
              </span>
            </td>
            <td class="actions">
              <form method="post" action="action.php">
                <input type="hidden" name="csrf"    value="<?= h($csrf) ?>">
                <input type="hidden" name="action"  value="toggle_site">
                <input type="hidden" name="student" value="<?= h($s['name']) ?>">
                <button class="btn btn-sm <?= $s['on'] ? 'btn-warning' : 'btn-success' ?>">
                  <?= $s['on'] ? 'Выключить' : 'Включить' ?>
                </button>
              </form>
              <form method="post" action="action.php">
                <input type="hidden" name="csrf"    value="<?= h($csrf) ?>">
                <input type="hidden" name="action"  value="del_student">
                <input type="hidden" name="student" value="<?= h($s['name']) ?>">
                <button class="btn btn-sm btn-danger"
                        onclick="return confirm('Удалить «<?= h($s['name']) ?>»?\nОперация необратима — все файлы и база данных будут удалены!')">
                  Удалить
                </button>
              </form>
            </td>
          </tr>
        <?php endforeach ?>
        </tbody>
      </table>
      <?php else: ?>
        <p class="empty-note">В группе нет студентов</p>
      <?php endif ?>

      <form method="post" action="action.php" class="add-form">
        <input type="hidden" name="csrf"   value="<?= h($csrf) ?>">
        <input type="hidden" name="action" value="add_student">
        <input type="hidden" name="group"  value="<?= h($g['name']) ?>">
        <input type="text" name="student"
               placeholder="логин нового студента"
               pattern="[a-z][a-z0-9_\-]*"
               maxlength="32"
               required>
        <button class="btn btn-primary">Добавить студента</button>
      </form>

    </div>
  </div>
  <?php endforeach ?>

  <!-- Add group card -->
  <div class="card">
    <div class="card-head"><h2>Новая группа</h2></div>
    <div class="card-body">
      <form method="post" action="action.php" class="add-form" style="border-top:none;padding-top:0;margin-top:0">
        <input type="hidden" name="csrf"   value="<?= h($csrf) ?>">
        <input type="hidden" name="action" value="add_group">
        <input type="text" name="group"
               placeholder="название группы (латиница, цифры, _ -)"
               pattern="[a-z][a-z0-9_\-]*"
               maxlength="32">
        <button class="btn btn-primary">Создать группу</button>
      </form>
    </div>
  </div>

</div>
</body>
</html>
