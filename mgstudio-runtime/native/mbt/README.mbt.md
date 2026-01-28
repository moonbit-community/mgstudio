# mgstudio-runtime-native

Native (host) runtime for `mgstudio-engine` powered by `Milky2018/wasmoon`.

## Status

This is a bring-up PoC that wires a `wasmoon` linker with stub `mgstudio_host`
imports, and attempts to instantiate the wasm-gc build.

The WasmGC `rec` forward-reference parser bug is fixed in `Milky2018/wasmoon >= 0.1.3`.

Current blocker: the `mgstudio_host` implementation is still stubs (GPU/window/assets),
so running examples may trap (`unreachable`). See bd issue `moon-game-studio-1r4`.

## WGPU bring-up

We are experimenting with a minimal native renderer using `Milky2018/wgpu_mbt` to
back a subset of `mgstudio_host` GPU calls (surface frame + a single render pass,
sprite quads, and simple meshes).

Known upstream blocker (wgpu_mbt packaging/build):
- When `wgpu_mbt` is used as a dependency (confirmed on `0.1.0`, `0.1.1`, and `0.1.2`),
  its native C stub include/link paths are currently resolved relative to the
  *consumer* workspace root. This means `moon run` may fail with
  `wgpu.h file not found` / missing `libwgpu_native.a` unless
  `vendor/wgpu-native` exists in this folder.

Local workaround (until upstream fix):
```bash
cd mgstudio-runtime/native/mbt
ln -s .mooncakes/Milky2018/wgpu_mbt/vendor vendor
moon run . ../../../mgstudio-engine/_build/wasm-gc/release/build/examples/runner/runner.wasm run_sprite
```

If you hit build errors beyond the above, please capture the full log and update
bd issue `moon-game-studio-izv`.
