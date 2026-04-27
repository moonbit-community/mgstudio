#!/usr/bin/env python3
# Copyright 2026 International Digital Economy Academy
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

import argparse
import bisect
import collections
import csv
import json
import math
import pathlib
import re
import sys


def percentile(values, p):
    if not values:
        return None
    values = sorted(values)
    if len(values) == 1:
        return values[0]
    k = (len(values) - 1) * p / 100.0
    lo = math.floor(k)
    hi = math.ceil(k)
    if lo == hi:
        return values[lo]
    return values[lo] * (hi - k) + values[hi] * (k - lo)


def stats(values):
    if not values:
        return {}
    values = list(values)
    return {
        "avg": sum(values) / len(values),
        "p50": percentile(values, 50),
        "p90": percentile(values, 90),
        "p95": percentile(values, 95),
        "p99": percentile(values, 99),
        "min": min(values),
        "max": max(values),
    }


def fmt(value, digits=3):
    if value is None:
        return "-"
    return f"{value:.{digits}f}"


def read_trace(path):
    with path.open("r", encoding="utf-8") as fp:
        payload = json.load(fp)
    events = payload.get("traceEvents", [])
    if not isinstance(events, list):
        raise ValueError(f"{path} does not contain a traceEvents array")
    return events


def parse_diagnostic_log(path):
    if path is None or not path.exists():
        return {}
    patterns = {
        "fps": re.compile(r"\] fps: .*avg ([0-9.]+)"),
        "frame_time_ms": re.compile(r"\] frame_time: .*avg ([0-9.]+)"),
        "frame_count": re.compile(r"\] frame_count: ([0-9]+)"),
    }
    result = {}
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        for key, pattern in patterns.items():
            match = pattern.search(line)
            if match:
                result[key] = match.group(1)
    return result


def build_frames(stages, startup_frames, spike_ms):
    mains = sorted(
        [e for e in stages if e.get("name") == "Main"],
        key=lambda e: e["ts"],
    )
    frames = []
    for i, main in enumerate(mains[:-1]):
        start = main["ts"]
        end = mains[i + 1]["ts"]
        interval_ms = (end - start) / 1000.0
        max_stage_ms = 0.0
        for stage in stages:
            if start <= stage["ts"] < end:
                max_stage_ms = max(max_stage_ms, stage["dur"] / 1000.0)
        frames.append(
            {
                "index": i,
                "start": start,
                "end": end,
                "interval_ms": interval_ms,
                "main_ms": main["dur"] / 1000.0,
                "max_stage_ms": max_stage_ms,
            }
        )
    steady = [
        f
        for f in frames
        if f["index"] >= startup_frames
        and f["interval_ms"] < spike_ms
        and f["max_stage_ms"] < spike_ms
    ]
    excluded = [
        f
        for f in frames
        if f["index"] < startup_frames
        or f["interval_ms"] >= spike_ms
        or f["max_stage_ms"] >= spike_ms
    ]
    return mains, frames, steady, excluded


def aggregate_events(events, steady_frames):
    starts = [frame["start"] for frame in steady_frames]
    intervals = [(frame["start"], frame["end"]) for frame in steady_frames]

    def frame_index_for_ts(ts):
        index = bisect.bisect_right(starts, ts) - 1
        if index < 0:
            return None
        start, end = intervals[index]
        if start <= ts < end:
            return index
        return None

    categories = ["schedule_stage", "system", "render_queue", "render_pass"]
    duration_by_cat_name = {
        category: collections.defaultdict(float) for category in categories
    }
    count_by_cat_name = {category: collections.Counter() for category in categories}
    duration_by_category = collections.defaultdict(float)
    count_by_category = collections.Counter()

    for event in events:
        if "ts" not in event or "dur" not in event:
            continue
        frame_index = frame_index_for_ts(event["ts"])
        if frame_index is None:
            continue
        category = event.get("cat", "")
        name = event.get("name", "")
        duration_ms = event["dur"] / 1000.0
        duration_by_category[category] += duration_ms
        count_by_category[category] += 1
        if category in duration_by_cat_name:
            duration_by_cat_name[category][name] += duration_ms
            count_by_cat_name[category][name] += 1

    return duration_by_category, count_by_category, duration_by_cat_name, count_by_cat_name


def top_rows(duration_by_name, count_by_name, frame_count, limit):
    rows = []
    if frame_count == 0:
        return rows
    for name, duration_ms in sorted(
        duration_by_name.items(),
        key=lambda item: item[1],
        reverse=True,
    )[:limit]:
        rows.append(
            {
                "name": name,
                "avg_ms_per_frame": duration_ms / frame_count,
                "count_per_frame": count_by_name[name] / frame_count,
            }
        )
    return rows


def write_csv(path, rows):
    with path.open("w", newline="", encoding="utf-8") as fp:
        writer = csv.DictWriter(
            fp,
            fieldnames=["category", "name", "avg_ms_per_frame", "count_per_frame"],
        )
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def markdown_table(headers, rows):
    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join(["---"] * len(headers)) + " |",
    ]
    for row in rows:
        lines.append("| " + " | ".join(row) + " |")
    return lines


def main():
    parser = argparse.ArgumentParser(
        description="Analyze mgstudio timeline trace JSON and emit a frame-time breakdown."
    )
    parser.add_argument("trace", type=pathlib.Path)
    parser.add_argument("--log", type=pathlib.Path)
    parser.add_argument("--out-md", type=pathlib.Path)
    parser.add_argument("--out-csv", type=pathlib.Path)
    parser.add_argument("--startup-frames", type=int, default=10)
    parser.add_argument("--spike-ms", type=float, default=200.0)
    parser.add_argument("--top", type=int, default=30)
    parser.add_argument("--title", default="Timeline Trace Breakdown")
    args = parser.parse_args()

    events = read_trace(args.trace)
    stages = sorted(
        [
            e
            for e in events
            if e.get("cat") == "schedule_stage" and "ts" in e and "dur" in e
        ],
        key=lambda e: e["ts"],
    )
    mains, frames, steady_frames, excluded_frames = build_frames(
        stages, args.startup_frames, args.spike_ms
    )
    if not mains:
        raise SystemExit("trace does not contain any Main schedule_stage events")

    duration_by_category, count_by_category, duration_by_name, count_by_name = (
        aggregate_events(events, steady_frames)
    )
    steady_count = len(steady_frames)
    frametime_stats = stats([f["interval_ms"] for f in steady_frames])
    fps = None
    if frametime_stats.get("avg"):
        fps = 1000.0 / frametime_stats["avg"]

    diagnostic = parse_diagnostic_log(args.log)
    event_categories = collections.Counter(e.get("cat", "") for e in events)
    all_top_rows = []
    for category in ["schedule_stage", "system", "render_queue", "render_pass"]:
        for row in top_rows(
            duration_by_name[category],
            count_by_name[category],
            steady_count,
            args.top,
        ):
            all_top_rows.append(
                {
                    "category": category,
                    "name": row["name"],
                    "avg_ms_per_frame": f"{row['avg_ms_per_frame']:.6f}",
                    "count_per_frame": f"{row['count_per_frame']:.6f}",
                }
            )
    if args.out_csv:
        args.out_csv.parent.mkdir(parents=True, exist_ok=True)
        write_csv(args.out_csv, all_top_rows)

    lines = [
        f"# {args.title}",
        "",
        f"- trace: `{args.trace}`",
    ]
    if args.log:
        lines.append(f"- log: `{args.log}`")
    lines.extend(
        [
            f"- trace_events: `{len(events)}`",
            f"- event_categories: `{dict(event_categories)}`",
            f"- main_frames: `{len(mains)}`",
            f"- steady_frames: `{steady_count}`",
            f"- excluded_frames: `{len(excluded_frames)}`",
            f"- startup_frames_excluded: `{args.startup_frames}`",
            f"- spike_threshold_ms: `{args.spike_ms}`",
            "",
            "## Frame Time",
            "",
        ]
    )
    lines.extend(
        markdown_table(
            ["metric", "value"],
            [
                ["avg_ms", fmt(frametime_stats.get("avg"))],
                ["p50_ms", fmt(frametime_stats.get("p50"))],
                ["p90_ms", fmt(frametime_stats.get("p90"))],
                ["p95_ms", fmt(frametime_stats.get("p95"))],
                ["p99_ms", fmt(frametime_stats.get("p99"))],
                ["min_ms", fmt(frametime_stats.get("min"))],
                ["max_ms", fmt(frametime_stats.get("max"))],
                ["fps_from_interval", fmt(fps)],
                ["diagnostic_fps_avg", diagnostic.get("fps", "-")],
                ["diagnostic_frame_time_avg_ms", diagnostic.get("frame_time_ms", "-")],
                ["diagnostic_frame_count", diagnostic.get("frame_count", "-")],
            ],
        )
    )

    if steady_count:
        lines.extend(["", "## Category Totals", ""])
        category_rows = []
        for category, duration_ms in sorted(
            duration_by_category.items(),
            key=lambda item: item[1],
            reverse=True,
        ):
            category_rows.append(
                [
                    f"`{category}`",
                    fmt(duration_ms / steady_count),
                    fmt(count_by_category[category] / steady_count, 2),
                ]
            )
        lines.extend(markdown_table(["category", "avg_ms/frame", "count/frame"], category_rows))

    for category, title in [
        ("schedule_stage", "Stage Breakdown"),
        ("system", "Top Systems"),
        ("render_queue", "Render Queue"),
        ("render_pass", "Render Pass"),
    ]:
        lines.extend(["", f"## {title}", ""])
        rows = []
        for row in top_rows(
            duration_by_name[category],
            count_by_name[category],
            steady_count,
            args.top,
        ):
            rows.append(
                [
                    f"`{row['name']}`",
                    fmt(row["avg_ms_per_frame"]),
                    fmt(row["count_per_frame"], 2),
                ]
            )
        if rows:
            lines.extend(markdown_table(["name", "avg_ms/frame", "count/frame"], rows))
        else:
            lines.append("_No events._")

    spike_rows = sorted(
        [
            f
            for f in excluded_frames
            if f["index"] >= args.startup_frames
            and (f["interval_ms"] >= args.spike_ms or f["max_stage_ms"] >= args.spike_ms)
        ],
        key=lambda f: f["interval_ms"],
        reverse=True,
    )[:10]
    lines.extend(["", "## Excluded Runtime Spikes", ""])
    if spike_rows:
        lines.extend(
            markdown_table(
                ["frame", "interval_ms", "main_ms", "max_stage_ms"],
                [
                    [
                        str(f["index"]),
                        fmt(f["interval_ms"]),
                        fmt(f["main_ms"]),
                        fmt(f["max_stage_ms"]),
                    ]
                    for f in spike_rows
                ],
            )
        )
    else:
        lines.append("_No runtime spikes excluded._")

    output = "\n".join(lines) + "\n"
    if args.out_md:
        args.out_md.parent.mkdir(parents=True, exist_ok=True)
        args.out_md.write_text(output, encoding="utf-8")
    else:
        sys.stdout.write(output)


if __name__ == "__main__":
    main()
