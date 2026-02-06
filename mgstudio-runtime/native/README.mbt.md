# mgstudio-runtime-native

Native (host) runtime for `mgstudio-engine` powered by `Milky2018/wasmoon`.

## Status

This is a bring-up PoC that wires a `wasmoon` linker with stub `mgstudio_host`
imports, and attempts to instantiate the wasm build.

The WasmGC `rec` forward-reference parser bug is fixed in `Milky2018/wasmoon >= 0.1.3`.

The runtime runs a game wasm module and calls its single exported entrypoint:
`game_app() -> Unit`.

We also provide a small subset of wasm spec test imports (e.g. `spectest.print_char`)
so we can reuse upstream test modules during bring-up.

## WGPU bring-up

We are experimenting with a minimal native renderer using `Milky2018/wgpu_mbt` to
back a subset of `mgstudio_host` GPU calls (surface frame + a single render pass,
sprite quads, and simple meshes).

Known upstream blocker (wgpu_mbt packaging/build):
- `wgpu_mbt` requires `libwgpu_native` at runtime (wgpu-mbt uses `dlopen`).
  Newer `wgpu_mbt` releases no longer bundle `libwgpu_native`; mgstudio provides
  it via the SDK (`moon.game.json.sdkroot/lib/libwgpu_native.dylib`) and passes
  it to the native runtime (which sets `MBT_WGPU_NATIVE_LIB` internally).

Recommended workflow (from repo root):
```bash
# Build a game wasm (example).
moon build --release --target wasm -C mgstudio-engine mgstudio-engine/examples/2d/sprite

# Run the game described by moon.game.json (calls export: game_app).
./mgstudio-dev run --game mgstudio-engine/examples/2d/sprite/moon.game.json
```

If you hit `failed to dlopen libwgpu_native`, verify your SDK installation:

- `moon.game.json.sdkroot` points to a valid SDK directory
- `<sdkroot>/lib/libwgpu_native.dylib` exists
- `<sdkroot>/share/mgstudio/assets/` exists
- `<sdkroot>/share/mgstudio/web/mgstudio-runtime-web.js` exists

If you hit build errors beyond the above, please capture the full log and update
bd issue `moon-game-studio-izv`.
