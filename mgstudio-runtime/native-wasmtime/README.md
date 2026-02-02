# mgstudio-runtime-native-wasmtime

A reference native runtime for **mgstudio** implemented in Rust (Cargo), using:

- `wasmtime` (Wasm runtime; intended to run `wasm-gc` carts built by MoonBit)
- `wgpu` + `winit` (windowing + GPU)

This runtime is designed to be a side-by-side comparison with the existing
MoonBit/wasmoon native runtime (`mgstudio-runtime/native`).

## Build

```bash
cargo build --release
```

## Run (direct)

The mgstudio CLI will eventually spawn this runtime when `--backend wasmtime`
is selected. During bring-up you can run it directly:

```bash
./target/release/mgstudio-runtime-native-wasmtime \
  --cart /abs/path/to/game.wasm \
  --assets dir:/abs/path/to/assets \
  --data dir:/abs/path/to/tmp/data
```

Notes:

- `--assets` and `--data` are passed through from `moon.game.json` by
  `mgstudio-cli` and may contain a `dir:` prefix.
- Status: functional for basic 2D rendering:
  - `winit` window + keyboard/mouse input (`mgstudio_host.window_*` / `input_*`)
  - `wgpu` surface + sprite batching (`sprite.wgsl`) + basic 2D meshes (`mesh.wgsl`)
  - texture assets: `asset_load_texture`, `asset_create_dynamic_texture`,
    `asset_update_texture_region_bytes`, and basic sampler switching
- Known limitations (as of 2026-02-02):
  - On Apple Silicon (AArch64) some `wasm-gc` carts may not yet compile in
    Wasmtime/Cranelift due to upstream codegen limitations. A practical
    workaround is to build this runtime for `x86_64-apple-darwin` and run it
    via Rosetta.
  - Fonts/folder async asset APIs and gizmo line rendering are still stubbed.
