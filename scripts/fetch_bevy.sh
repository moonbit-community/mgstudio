#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BEVY_DIR="${ROOT_DIR}/bevy"

BEVY_REPO="https://github.com/bevyengine/bevy.git"
BEVY_COMMIT="48ec375a3a3cdc904476ef1d13f9d71c9f2820d3"
BEVY_DESCRIBE="v0.16.0-rc.4-1998-g48ec375a3"

if [[ -d "${BEVY_DIR}/.git" ]]; then
  echo "bevy/: found existing git repo"
else
  if [[ -e "${BEVY_DIR}" ]]; then
    echo "bevy/: exists but is not a git repo; refusing to overwrite: ${BEVY_DIR}" >&2
    exit 1
  fi
  echo "Cloning ${BEVY_REPO} into ${BEVY_DIR} ..."
  git clone --filter=blob:none --no-checkout "${BEVY_REPO}" "${BEVY_DIR}"
fi

cd "${BEVY_DIR}"

echo "Fetching tags..."
git fetch --tags --force --prune origin
git fetch --force --prune origin

echo "Checking out commit: ${BEVY_COMMIT}"
git checkout -f "${BEVY_COMMIT}"

actual_commit="$(git rev-parse HEAD)"
if [[ "${actual_commit}" != "${BEVY_COMMIT}" ]]; then
  echo "ERROR: Bevy baseline commit mismatch." >&2
  echo "  expected: ${BEVY_COMMIT}" >&2
  echo "  actual:   ${actual_commit}" >&2
  exit 1
fi

actual_describe="$(git describe --tags --always || true)"
if [[ -n "${actual_describe}" && "${actual_describe}" != "${BEVY_DESCRIBE}" ]]; then
  echo "WARNING: baseline describe mismatch (non-fatal)." >&2
  echo "  expected: ${BEVY_DESCRIBE}" >&2
  echo "  actual:   ${actual_describe}" >&2
fi

echo "OK: Bevy baseline is ready at ${actual_commit} (${actual_describe})"
