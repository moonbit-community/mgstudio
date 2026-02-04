# Bevy Baseline (Reproducible Reference)

This repository is **Bevy-aligned**: some engine/runtime semantics and APIs are
implemented to mirror Bevy concepts for easier migration and parity checks.

To make this reproducible, we pin a concrete Bevy version as the reference for
ported behavior.

## Baseline

- Repository: `bevyengine/bevy`
- Tag: `v0.15.3`
- Commit: `75f04a743bc3da77d3d1fac9d9322920d56ed05b`

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
is gitignored). Use the helper script to fetch a local copy pinned to the
baseline:

```bash
./scripts/fetch_bevy.sh
```

This creates `./bevy` at the pinned tag and validates the commit hash.

