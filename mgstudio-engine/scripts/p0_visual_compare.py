#!/usr/bin/env python3
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

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    from PIL import Image
    from PIL import ImageChops
    from PIL import ImageStat
except Exception as exc:  # pragma: no cover - runtime dependency check
    print(
        "[compare] Pillow is required. Install with: python3 -m pip install Pillow",
        file=sys.stderr,
    )
    print(f"[compare] import error: {exc}", file=sys.stderr)
    sys.exit(4)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Compare two PNG images for parity gates.")
    parser.add_argument("--baseline", required=True, type=Path, help="Baseline PNG path")
    parser.add_argument("--actual", required=True, type=Path, help="Actual PNG path")
    parser.add_argument(
        "--report",
        required=False,
        type=Path,
        help="Optional JSON report output path",
    )
    parser.add_argument(
        "--pixel-delta-threshold",
        required=False,
        type=int,
        default=10,
        help="Per-pixel max channel diff threshold (0..255) for changed-pixel counting",
    )
    parser.add_argument(
        "--max-mean-abs",
        required=False,
        type=float,
        default=6.0,
        help="Maximum allowed mean absolute difference over RGB channels",
    )
    parser.add_argument(
        "--max-changed-ratio",
        required=False,
        type=float,
        default=0.08,
        help="Maximum allowed changed-pixel ratio (0..1)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if not args.baseline.is_file():
        print(f"[compare] baseline not found: {args.baseline}", file=sys.stderr)
        return 2
    if not args.actual.is_file():
        print(f"[compare] actual image not found: {args.actual}", file=sys.stderr)
        return 2

    baseline = Image.open(args.baseline).convert("RGB")
    actual = Image.open(args.actual).convert("RGB")
    if actual.size != baseline.size:
        actual = actual.resize(baseline.size, resample=Image.Resampling.BILINEAR)

    diff = ImageChops.difference(baseline, actual)
    stat = ImageStat.Stat(diff)
    mean_abs = sum(stat.mean) / float(len(stat.mean))
    max_abs = max(stat.extrema[0][1], stat.extrema[1][1], stat.extrema[2][1])

    changed = 0
    total = baseline.size[0] * baseline.size[1]
    for r, g, b in diff.getdata():
        if max(r, g, b) > args.pixel_delta_threshold:
            changed += 1
    changed_ratio = changed / float(total)

    pass_mean = mean_abs <= args.max_mean_abs
    pass_ratio = changed_ratio <= args.max_changed_ratio
    passed = pass_mean and pass_ratio

    report = {
        "baseline": str(args.baseline),
        "actual": str(args.actual),
        "size": {"width": baseline.size[0], "height": baseline.size[1]},
        "metrics": {
            "mean_abs_rgb": mean_abs,
            "max_abs_rgb": max_abs,
            "changed_ratio": changed_ratio,
            "changed_pixels": changed,
            "total_pixels": total,
            "pixel_delta_threshold": args.pixel_delta_threshold,
        },
        "thresholds": {
            "max_mean_abs": args.max_mean_abs,
            "max_changed_ratio": args.max_changed_ratio,
        },
        "passed": passed,
    }

    if args.report is not None:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    print(json.dumps(report, indent=2))
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
