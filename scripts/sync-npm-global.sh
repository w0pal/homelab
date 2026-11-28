#!/bin/sh
# Regenerate the pinned npm-global manifest from the live install.
# Package names and versions only. node_modules are never tracked.
set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
NPM_ROOT=${NPM_ROOT:-"$HOME/.npm-global/lib/node_modules"}
NODE=${NODE:-"$HOME/.nix-profile/bin/node"}

if [ ! -x "$NODE" ]; then
  NODE=$(command -v node 2>/dev/null || true)
fi
[ -n "$NODE" ] && [ -d "$NPM_ROOT" ] || exit 0

OUT="$REPO_DIR/configs/npm-global/package.json"
mkdir -p "$(dirname "$OUT")"

"$NODE" - "$NPM_ROOT" > "$OUT.tmp" <<'NODE'
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const deps = {};

function add(dir) {
  const file = path.join(dir, 'package.json');
  if (!fs.existsSync(file)) return;
  try {
    const pkg = JSON.parse(fs.readFileSync(file, 'utf8'));
    if (pkg.name && pkg.version) deps[pkg.name] = pkg.version;
  } catch (_) {}
}

for (const name of fs.readdirSync(root)) {
  const dir = path.join(root, name);
  let stat;
  try { stat = fs.statSync(dir); } catch (_) { continue; }
  if (!stat.isDirectory()) continue;
  if (name.startsWith('@')) {
    for (const sub of fs.readdirSync(dir)) add(path.join(dir, sub));
  } else {
    add(dir);
  }
}

const sorted = Object.fromEntries(Object.entries(deps).sort(([a], [b]) => a.localeCompare(b)));
process.stdout.write(JSON.stringify({ name: 'homelab-npm-global', private: true, dependencies: sorted }, null, 2) + '\n');
NODE

mv "$OUT.tmp" "$OUT"
