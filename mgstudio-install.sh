#!/usr/bin/env bash
# Copyright 2025 International Digital Economy Academy
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

usage() {
  cat <<'EOF'
mgstudio-install.sh

Install mgstudio SDK + CLI from GitHub Releases.

Default behavior installs the latest release for darwin-arm64 into:
  $HOME/.local/share/mgstudio/current
and links the `mgstudio` command into:
  $XDG_BIN_HOME (default) or ~/.local/bin

Usage:
  mgstudio-install.sh [--version <v>] [--sdkroot <dir>] [--bin-dir <dir>] [--verbose] [--dry-run]

Options:
  --version <v>    Install a specific version (e.g. 0.1.1). Default: latest
  --sdkroot <dir>  Install destination SDK root (default: $HOME/.local/share/mgstudio/current)
  --bin-dir <dir>  Where to install the `mgstudio` symlink (default: $XDG_BIN_HOME, else ~/.local/bin)
  --verbose        Print progress information
  --dry-run        Print actions without modifying the filesystem
  -h, --help       Show this help

Examples:
  curl -fsSL https://github.com/moonbit-community/mgstudio/releases/latest/download/mgstudio-install.sh | bash
  curl -fsSL https://github.com/moonbit-community/mgstudio/releases/download/v0.1.1/mgstudio-install.sh | bash -s -- --version 0.1.1
EOF
}

VERSION="latest"
SDKROOT="${HOME}/.local/share/mgstudio/current"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
DRY_RUN=0
VERBOSE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    --sdkroot)
      SDKROOT="${2:-}"
      shift 2
      ;;
    --bin-dir)
      BIN_DIR="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --verbose)
      VERBOSE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${VERSION}" ]]; then
  echo "Missing value for --version" >&2
  exit 2
fi
if [[ -z "${SDKROOT}" ]]; then
  echo "Missing value for --sdkroot" >&2
  exit 2
fi
if [[ -z "${BIN_DIR}" ]]; then
  echo "Missing value for --bin-dir" >&2
  exit 2
fi

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
if [[ "${ARCH}" == "aarch64" ]]; then
  ARCH="arm64"
fi

if [[ "${OS}" != "darwin" || "${ARCH}" != "arm64" ]]; then
  echo "Unsupported platform: ${OS}-${ARCH}" >&2
  echo "Current installer supports: darwin-arm64" >&2
  exit 2
fi

SDK_TARBALL=""
SDK_SHA256SUMS="SHA256SUMS"
SDK_PLATFORM="darwin-arm64"

if [[ "${VERSION}" == "latest" ]]; then
  BASE_URL="https://github.com/moonbit-community/mgstudio/releases/latest/download"
else
  SDK_TARBALL="mgstudio-sdk-${VERSION}-${SDK_PLATFORM}.tar.gz"
  BASE_URL="https://github.com/moonbit-community/mgstudio/releases/download/v${VERSION}"
fi

SUMS_URL="${BASE_URL}/${SDK_SHA256SUMS}"

log_step() {
  if [[ "${VERBOSE}" -eq 1 ]]; then
    echo "$@"
  fi
}

if [[ "${DRY_RUN}" -eq 1 ]]; then
  if [[ "${VERSION}" == "latest" ]]; then
    echo "Dry run."
    echo "  Version:  latest (${SDK_PLATFORM})"
    echo "  SDK root: ${SDKROOT}"
    echo "  CLI:      ${BIN_DIR}/mgstudio"
    echo "  Note: resolving the exact SDK tarball for 'latest' requires downloading ${SUMS_URL}."
    echo "        Use --version <v> for a deterministic dry run."
    exit 0
  fi

  SDK_URL="${BASE_URL}/${SDK_TARBALL}"
  echo "Dry run."
  echo "  Version:  ${VERSION} (${SDK_PLATFORM})"
  echo "  SDK root: ${SDKROOT}"
  echo "  CLI:      ${BIN_DIR}/mgstudio"
  echo "  Would download: ${SDK_URL}"
  echo "  Would download: ${SUMS_URL}"
  exit 0
fi

run() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "+ $*"
  else
    "$@"
  fi
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 2
  fi
}

sha256_file() {
  local file="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
    return 0
  fi
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
    return 0
  fi
  echo "No sha256 tool found (need shasum or sha256sum)" >&2
  exit 2
}

fetch() {
  local url="$1"
  local out="$2"
  require_cmd curl
  run curl -fsSL --proto '=https' --tlsv1.2 -o "$out" "$url"
}

BASE_DIR="$(dirname -- "${SDKROOT}")"
INSTALL_TMP="${BASE_DIR}/.tmp.mgstudio-install.$$"

cleanup() {
  if [[ "${DRY_RUN}" -eq 0 ]]; then
    rm -rf "${INSTALL_TMP}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

run mkdir -p "${BASE_DIR}"
run rm -rf "${INSTALL_TMP}"
run mkdir -p "${INSTALL_TMP}"

TARBALL_PATH="${INSTALL_TMP}/${SDK_TARBALL}"
SUMS_PATH="${INSTALL_TMP}/${SDK_SHA256SUMS}"

log_step "Downloading release assets..."
fetch "${SUMS_URL}" "${SUMS_PATH}"

if [[ "${VERSION}" == "latest" ]]; then
  SDK_TARBALL="$(
    awk -v plat="${SDK_PLATFORM}" '
      {
        f=$2
        sub(/^\*/, "", f)
        sub(/^\.\//, "", f)
        if (f ~ ("^mgstudio-sdk-.*-" plat "\\.tar\\.gz$")) { print f; exit 0 }
      }
    ' "${SUMS_PATH}"
  )"
  if [[ -z "${SDK_TARBALL}" ]]; then
    echo "SHA256SUMS does not contain an SDK tarball entry for: ${SDK_PLATFORM}" >&2
    echo "Fetched: ${SUMS_URL}" >&2
    exit 1
  fi
  TARBALL_PATH="${INSTALL_TMP}/${SDK_TARBALL}"
fi

SDK_URL="${BASE_URL}/${SDK_TARBALL}"
log_step "Downloading SDK tarball..."
fetch "${SDK_URL}" "${TARBALL_PATH}"

log_step "Verifying SHA256..."
EXPECTED="$(
  awk -v target="${SDK_TARBALL}" '
    {
      f=$2
      sub(/^\*/, "", f)
      sub(/^\.\//, "", f)
      if (f == target) { print $1; exit 0 }
    }
  ' "${SUMS_PATH}"
)"
if [[ -z "${EXPECTED}" ]]; then
  echo "SHA256SUMS does not contain an entry for: ${SDK_TARBALL}" >&2
  echo "Fetched: ${SUMS_URL}" >&2
  exit 1
fi
ACTUAL="$(sha256_file "${TARBALL_PATH}")"
if [[ "${EXPECTED}" != "${ACTUAL}" ]]; then
  echo "SHA256 mismatch for ${SDK_TARBALL}" >&2
  echo "  expected: ${EXPECTED}" >&2
  echo "  actual:   ${ACTUAL}" >&2
  exit 1
fi

log_step "Unpacking..."
require_cmd tar
UNPACK_DIR="${INSTALL_TMP}/unpack"
run mkdir -p "${UNPACK_DIR}"
run tar -xzf "${TARBALL_PATH}" -C "${UNPACK_DIR}"

# Expect the tarball to contain a single top-level directory.
SDK_DIR="$(find "${UNPACK_DIR}" -mindepth 1 -maxdepth 1 -type d | head -n 1 || true)"
if [[ -z "${SDK_DIR}" ]]; then
  echo "Invalid SDK archive (no top-level directory found): ${SDK_TARBALL}" >&2
  exit 2
fi

if [[ ! -x "${SDK_DIR}/bin/mgstudio" ]]; then
  echo "Invalid SDK (missing executable): ${SDK_DIR}/bin/mgstudio" >&2
  exit 2
fi
if [[ ! -d "${SDK_DIR}/share/mgstudio/assets" ]]; then
  echo "Invalid SDK (missing assets): ${SDK_DIR}/share/mgstudio/assets" >&2
  exit 2
fi
if [[ ! -f "${SDK_DIR}/share/mgstudio/web/mgstudio-runtime-web.js" ]]; then
  echo "Invalid SDK (missing web runtime): ${SDK_DIR}/share/mgstudio/web/mgstudio-runtime-web.js" >&2
  exit 2
fi
if [[ ! -f "${SDK_DIR}/lib/libwgpu_native.dylib" ]]; then
  echo "Invalid SDK (missing libwgpu_native): ${SDK_DIR}/lib/libwgpu_native.dylib" >&2
  exit 2
fi
if [[ -f "${SDK_DIR}/bin/mgstudio-runtime-native-wasmtime" ]] &&
  [[ ! -x "${SDK_DIR}/bin/mgstudio-runtime-native-wasmtime" ]]; then
  echo "Invalid SDK (wasmtime runtime is not executable): ${SDK_DIR}/bin/mgstudio-runtime-native-wasmtime" >&2
  exit 2
fi

log_step "Installing (atomic swap)..."
STAGE_DIR="${BASE_DIR}/.tmp.mgstudio-sdk.stage.$$"
run rm -rf "${STAGE_DIR}"
run cp -R "${SDK_DIR}/." "${STAGE_DIR}/"
run rm -rf "${SDKROOT}"
run mv "${STAGE_DIR}" "${SDKROOT}"

log_step "Linking CLI..."
run mkdir -p "${BIN_DIR}"
run ln -sfn "${SDKROOT}/bin/mgstudio" "${BIN_DIR}/mgstudio"

RESOLVED_VERSION="${VERSION}"
if [[ "${RESOLVED_VERSION}" == "latest" ]]; then
  # Parse `mgstudio-sdk-<version>-darwin-arm64.tar.gz`
  RESOLVED_VERSION="$(
    echo "${SDK_TARBALL}" | sed -E 's/^mgstudio-sdk-([0-9]+\.[0-9]+\.[0-9]+)-darwin-arm64\.tar\.gz$/\1/'
  )"
fi

echo "mgstudio installed."
echo "  Version:  ${RESOLVED_VERSION} (${SDK_PLATFORM})"
echo "  SDK root: ${SDKROOT}"
echo "  CLI:      ${BIN_DIR}/mgstudio"
if [[ -x "${SDKROOT}/bin/mgstudio-runtime-native-wasmtime" ]]; then
  echo "  Wasmtime: ${SDKROOT}/bin/mgstudio-runtime-native-wasmtime (ready)"
else
  echo "  Wasmtime: not bundled in this SDK release"
fi
echo "Next: ensure '${BIN_DIR}' is on your PATH."
