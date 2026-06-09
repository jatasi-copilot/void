#!/usr/bin/env zsh
# Full Void build script for macOS (ARM64) and Windows (x64)
set -e

echo "=== Void Full Build ==="

echo "→ Installing dependencies (skip native scripts)..."
npm install --ignore-scripts

echo "→ Building React UI..."
npm run buildreact

echo "→ Compiling TypeScript..."
npm run compile

echo "→ Rebuilding native modules..."
for mod in \
  node_modules/@parcel/watcher \
  node_modules/@vscode/deviceid \
  node_modules/@vscode/policy-watcher \
  node_modules/@vscode/spdlog \
  node_modules/@vscode/sqlite3 \
  node_modules/kerberos \
  node_modules/native-is-elevated \
  node_modules/native-keymap \
  node_modules/native-watchdog \
  node_modules/node-pty; do
  if [ -f "$mod/binding.gyp" ]; then
    echo "  Rebuilding $mod..."
    (cd "$mod" && npx node-gyp rebuild 2>&1 | tail -2)
  fi
done

echo "→ Generating NLS messages..."
node -e "
const path = require('path');
const fs = require('fs');
const outDir = './out';
let messages = {};
function extractNLS(dir) {
  const files = fs.readdirSync(dir, { withFileTypes: true });
  for (const f of files) {
    const fp = path.join(dir, f.name);
    if (f.isDirectory()) { extractNLS(fp); }
    else if (f.name.endsWith('.js')) {
      const content = fs.readFileSync(fp, 'utf8');
      const re = /localize\s*\(\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]*)['\"](?:\s*,\s*['\"]([^'\"]*)['\"])?\s*\)/g;
      let m;
      while ((m = re.exec(content)) !== null) { messages[m[1]] = m[2]; }
    }
  }
}
extractNLS(outDir);
fs.writeFileSync('./out/nls.messages.json', JSON.stringify(messages, null, 2));
console.log('NLS: ' + Object.keys(messages).length + ' keys written');
"

echo "=== Build complete. Launch with: npx electron ./out/main.js ==="
