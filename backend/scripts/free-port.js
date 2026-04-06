const { execSync } = require('child_process');

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function getPidsOnPortWindows(port) {
  try {
    const output = execSync(`netstat -ano -p TCP | findstr :${port}`, {
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'ignore'],
    });

    return output
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && line.includes('LISTENING'))
      .map((line) => {
        const match = line.match(/LISTENING\s+(\d+)\s*$/i);
        return match ? Number(match[1]) : null;
      })
      .filter((pid) => Number.isInteger(pid) && pid > 0 && pid !== process.pid);
  } catch (_) {
    return [];
  }
}

function killPidWindows(pid) {
  try {
    execSync(`taskkill /PID ${pid} /F /T`, {
      stdio: ['pipe', 'pipe', 'ignore'],
    });
    return true;
  } catch (_) {
    return false;
  }
}

async function main() {
  const port = Number(process.argv[2] || 3001);

  if (!Number.isInteger(port) || port <= 0) {
    console.error('[free-port] Invalid port.');
    process.exit(1);
  }

  if (process.platform !== 'win32') {
    // Safe no-op outside Windows for this workspace.
    return;
  }

  const pids = [...new Set(getPidsOnPortWindows(port))];
  if (pids.length === 0) {
    return;
  }

  console.log(`[free-port] Port ${port} in use by PID(s): ${pids.join(', ')}. Stopping...`);

  for (const pid of pids) {
    const killed = killPidWindows(pid);
    if (!killed) {
      console.warn(`[free-port] Unable to stop PID ${pid}.`);
    }
  }

  await sleep(250);

  const remaining = [...new Set(getPidsOnPortWindows(port))];
  if (remaining.length > 0) {
    console.warn(`[free-port] Port ${port} still in use by: ${remaining.join(', ')}.`);
  } else {
    console.log(`[free-port] Port ${port} released.`);
  }
}

main().catch((error) => {
  console.error('[free-port] Unexpected error:', error.message);
  process.exit(1);
});
