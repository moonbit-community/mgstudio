# Credits

This repository contains or depends on third-party software. This document
records attribution and pointers to license texts that should be included when
redistributing this project (in source or binary form).

## cosmic-text

Text shaping and layout is provided via the MoonBit package `moon_cosmic`, which
is based on the Rust project `cosmic-text` (System76 / Pop!\_OS).

- License: Apache-2.0 OR MIT (dual-licensed)
- License texts: `third_party/cosmic-text/LICENSE-APACHE`,
  `third_party/cosmic-text/LICENSE-MIT`

## Bevy

Some engine/runtime implementations are derived from or aligned with Bevy. The
Bevy source tree is included under `bevy/` for reference and migration
guidance.

- License: Apache-2.0 OR MIT (dual-licensed)
- License texts: `bevy/LICENSE-APACHE`, `bevy/LICENSE-MIT`

## wgpu-native

The native renderer uses `wgpu_mbt`, which loads the `wgpu-native` dynamic
library (`libwgpu_native`) at runtime. Our SDK distribution includes a
prebuilt `libwgpu_native.dylib` for darwin-arm64.

- License: Apache-2.0 OR MIT (dual-licensed)
- License texts: `third_party/wgpu-native/LICENSE-APACHE`,
  `third_party/wgpu-native/LICENSE-MIT`
