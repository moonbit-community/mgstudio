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
except Exception as exc:  # pragma: no cover - runtime dependency check
    print(
        "[sanity] Pillow is required. Install with: python3 -m pip install Pillow",
        file=sys.stderr,
    )
    print(f"[sanity] import error: {exc}", file=sys.stderr)
    sys.exit(4)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sanity-check captured example screenshots (non-empty/non-black)."
    )
    parser.add_argument("--image", required=True, type=Path, help="PNG path")
    parser.add_argument(
        "--report",
        required=False,
        type=Path,
        help="Optional JSON report output path",
    )
    parser.add_argument(
        "--black-threshold",
        required=False,
        type=int,
        default=8,
        help="A pixel is considered non-black if max(R,G,B) > threshold.",
    )
    parser.add_argument(
        "--min-non-black-ratio",
        required=False,
        type=float,
        default=0.01,
        help="Minimum ratio of non-black pixels in full image.",
    )
    parser.add_argument(
        "--min-mean-luma",
        required=False,
        type=float,
        default=4.0,
        help="Minimum mean luma (0..255) in full image.",
    )
    parser.add_argument(
        "--min-center-mean-luma",
        required=False,
        type=float,
        default=3.0,
        help="Minimum mean luma (0..255) in center crop (50%% width x 50%% height).",
    )
    parser.add_argument(
        "--min-center-non-black-ratio",
        required=False,
        type=float,
        default=0.005,
        help="Minimum non-black pixel ratio in center crop.",
    )
    return parser.parse_args()


def mean_luma(rgb_pixels: list[tuple[int, int, int]]) -> float:
    if not rgb_pixels:
        return 0.0
    # ITU-R BT.709 luma coefficients.
    luma_sum = 0.0
    for r, g, b in rgb_pixels:
        luma_sum += 0.2126 * r + 0.7152 * g + 0.0722 * b
    return luma_sum / float(len(rgb_pixels))


def main() -> int:
    args = parse_args()
    if not args.image.is_file():
        print(f"[sanity] image not found: {args.image}", file=sys.stderr)
        return 2

    image = Image.open(args.image).convert("RGB")
    width, height = image.size
    pixels = list(image.getdata())
    total_pixels = len(pixels)
    non_black_pixels = sum(
        1 for (r, g, b) in pixels if max(r, g, b) > args.black_threshold
    )
    non_black_ratio = (
        float(non_black_pixels) / float(total_pixels) if total_pixels > 0 else 0.0
    )
    full_mean_luma = mean_luma(pixels)

    center_w = max(1, width // 2)
    center_h = max(1, height // 2)
    left = (width - center_w) // 2
    top = (height - center_h) // 2
    right = left + center_w
    bottom = top + center_h
    center_pixels = list(image.crop((left, top, right, bottom)).getdata())
    center_mean_luma = mean_luma(center_pixels)
    center_non_black_pixels = sum(
        1 for (r, g, b) in center_pixels if max(r, g, b) > args.black_threshold
    )
    center_total_pixels = len(center_pixels)
    center_non_black_ratio = (
        float(center_non_black_pixels) / float(center_total_pixels)
        if center_total_pixels > 0
        else 0.0
    )

    pass_non_black = non_black_ratio >= args.min_non_black_ratio
    pass_full_luma = full_mean_luma >= args.min_mean_luma
    pass_center_luma = center_mean_luma >= args.min_center_mean_luma
    pass_center_non_black = center_non_black_ratio >= args.min_center_non_black_ratio
    # Dark-background text scenes are valid when center activity is visible.
    pass_dark_scene_override = pass_center_luma and pass_center_non_black
    passed = pass_non_black and (pass_full_luma or pass_dark_scene_override)

    report = {
        "image": str(args.image),
        "size": {"width": width, "height": height},
        "metrics": {
            "black_threshold": args.black_threshold,
            "non_black_pixels": non_black_pixels,
            "total_pixels": total_pixels,
            "non_black_ratio": non_black_ratio,
            "mean_luma": full_mean_luma,
            "center_mean_luma": center_mean_luma,
            "center_non_black_pixels": center_non_black_pixels,
            "center_total_pixels": center_total_pixels,
            "center_non_black_ratio": center_non_black_ratio,
        },
        "thresholds": {
            "min_non_black_ratio": args.min_non_black_ratio,
            "min_mean_luma": args.min_mean_luma,
            "min_center_mean_luma": args.min_center_mean_luma,
            "min_center_non_black_ratio": args.min_center_non_black_ratio,
        },
        "checks": {
            "pass_non_black_ratio": pass_non_black,
            "pass_mean_luma": pass_full_luma,
            "pass_center_mean_luma": pass_center_luma,
            "pass_center_non_black_ratio": pass_center_non_black,
            "pass_dark_scene_override": pass_dark_scene_override,
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
