#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENGINE="$ROOT/mgstudio-engine/runtime_native"

CANONICAL_MODULES=(a11y app asset gpu input time window)
REMOVED_WRAPPERS=(a11y app asset input time window)

status=0

for name in "${CANONICAL_MODULES[@]}"; do
  canonical="$ENGINE/native_$name"
  if [[ ! -d "$canonical" ]]; then
    echo "[missing] canonical package not found: $canonical" >&2
    status=1
    continue
  fi
  canonical_pkg="$canonical/moon.pkg"
  if [[ ! -f "$canonical_pkg" ]]; then
    echo "[missing] canonical moon.pkg not found: $canonical_pkg" >&2
    status=1
    continue
  fi
  if ! grep -q "Canonical native runtime implementation package." "$canonical_pkg"; then
    echo "[marker] missing canonical marker in $canonical_pkg" >&2
    status=1
  fi
done

for name in "${REMOVED_WRAPPERS[@]}"; do
  wrapper="$ENGINE/$name"
  if [[ -d "$wrapper" ]]; then
    echo "[legacy] deprecated wrapper package should not exist anymore: $wrapper" >&2
    status=1
  fi
done

legacy_imports="$(
  rg -n "\"Milky2018/mgstudio/runtime_native/(a11y|app|asset|gpu|input|time|window)\"" \
    "$ROOT/mgstudio-engine" \
    --glob '!runtime_native/**' \
    --glob '!**/pkg.generated.mbti' \
    --glob '!**/--registry' \
    || true
)"
if [[ -n "$legacy_imports" ]]; then
  echo "[imports] deprecated runtime_native/* package paths are still imported outside runtime_native:" >&2
  echo "$legacy_imports" >&2
  status=1
fi

if [[ $status -ne 0 ]]; then
  echo "runtime_native single-source routing check failed" >&2
  exit $status
fi

echo "runtime_native single-source routing is valid (native_* canonical only)"
