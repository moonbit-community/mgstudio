# multiple_windows Parity Note

- Bevy source: `bevy/examples/window/multiple_windows.rs`
- mgstudio target: `mgstudio-engine/examples/window/multiple_windows/`
- Status: Blocked (not Exact)
- Tracking: `bd-qrn`, `bd-4al`, blocker `bd-ixf`

## Current Alignment

- Scene setup, directional light, dual-camera setup, and second-window entity spawn follow the Bevy sample structure.
- Formal multi-surface routing is implemented in renderer + window runner:
  - Per-window `surface_id/target_id` binding
  - Per-camera active surface target switching (`target_id < 0`)
  - Multi-window frame begin/end orchestration in runner
- `MGSTUDIO_SCREENSHOT_EXIT_ON_SAVE=1` terminates cleanly in multi-window runs.
- Primary-window surface capture is non-black again.

## Remaining Blocker (Formal Support)

- Secondary-window surface capture (`MGSTUDIO_SCREENSHOT_SURFACE_INDEX=1`) is still fully black under the Bevy-parity secondary camera transform (`Transform::from_xyz(6.0, 0.0, 0.0).looking_at(...)`).
- This indicates remaining parity gap after routing landed; tracked by `bd-ixf` (discovered from `bd-4al`).
- Additional observation: when the secondary camera is moved to `(0, 0, 6)` for probe-only validation, secondary capture becomes non-black, so current gap is tied to the Bevy-angle secondary output path.

## Validation Commands

- `moon -C mgstudio-engine check --target native examples/window/multiple_windows`
- `MGSTUDIO_SCREENSHOT_PATH=docs/parity/artifacts/window_multiple_windows_primary_formal.png MGSTUDIO_SCREENSHOT_FRAME=180 MGSTUDIO_SCREENSHOT_SURFACE_INDEX=0 MGSTUDIO_SCREENSHOT_EXIT_ON_SAVE=1 moon -C mgstudio-engine run --target native examples/window/multiple_windows`
- `MGSTUDIO_SCREENSHOT_PATH=docs/parity/artifacts/window_multiple_windows_secondary_formal.png MGSTUDIO_SCREENSHOT_FRAME=180 MGSTUDIO_SCREENSHOT_SURFACE_INDEX=1 MGSTUDIO_SCREENSHOT_EXIT_ON_SAVE=1 moon -C mgstudio-engine run --target native examples/window/multiple_windows`

## Output Location Note

- Runtime screenshot outputs are written under:
  - `mgstudio-engine/tmp/data/<MGSTUDIO_SCREENSHOT_PATH>`
