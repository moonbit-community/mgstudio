# mgstudio-runtime-native

Native (host) runtime for `mgstudio-engine` powered by `Milky2018/wasmoon`.

## Status

This is a bring-up PoC that wires a `wasmoon` linker with stub `mgstudio_host`
imports, and attempts to instantiate the wasm-gc build.

The WasmGC `rec` forward-reference parser bug is fixed in `Milky2018/wasmoon >= 0.1.3`.

Current blocker: the `mgstudio_host` implementation is still stubs (GPU/window/assets),
so running examples may trap (`unreachable`). See bd issue `moon-game-studio-1r4`.
