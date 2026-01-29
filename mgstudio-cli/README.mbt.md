# mgstudio-cli

Developer CLI for mgstudio (native-only).

## Commands

- `mgstudio gen`: scan MoonBit source files for mgstudio tags (`#ecs.component`, `#ecs.resource`) and generate per-package `ecs.g.mbt`. Optionally generates a concrete ECS `World` package.
- `mgstudio run`: run a wasm-gc game module in the native runtime (calls export `game_app`).

## Usage

From the repo root (recommended), use the wrapper script:

```bash
./mgstudio --help
./mgstudio gen --workspace . --write
./mgstudio gen --workspace . --check
./mgstudio gen --workspace . --world-pkg mgstudio-engine/ecs_world

# Build a game wasm (example).
moon build --release --target wasm-gc -C mgstudio-engine mgstudio-engine/examples/2d/sprite

# Run the wasm (calls export: game_app).
./mgstudio run mgstudio-runtime/examples/2d/sprite/sprite.wasm
```

## Install (Local Symlink)

For a convenient `mgstudio` on your `PATH`, install a symlink to the repo wrapper:

```bash
./scripts/mgstudio-install
mgstudio --help
```

By default this installs to `$XDG_BIN_HOME` or `~/.local/bin`. You can customize the target directory:

```bash
./scripts/mgstudio-install --bin-dir "$HOME/.local/bin"
```

To uninstall:

```bash
./scripts/mgstudio-install --uninstall
```

Or build and run the binary directly:

```bash
moon -C mgstudio-cli build --release
./mgstudio-cli/_build/native/release/build/main/main.exe --help
```

`mgstudio gen` options are implemented with `TheWaWaR/clap`.

## Generated Output

For each MoonBit package directory containing `moon.pkg.json`, `mgstudio gen`:

- scans `.mbt` sources (skipping `_test.mbt`, `_wbtest.mbt`, and `*.g.mbt`)
- finds `#ecs.component` / `#ecs.resource` on type declarations
- writes `ecs.g.mbt` into that package directory

The generated file is deterministic. Use `--check` in CI to fail on drift.

If `--world-pkg <dir>` is provided, it also generates:

- `<dir>/ecs_world.g.mbt`: a concrete `World` type with component stores/resources as fields
- `<dir>/moon.pkg.json`: imports required packages for those types

## Notes

- Current implementation uses `moonbitlang/parser` to parse source files. If the parser lags behind compiler syntax, `mgstudio gen` may require temporary syntax workarounds until upstream catches up.
