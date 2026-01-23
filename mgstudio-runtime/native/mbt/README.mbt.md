# mgstudio-runtime-native

Native (host) runtime for `mgstudio-engine` powered by `Milky2018/wasmoon`.

## Status

This is a bring-up PoC that wires a `wasmoon` linker with stub `mgstudio_host`
imports, and attempts to instantiate the wasm-gc build.

Currently blocked by a `wasmoon@0.1.2` parser limitation on WasmGC recursive
type groups (forward references): see bd issue `moon-game-studio-953`.
