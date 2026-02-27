# wireframe Parity Note

- Bevy source: `bevy/examples/3d/wireframe.rs`
- mgstudio target: `mgstudio-engine/examples/3d/wireframe/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Exact`
- Owner: `team-render`

## Behavioral Comparison

- Scene composition and controls are aligned:
  - red/orange/green cubes plus blue plane.
  - camera at `(-2.0, 2.5, 5.0)` and one point light.
  - keyboard controls:
    - `Z`: toggle global wireframe visibility.
    - `X`: toggle global wireframe color (white/deep pink).
    - `C`: toggle green wireframe color (lime/red).
- Semantics are preserved:
  - red cube has no wireframe,
  - orange cube follows global wireframe toggles,
  - green cube always shows custom wireframe color,
  - plane wireframe color stays black while following global visibility.
- API surfaces are aligned:
  - `Wireframe`, `NoWireframe`, `WireframeColor`, `WireframeConfig`.
  - explicit plugin registration (`wireframe_plugin`) before scene setup.
  - control text overlay updates each frame with current global settings.

## Runtime Constraints

- WASM/Web: depends on browser WebGPU availability.
- Native runtimes: depends on backend GPU capabilities.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/3d/wireframe`
- Check commands:
  - `moon -C mgstudio-engine check`
  - `bash scripts/check_codegen_clean.sh`
  - `python3 scripts/check_host_abi.py`

## Follow-up Tasks

