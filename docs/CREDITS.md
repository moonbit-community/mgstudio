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

Some runtime example assets are also staged from the vendored Bevy example
asset tree into `mgstudio-engine/assets/` so that migrated examples load from
mgstudio-owned paths instead of vendor paths.

- License: Apache-2.0 OR MIT (dual-licensed)
- License texts: `bevy/LICENSE-APACHE`, `bevy/LICENSE-MIT`
