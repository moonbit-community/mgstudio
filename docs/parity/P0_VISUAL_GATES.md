# P0 Visual Gates for 3D Blockers

This document defines the executable visual parity gate for the two blocker examples:

- `examples/3d/3d_scene` (must show visible shadows)
- `examples/3d/3d_shapes` (near-camera face must render correctly)

The gate is implemented with scripts under:

- `/Users/zhengyu/Documents/projects/moon-game-studio/mgstudio-engine/scripts/p0_visual_gate.sh`
- `/Users/zhengyu/Documents/projects/moon-game-studio/mgstudio-engine/scripts/p0_visual_capture_native.sh`
- `/Users/zhengyu/Documents/projects/moon-game-studio/mgstudio-engine/scripts/p0_visual_compare.py`

## Baseline Convention

Expected baseline files:

- `docs/parity/baselines/bevy_p0_blockers/3d_scene.png`
- `docs/parity/baselines/bevy_p0_blockers/3d_shapes.png`

These images should be captured from Bevy with fixed camera state and stable window size.

## Gate Command

```bash
./mgstudio-engine/scripts/p0_visual_gate.sh
```

Environment knobs:

- `MGSTUDIO_PARITY_BASELINE_DIR`: baseline image directory
- `MGSTUDIO_PARITY_ARTIFACT_DIR`: output artifact directory
- `MGSTUDIO_PARITY_SETTLE_SECONDS`: seconds to wait before capture (default `4`)
- `MGSTUDIO_PARITY_RUN_TIMEOUT_SECONDS`: process timeout budget (default `12`)
- `MGSTUDIO_PARITY_MAX_MEAN_ABS`: mean absolute RGB diff threshold (default `6.0`)
- `MGSTUDIO_PARITY_MAX_CHANGED_RATIO`: changed-pixel ratio threshold (default `0.08`)
- `MGSTUDIO_PARITY_PIXEL_DELTA`: per-pixel max-channel diff threshold (default `10`)

## Acceptance Thresholds

Default pass criteria per case:

- `mean_abs_rgb <= 6.0`
- `changed_ratio <= 0.08` (8%)

Both conditions must pass.

## Output Artifacts

Each run writes:

- `<artifact_dir>/3d_scene.png`
- `<artifact_dir>/3d_shapes.png`
- `<artifact_dir>/3d_scene.json`
- `<artifact_dir>/3d_shapes.json`
- `<artifact_dir>/summary.md`

## Notes

- Current capture mode is `fullscreen-snapshot` via macOS `screencapture`.
- For CI/headless environments, this gate should be run on a GUI-capable runner or replaced by a renderer-level offscreen capture path.
