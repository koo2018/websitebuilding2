<?php
if (!defined('WSB2_APP')) die();

function wsb2_get_webserver(): string {
    static $ws = null;
    if ($ws !== null) return $ws;
    $src = @file_get_contents(WSB2_TEACHER_BIN . '/wsb2-newstudent.sh') ?: '';
    preg_match('/^webserver="([12])"/m', $src, $m);
    return $ws = ($m[1] ?? '1');
}

/**
 * Returns list of student group names: Unix groups with GID >= 1000
 * that have a matching /home/<group>/ directory.
 */
function wsb2_get_groups(): array {
    $teacher = WSB2_TEACHER;
    $exclude = [$teacher, 'www-data', 'sudo', 'root', 'nogroup', 'staff'];
    $result  = [];

    foreach (@file('/etc/group') ?: [] as $line) {
        $p = explode(':', trim($line));
        if (count($p) < 3) continue;
        $name = $p[0];
        $gid  = (int)$p[2];
        if ($gid < 1000) continue;
        if (in_array($name, $exclude, true)) continue;
        if (!is_dir("/home/$name")) continue;
        $result[] = $name;
    }

    sort($result);
    return $result;
}

/**
 * Returns list of student usernames in the given group.
 * A student is a passwd entry whose primary GID matches the group
 * and whose home is /home/<group>/<student>.
 */
function wsb2_get_students(string $group): array {
    $gid = null;
    foreach (@file('/etc/group') ?: [] as $line) {
        $p = explode(':', trim($line));
        if ($p[0] === $group) { $gid = (int)$p[2]; break; }
    }
    if ($gid === null) return [];

    $prefix = "/home/$group/";
    $result = [];
    foreach (@file('/etc/passwd') ?: [] as $line) {
        $p = explode(':', trim($line));
        if (count($p) < 6) continue;
        if ((int)$p[3] !== $gid) continue;
        if (strpos($p[5], $prefix) !== 0) continue;
        $result[] = $p[0];
    }
    sort($result);
    return $result;
}

/**
 * Returns true if the student's virtual host is currently enabled.
 */
function wsb2_site_enabled(string $student): bool {
    if (wsb2_get_webserver() === '1') {
        return is_link("/etc/nginx/sites-enabled/$student.conf");
    }
    return file_exists("/etc/apache2/sites-enabled/$student.conf");
}
