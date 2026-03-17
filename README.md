## moon-game-studio (mgstudio)

A Bevy-aligned game engine in MoonBit, now running in a native-only architecture.

### Repository layout

- `mgstudio-engine/`: engine core + native runtime bridge (`runtime_native/*`)
- `mgstudio-page/`: docs-only static site for example catalog and run instructions
- `bevy/`: local gitignored Bevy baseline checkout for parity reference
- `scripts/`: project scripts (native smoke, parity tooling)

### Quick start (native)

1. Install MoonBit and update registry.
2. Run an example directly:

```bash
moon -C mgstudio-engine run --target native examples/3d/3d_scene
```

Representative examples:

- `examples/2d/sprite`
- `examples/2d/2d_shapes`
- `examples/3d/pbr`
- `examples/3d/3d_shapes`
- `examples/3d/3d_scene`
- `examples/ui/button`

### Common commands

- `moon -C mgstudio-engine check --target native`
- `moon -C mgstudio-engine test --target native`
- `moon -C mgstudio-engine build --target native <package>`
- `./scripts/smoke_bevy_examples.sh`

### Runtime options

- `MGSTUDIO_ASSETS_DIR` (default: `./assets`)
- `MGSTUDIO_DATA_DIR` (default: `./tmp/data`)

### Notes

- WASM/Web runtime and `mgstudio` CLI were removed in this native-only cutover.
- Planning artifacts under `.private/` are git-ignored and should not be committed.
