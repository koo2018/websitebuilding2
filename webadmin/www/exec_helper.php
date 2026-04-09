<?php
if (!defined('WSB2_APP')) die();

const WSB2_WRAPPER_BIN = '/opt/wsb2-webadmin/bin';

const WSB2_ALLOWED_SCRIPTS = [
    'wa-newstudent.sh',
    'wa-delstudent.sh',
    'wa-offsite.sh',
    'wa-onsite.sh',
    'wa-addgroup.sh',
    'wa-delgroup.sh',
];

/**
 * Run a wrapper script as root via sudo.
 * @param  string   $script  Basename from WSB2_ALLOWED_SCRIPTS
 * @param  string[] $args    Validated arguments
 * @return array{ok: bool, output: string}
 */
function wsb2_exec(string $script, array $args): array {
    if (!in_array($script, WSB2_ALLOWED_SCRIPTS, true)) {
        return ['ok' => false, 'output' => 'Unknown script'];
    }

    foreach ($args as $arg) {
        if (!preg_match('/^[a-z][a-z0-9_-]{1,31}$/', $arg)) {
            return ['ok' => false, 'output' => 'Invalid argument: ' . htmlspecialchars($arg, ENT_QUOTES)];
        }
    }

    // Build command: sudo /opt/wsb2-webadmin/bin/<script> 'arg1' 'arg2'
    $bin = WSB2_WRAPPER_BIN . '/' . basename($script);
    $cmd = 'sudo ' . escapeshellarg($bin);
    foreach ($args as $arg) {
        $cmd .= ' ' . escapeshellarg($arg);
    }

    exec($cmd . ' 2>&1', $out, $code);
    return ['ok' => $code === 0, 'output' => implode("\n", $out)];
}
