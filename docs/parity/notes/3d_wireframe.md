# wireframe Parity Note

- Bevy source: `bevy/examples/3d/wireframe.rs`
- mgstudio target: `mgstudio-engine/examples/3d/wireframe/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-render`

## Behavioral Comparison

- Scene composition and controls follow Bevy intent:
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

## Known Differences

- Baseline parity: Bevy uses runtime wireframe pipeline (`WireframePlugin` and polygon line mode).
- mgstudio currently has no public wireframe pipeline surface in this path.
- This port emulates wireframe with thin unlit cuboid segments.
- Baseline parity: Bevy text UI overlay is not included in this port.

## Runtime Constraints

- WASM/Web: depends on browser WebGPU availability.
- Native runtimes: depends on backend GPU capabilities.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/3d/wireframe`
- Check command: `moon -C mgstudio-engine check`

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.11.56`
