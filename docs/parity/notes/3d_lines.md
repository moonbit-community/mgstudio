# lines Parity Note

- Bevy source: `bevy/examples/3d/lines.rs`
- mgstudio target: `mgstudio-engine/examples/3d/lines/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Exact`
- Owner: `team-render`

## Behavioral Comparison

- Scene framing and data layout are aligned:
  - one line-list group offset to `(-1.5, 0, 0)`,
  - one line-strip group offset to `(0.5, 0, 0)`,
  - camera at `(-2.0, 2.5, 5.0)` looking at origin.
- Color intent is aligned:
  - left group in green, right group in blue.
- Primitive topology semantics are aligned:
  - line-list mesh is uploaded and drawn with line-list topology.
  - line-strip mesh is uploaded and drawn with line-strip topology.

## Runtime Constraints

- WASM/Web: depends on browser WebGPU availability.
- Native runtimes: depends on backend GPU capabilities.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/3d/lines`
- Check commands:
  - `moon -C mgstudio-engine check`
  - `moon -C mgstudio-runtime/web check`
  - `cargo check -q` (in `mgstudio-runtime/native-wasmtime`)
  - `python3 scripts/check_host_abi.py`

## Follow-up Tasks
