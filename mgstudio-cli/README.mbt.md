# mgstudio-cli

Developer CLI for mgstudio (native-only).

## Commands

- `mgstudio gen`: scan MoonBit source files for mgstudio tags (`#ecs.component`, `#ecs.resource`) and generate per-package `ecs.g.mbt`. Optionally generates a concrete ECS `World` package.
- `mgstudio run`: run a game described by a game config file in the native runtime (calls export `game_app`).
- `mgstudio serve`: serve the web runtime and run a game described by a game config file in the browser (calls export `game_app`).
- `mgstudio new`: create a new MoonBit game project template (`moon new` + `moon.game.json` + `index.html`).

## Usage

From the repo root (recommended), use the wrapper script:

```bash
./mgstudio --help

# Run codegen in your game/module directory (must contain moon.mod.json).
(cd mgstudio-engine && ../mgstudio gen)
(cd mgstudio-engine && ../mgstudio gen --check)

# Build a game wasm (example).
moon build --release --target wasm-gc -C mgstudio-engine mgstudio-engine/examples/2d/sprite

# Run (calls export: game_app). The runner reads ./moon.game.json (or use --game).
./mgstudio run --game mgstudio-engine/examples/2d/sprite/moon.game.json

# Serve (browser). The runner reads ./moon.game.json (or use --game).
./mgstudio serve --game mgstudio-engine/examples/2d/sprite/moon.game.json
```

## Running Example Games

`mgstudio run/serve` reads a game config JSON file (default name: `moon.game.json`). It does not build game wasm for you.

### Game Config (`moon.game.json`)

Minimal example:

```json
{
  "mgstudio": "0.1.0",
  "cart": "./_build/wasm-gc/release/build/main/main.wasm",
  "assets": "./assets",
  "data": "./tmp/data",
  "native": { "wgpu_lib": "/absolute/path/to/libwgpu_native.dylib" },
  "web": { "addr": "localhost", "port": 8099 }
}
```

Notes:

- Paths are resolved relative to the config file directory.
- File name is not fixed. Use `--game <path>` to point to any config file name.

### Native (Local Window)

```bash
# auto-discover ./moon.game.json from current directory upwards
./mgstudio run

# or specify a config path explicitly
./mgstudio run --game path/to/moon.game.json

# optional: override libwgpu_native path
./mgstudio run --game path/to/moon.game.json --wgpu-lib /absolute/path/to/libwgpu_native.dylib
```

### Web (Browser)

```bash
# auto-discover ./moon.game.json from current directory upwards
./mgstudio serve

# or specify a config path explicitly
./mgstudio serve --game path/to/moon.game.json

# optional: override bind/port
./mgstudio serve --game path/to/moon.game.json --port 8099
```

### Non-Repo Layouts (Distributed Games)

`mgstudio` does not require a full git repo. If the runtime is not discoverable near the wasm file, pass:

```bash
./mgstudio run --game path/to/moon.game.json --runtime-root /path/to/runtime_bundle_root
```

`mgstudio serve` uses a staged served root and loads `mgstudio-runtime-web.js` from the URL provided in config (or a default GitHub release URL). It does not need `--runtime-root`.

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
