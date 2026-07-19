#!/usr/bin/env python3
"""Synchronize non-WGSL resource mirrors with the pinned Bevy baseline."""

from __future__ import annotations

import argparse
import hashlib
import shutil
import subprocess
import sys
from pathlib import Path


BEVY_BASELINE_COMMIT = "1413bc4e3632233b8fa610a6cf14b90258556c51"
MANIFEST_PATH = Path("scripts/bevy_asset_mirror.sha256")


def repository_root() -> Path:
    return Path(__file__).resolve().parents[1]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_manifest(root: Path) -> list[tuple[str, Path, Path]]:
    manifest = root / MANIFEST_PATH
    if not manifest.is_file():
        raise RuntimeError(f"missing Bevy asset manifest: {manifest}")

    entries: list[tuple[str, Path, Path]] = []
    for line_number, line in enumerate(manifest.read_text().splitlines(), start=1):
        if not line or line.startswith("#"):
            continue
        fields = line.split("\t")
        if len(fields) != 3:
            raise RuntimeError(f"invalid manifest row {line_number}")
        expected_hash, source, destination = fields
        entries.append((expected_hash, Path(source), Path(destination)))
    return entries


def require_pinned_bevy(root: Path) -> None:
    bevy_root = root / "bevy"
    if not (bevy_root / ".git").exists():
        raise RuntimeError(f"missing Bevy checkout: {bevy_root}")
    result = subprocess.run(
        ["git", "-C", str(bevy_root), "rev-parse", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    )
    actual = result.stdout.strip()
    if actual != BEVY_BASELINE_COMMIT:
        raise RuntimeError(
            f"expected Bevy baseline {BEVY_BASELINE_COMMIT}, got {actual}"
        )


def check_entries(
    root: Path,
    entries: list[tuple[str, Path, Path]],
    check_sources: bool,
) -> int:
    failures: list[str] = []
    for expected_hash, source_relative, destination_relative in entries:
        if check_sources:
            source = root / source_relative
            if not source.is_file():
                failures.append(f"missing source: {source_relative}")
            elif sha256(source) != expected_hash:
                failures.append(f"unexpected source bytes: {source_relative}")

        destination = root / destination_relative
        if not destination.is_file():
            failures.append(f"missing mirror: {destination_relative}")
        elif sha256(destination) != expected_hash:
            failures.append(f"out-of-date mirror: {destination_relative}")

    if failures:
        print("Bevy non-WGSL resource mirror is out of date:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1
    print(f"checked {len(entries)} pinned Bevy non-WGSL resource mirrors")
    return 0


def synchronize(root: Path, entries: list[tuple[str, Path, Path]]) -> int:
    updated = 0
    for expected_hash, source_relative, destination_relative in entries:
        source = root / source_relative
        if not source.is_file() or sha256(source) != expected_hash:
            print(f"invalid pinned source: {source_relative}", file=sys.stderr)
            return 1
        destination = root / destination_relative
        if destination.is_file() and sha256(destination) == expected_hash:
            continue
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
        updated += 1
    print(
        f"synchronized {len(entries)} pinned Bevy non-WGSL resource mirrors "
        f"({updated} updated)"
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Synchronize non-WGSL resources from the pinned Bevy baseline."
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--check",
        action="store_true",
        help="verify sources and mirrors against the pinned Bevy checkout",
    )
    mode.add_argument(
        "--check-manifest",
        action="store_true",
        help="verify mirrors without requiring a Bevy checkout",
    )
    args = parser.parse_args()

    root = repository_root()
    try:
        entries = read_manifest(root)
        if args.check_manifest:
            return check_entries(root, entries, check_sources=False)
        require_pinned_bevy(root)
        if args.check:
            return check_entries(root, entries, check_sources=True)
        return synchronize(root, entries)
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print(error, file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
