# mgstudio-cli

Developer CLI for mgstudio (native + web).

## Commands

- `mgstudio gen`: scan MoonBit source files for mgstudio tags (`#ecs.component`, `#ecs.resource`) and generate per-package `ecs.g.mbt`. Optionally generates a concrete ECS `World` package.
- `mgstudio run`: run a game described by a game config file in the native runtime (calls export `game_app`).
- `mgstudio serve`: serve the web runtime and run a game described by a game config file in the browser (calls export `game_app`).
- `mgstudio new`: create a new MoonBit game project template (`moon new` + `moon.game.json`).

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
  "sdkroot": "$HOME/.local/share/mgstudio/current",
  "cart": "./_build/wasm-gc/release/build/cmd/main/main.wasm",
  "web": { "addr": "127.0.0.1", "port": 8099 },
  "assets_allow_sdk_override": false
}
```

Notes:

- Paths are resolved relative to the config file directory.
- `sdkroot` supports `$HOME` and `~/` expansion.
- File name is not fixed. Use `--game <path>` to point to any config file name.
- `assets` and `data` are optional. If omitted, defaults are `./assets` (if it exists) and `./tmp/data`.
  The CLI builds an assets overlay so both game assets and SDK-provided engine
  assets are visible to runtimes.

### Native (Local Window)

```bash
# auto-discover ./moon.game.json from current directory upwards
./mgstudio run

# or specify a config path explicitly
./mgstudio run --game path/to/moon.game.json

# select the Rust/wasmtime native backend (experimental)
./mgstudio run --backend wasmtime
```

Note: the wasmtime backend is currently experimental and may fail to compile
some `wasm-gc` carts on AArch64 due to upstream codegen limitations.
It currently supports basic 2D sprite + mesh rendering via `wgpu`, but some
APIs (e.g. fonts/folder async assets) may still be stubbed.

macOS (Apple Silicon) workaround: build/run the runtime as x86_64 under Rosetta:

```bash
export MGSTUDIO_WASMTIME_CARGO_TARGET=x86_64-apple-darwin
./mgstudio run --backend wasmtime
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

`mgstudio` does not require a full git repo. It runs the game described by `moon.game.json` (or your `--game` path).

`mgstudio serve` uses a staged served root and copies `mgstudio-runtime-web.js`
from the SDK into the served directory (offline by default).

## Install (Local Symlink)

### Install (SDK)

`mgstudio` expects an SDK directory (configured via `moon.game.json.sdkroot`) that
contains:

- `share/mgstudio/assets/` (engine default assets, including built-in shaders)
- `share/mgstudio/web/mgstudio-runtime-web.js` (web runtime bundle, for `mgstudio serve`)
- `lib/libwgpu_native.dylib` (native rendering via `wgpu_mbt`)

For local development you can build and install a SDK directory into the default
location `$HOME/.local/share/mgstudio/current`:

```bash
# Build the SDK dir (requires a local libwgpu_native.dylib).
./scripts/mgstudio-sdk-build --wgpu-lib /path/to/libwgpu_native.dylib

# Install it into $HOME/.local/share/mgstudio/current and link mgstudio into ~/.local/bin.
./scripts/mgstudio-sdk-install --from ./_out/sdk/mgstudio-sdk-*-darwin-arm64
```

### Install (Repo Symlink, Dev Only)

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

## Notes

- Current implementation uses `moonbitlang/parser` to parse source files. If the parser lags behind compiler syntax, `mgstudio gen` may require temporary syntax workarounds until upstream catches up.
