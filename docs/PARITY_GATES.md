# Parity Gates

This repository uses a small set of hard gates to keep Bevy-alignment work from
drifting in ways that are easy to miss during feature work.

## Current gates

### `gate_shader_mirror.sh`

Checks that runtime upstream shader sources under
`mgstudio-engine/assets/shaders/` match the vendored Bevy baseline exactly for
all mirrored crates, excluding the explicit `generated/` and `custom/` buckets.

This gate enforces:

- the runtime shader tree keeps exact upstream copies where mirroring is
  intended
- mirrored files are not silently edited in-place
- extra unexpected mirrored files are not introduced

### `gate_no_mgstudio_shader.sh`

Checks that the legacy transitional shader trees are gone and remain gone:

- `mgstudio-engine/assets/shaders/mgstudio`
- `mgstudio-engine/assets/shaders/mgstudio_runtime`

It also scans the engine and CI config for forbidden references to
`shaders/mgstudio/` or `shaders/mgstudio_runtime/`.

### `gate_asset_provenance.sh`

Checks that example assets are loaded from the engine runtime asset tree rather
than external paths such as:

- `bevy/assets`
- `../third_party`
- `.mooncakes`

This preserves runtime asset provenance for example parity claims.

### `gate_visual_runtime.sh`

Runs a small visual screenshot gate over representative 3D examples. The gate
captures screenshots, performs basic image sanity checks, scans runtime logs for
fatal errors, and emits a manifest plus per-case artifacts.

By default it targets:

- `examples/3d/3d_shapes`
- `examples/3d/pbr`
- `examples/3d/3d_scene`

The exact selection can be narrowed or widened with:

- `MGSTUDIO_3D_EXAMPLES_FILTER`
- `MGSTUDIO_3D_EXAMPLES_MAX_CASES`

## Entry point

`mgstudio-engine/scripts/parity_hard_gates.sh` is the top-level entry point for
the parity gate set:

1. `gate_shader_mirror.sh`
2. `gate_no_mgstudio_shader.sh`
3. `gate_asset_provenance.sh`
4. `gate_visual_runtime.sh`

For environments that should only run the static subset, set:

```bash
MGSTUDIO_PARITY_SKIP_VISUAL=1 ./mgstudio-engine/scripts/parity_hard_gates.sh
```

## CI shape

CI intentionally splits parity gates into two jobs:

- `parity static gates`
  Runs `parity_hard_gates.sh` with `MGSTUDIO_PARITY_SKIP_VISUAL=1`
- `parity visual runtime gate`
  Runs `gate_visual_runtime.sh` on macOS and uploads screenshot/log artifacts

This split keeps the static provenance checks fast while preserving a real
native visual gate for representative runtime behavior.

## Scope note

Per the approved migration strategy, shader parity gates target:

- runtime shader asset provenance
- canonical mirrored shader source trees
- runtime shader contract and example behavior parity

They do **not** require re-implementing Bevy's internal `naga` /
`naga_oil` toolchain inside `mgstudio-engine`.
