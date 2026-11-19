// homelab-fetch collector.
// Runs real fastfetch against read-only host mounts (/proc, /sys,
// /etc/os-release, /), normalizes the JSON output, and pushes it to the
// portfolio tracker API. No docker socket, no privileges, non-root user.

import { execFile } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { promisify } from 'node:util'

const execFileAsync = promisify(execFile)

const API_URL = (process.env.HOMELAB_API_URL || '').replace(/\/+$/, '')
const TOKEN = process.env.HOMELAB_TRACKER_TOKEN || ''
const INTERVAL_MS = Math.max(1000, Number(process.env.PUSH_INTERVAL_MS) || 10_000)
const IP_OVERRIDE = process.env.HOMELAB_IP || ''
const USER_OVERRIDE = process.env.HOMELAB_USER || ''

const STRUCTURE_CONFIG = '/app/fastfetch.jsonc'

function readHost(path) {
  try {
    return readFileSync(path, 'utf8')
  } catch {
    return ''
  }
}

function getHostname() {
  return readHost('/host/etc/hostname').trim() || 'homelab'
}

function getUser() {
  if (USER_OVERRIDE) return USER_OVERRIDE
  const line = readHost('/host/etc/passwd')
    .split('\n')
    .find((l) => l.split(':')[2] === '1000')
  return line ? line.split(':')[0] : 'user'
}

function hexToIp(hex) {
  return hex
    .match(/../g)
    .map((h) => parseInt(h, 16))
    .reverse()
    .join('.')
}

// Host LAN IP: default-route gateway from the host's route table, then the
// matching /32 LOCAL entry in fib_trie (same /24 as the gateway).
// Note: /proc/net is per-netns, so we read pid 1's net directory — that is
// the host's network namespace, not the container's.
function detectIp() {
  if (IP_OVERRIDE) return IP_OVERRIDE
  try {
    const routes = readHost('/host/proc/1/net/route').trim().split('\n').slice(1)
    const def = routes.map((l) => l.split(/\s+/)).find((c) => c[1] === '00000000')
    const gw = def && def[2] !== '00000000' ? hexToIp(def[2]) : null
    const local = readHost('/host/proc/1/net/fib_trie').split('Local:')[1] || ''
    const ips = [...local.matchAll(/\|-- (\d+\.\d+\.\d+\.\d+)\s*\n\s*\/32 host LOCAL/g)]
      .map((m) => m[1])
      .filter((ip) => !ip.startsWith('127.'))
    if (gw) {
      const prefix = gw.split('.').slice(0, 3).join('.') + '.'
      const match = ips.find((ip) => ip.startsWith(prefix))
      if (match) return match
    }
    return ips[0] || null
  } catch {
    return null
  }
}

async function collect() {
  const { stdout } = await execFileAsync(
    'fastfetch',
    ['--config', STRUCTURE_CONFIG, '--format', 'json'],
    { timeout: 15_000 },
  )
  const mods = JSON.parse(stdout)
  const get = (type) => mods.find((m) => m.type === type)?.result

  const os = get('OS')
  const host = get('Host')
  const kernel = get('Kernel')
  const uptime = get('Uptime')
  const cpu = get('CPU')
  const gpuRaw = get('GPU')
  const gpu = Array.isArray(gpuRaw) ? gpuRaw[0] : gpuRaw
  const mem = get('Memory')
  // fastfetch <= 2.64 returns Swap as a per-device array; newer versions a
  // single object. Sum devices when it's an array.
  const swapRaw = get('Swap')
  const swap = Array.isArray(swapRaw)
    ? swapRaw.reduce(
        (acc, s) => ({ used: acc.used + (s.used || 0), total: acc.total + (s.total || 0) }),
        { used: 0, total: 0 },
      )
    : swapRaw
  const disks = get('Disk') || []
  const disk = disks.find((d) => d.mountpoint === '/host') || disks[0]
  const load = get('Loadavg')

  return {
    v: 1,
    hostname: getHostname(),
    user: getUser(),
    os: os ? `${os.prettyName} ${kernel?.architecture || ''}`.trim() : null,
    host: host?.name || host?.family || null,
    kernel: kernel ? `${kernel.name} ${kernel.release}` : null,
    uptimeMs: uptime?.uptime ?? 0,
    cpu: cpu
      ? {
          model: cpu.cpu,
          cores: cpu.cores?.logical ?? cpu.cores?.physical ?? null,
          maxFreqGHz: cpu.frequency?.max ? cpu.frequency.max / 1000 : null,
        }
      : null,
    gpu: gpu
      ? `${gpu.vendor} ${gpu.name}${gpu.frequency ? ` @ ${(gpu.frequency / 1000).toFixed(2)} GHz` : ''}${gpu.type ? ` [${gpu.type}]` : ''}`
      : null,
    memory: mem ? { used: mem.used, total: mem.total } : null,
    swap: swap?.total ? { used: swap.used, total: swap.total } : null,
    disk: disk ? { used: disk.bytes.used, total: disk.bytes.total, fs: disk.filesystem } : null,
    load: Array.isArray(load) ? load : null,
    ip: detectIp(),
  }
}

async function push(payload) {
  const res = await fetch(API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${TOKEN}`,
    },
    body: JSON.stringify(payload),
    signal: AbortSignal.timeout(10_000),
  })
  if (!res.ok) {
    throw new Error(`HTTP ${res.status}: ${(await res.text()).slice(0, 200)}`)
  }
}

let stopped = false
process.on('SIGTERM', () => {
  stopped = true
})
process.on('SIGINT', () => {
  stopped = true
})

async function loop() {
  if (!API_URL || !TOKEN) {
    console.error('[homelab-fetch] HOMELAB_API_URL and HOMELAB_TRACKER_TOKEN must be set (see .env.example)')
    process.exit(1)
  }
  console.log(`[homelab-fetch] pushing to ${API_URL} every ${INTERVAL_MS}ms`)

  let pushes = 0
  while (!stopped) {
    const started = Date.now()
    try {
      const payload = await collect()
      await push(payload)
      pushes++
      // Log the first push, then once a minute; errors always log.
      if (pushes === 1 || pushes % Math.max(1, Math.round(60_000 / INTERVAL_MS)) === 0) {
        console.log(`[homelab-fetch] pushed #${pushes} (${payload.hostname}, mem ${Math.round((payload.memory.used / payload.memory.total) * 100)}%)`)
      }
    } catch (err) {
      console.error('[homelab-fetch] push failed:', err.message)
    }
    const wait = Math.max(500, INTERVAL_MS - (Date.now() - started))
    await new Promise((r) => setTimeout(r, wait))
  }
  console.log('[homelab-fetch] stopped')
}

loop()
