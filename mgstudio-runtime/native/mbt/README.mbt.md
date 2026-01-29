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
- On `wgpu_mbt<=0.1.2`, using it as a dependency can fail because native C stub
  include/link paths are resolved relative to the *consumer* workspace root
  (`wgpu.h file not found` / missing `libwgpu_native.a`).
- On `wgpu_mbt>=0.1.4`, the include-path failure is improved, but the dynamic
  library `libwgpu_native.dylib` still needs to exist at runtime (wgpu-mbt uses
  `dlopen`). For now you may need to build it manually via Cargo inside the
  dependency tree, or set `MBT_WGPU_NATIVE_LIB`.

Local workaround (until upstream fix):
```bash
cd mgstudio-runtime/native/mbt
ln -s .mooncakes/Milky2018/wgpu_mbt/vendor vendor
moon run . ../../../mgstudio-engine/_build/wasm-gc/release/build/examples/runner/runner.wasm run_sprite
```

Recommended workflow (from repo root):
```bash
./mgstudio run --example sprite
# or explicitly:
./mgstudio run native --example sprite
```

If you hit `failed to dlopen libwgpu_native`, set `MBT_WGPU_NATIVE_LIB` (or pass
`--wgpu-lib` to `mgstudio run`) to point to a built `libwgpu_native.dylib`.

If you hit build errors beyond the above, please capture the full log and update
bd issue `moon-game-studio-izv`.
