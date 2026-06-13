#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
H5_DIR="$ROOT/ReelMixH5"
OUT_DIR="$ROOT/DIYFormula/Resources/ReelMixH5"

cd "$H5_DIR"

if [ ! -d node_modules ]; then
  npm install
fi

npx vite build

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
cp -R dist/* "$OUT_DIR/"

echo "✅ ReelMixH5 已构建并复制到 $OUT_DIR"
