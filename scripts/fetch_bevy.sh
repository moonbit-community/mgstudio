#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BEVY_DIR="${ROOT_DIR}/bevy"

BEVY_REPO="https://github.com/bevyengine/bevy.git"
BEVY_TAG="v0.15.3"
BEVY_COMMIT="75f04a743bc3da77d3d1fac9d9322920d56ed05b"

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

echo "Checking out tag: ${BEVY_TAG}"
git checkout -f "${BEVY_TAG}"

actual_commit="$(git rev-parse HEAD)"
if [[ "${actual_commit}" != "${BEVY_COMMIT}" ]]; then
  echo "ERROR: Bevy baseline commit mismatch." >&2
  echo "  expected: ${BEVY_COMMIT}" >&2
  echo "  actual:   ${actual_commit}" >&2
  exit 1
fi

echo "OK: Bevy baseline is ready at ${BEVY_TAG} (${actual_commit})"

