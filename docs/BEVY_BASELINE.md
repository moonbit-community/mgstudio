# Bevy Baseline (Reproducible Reference)

This repository is **Bevy-aligned**: some engine/runtime semantics and APIs are
implemented to mirror Bevy concepts for easier migration and parity checks.

To make this reproducible, we pin a concrete Bevy snapshot as the reference for
ported behavior.

## Baseline

- Repository: `bevyengine/bevy`
- Workspace source: local `./bevy` git checkout (not committed)
- Commit: `1413bc4e3632233b8fa610a6cf14b90258556c51`
- Describe: `1413bc4e3`
- Cargo package version (`bevy/Cargo.toml`): `0.19.0-dev`
- Render dependency constraint (`bevy/crates/bevy_render/Cargo.toml`): `wgpu 29.0.3`, `wgpu-types 29.0.3`, `naga 29.0.3`
- Current lockfile resolution (`bevy/Cargo.lock`): `wgpu 28.0.0`, `wgpu-core 28.0.0`, `wgpu-hal 28.0.0`, `wgpu-types 28.0.0`

This baseline supersedes the historical `v0.15.3` reference.

## What "Bevy-aligned" means (UI MVP)

For the UI MVP port (`Milky2018/mgstudio/ui`), "aligned" means:

- Naming follows Bevy conventions where practical (`Val`, `Style`, `UiRect`,
  `UiRoot`, `Interaction`, etc.).
- Behavior is comparable to Bevy for the implemented subset:
  - absolute positioning
  - px/percent sizing
  - button hover/pressed interaction state
- Known gaps are explicit and intentional (see below).

### Known gaps (intentional MVP limitations)

- No flexbox layout (no `taffy`-like behavior).
- `UiRect.right/bottom` are ignored.
- `Val::Auto` resolves to `0` (documented, not Bevy-parity).
- No padding/margins, no text alignment options inside a node.
- UI rendering is implemented via 2D sprites + a shared 1x1 white texture.

## Fetching Bevy Sources Locally

The Bevy source tree is **not** checked into this repo (the `bevy/` directory
is gitignored). Use the helper script to fetch a local copy pinned to this
baseline commit:

```bash
./scripts/fetch_bevy.sh
```

This creates `./bevy` at the pinned commit and validates the commit hash.
