# multiple_windows Parity Note

- Bevy source: `bevy/examples/window/multiple_windows.rs`
- mgstudio target: `mgstudio-engine/examples/window/multiple_windows/`
- Status: Blocked (not Exact)
- Tracking: `bd-qrn`, `bd-419`, blocker `bd-4al`

## Current Alignment

- Scene setup, directional light, dual-camera setup, second-window entity spawn, and label spawning follow the Bevy sample structure.
- `MGSTUDIO_SCREENSHOT_EXIT_ON_SAVE=1` terminates the process in multi-window runs.
- Primary black-screen symptom is fixed; captured primary output is now non-black.

## Remaining Blocker (Formal Support)

- Current fix is an interim guard: `render3d` skips cameras targeting non-primary `RenderTarget::Window(...)` while backend is single-surface.
- Exact Bevy parity still needs true multi-window surface/frame routing so secondary-window cameras render to their own window targets.
- Follow-up implementation is tracked by `bd-4al`.

## Validation Commands

- `moon -C mgstudio-engine check --target native examples/window/multiple_windows`
- `MGSTUDIO_SCREENSHOT_PATH=docs/parity/artifacts/window_multiple_windows_probe_fix3.png MGSTUDIO_SCREENSHOT_FRAME=180 MGSTUDIO_SCREENSHOT_EXIT_ON_SAVE=1 moon -C mgstudio-engine run --target native examples/window/multiple_windows`

## Output Location Note

- Runtime screenshot outputs are written under:
  - `mgstudio-engine/tmp/data/<MGSTUDIO_SCREENSHOT_PATH>`
