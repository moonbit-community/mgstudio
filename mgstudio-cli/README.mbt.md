# mgstudio-cli

Developer CLI for mgstudio (native + web).

## Commands

- `mgstudio run`: run a game described by a game config file in the native runtime (calls export `game_app`).
- `mgstudio serve`: serve the web runtime and run a game described by a game config file in the browser (calls export `game_app`).
- `mgstudio new`: create a new MoonBit game project template (`moon new` + `moon.game.json`).

## Usage

If you installed mgstudio via the SDK, use the `mgstudio` command:

```bash
mgstudio --help

# Build a game wasm (example).
moon -C mgstudio-engine build --release --target wasm mgstudio-engine/examples/2d/sprite

# Run (calls export: game_app). The runner reads ./moon.game.json (or use --game).
mgstudio run --game mgstudio-engine/examples/2d/sprite/moon.game.json

# Serve (browser). The runner reads ./moon.game.json (or use --game).
mgstudio serve --game mgstudio-engine/examples/2d/sprite/moon.game.json
```

From this repo root, use the dev wrapper:

```bash
./mgstudio-dev --help
```

## Running Example Games

`mgstudio run/serve` reads a game config JSON file (default name: `moon.game.json`). It does not build game wasm for you.

### Game Config (`moon.game.json`)

Minimal example:

```json
{
  "mgstudio": "0.1.0",
  "sdkroot": "$HOME/.local/share/mgstudio/current",
  "cart": "./_build/wasm/release/build/cmd/main/main.wasm",
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
mgstudio run

# or specify a config path explicitly
mgstudio run --game path/to/moon.game.json
```

Native run uses the Rust/wasmtime runtime.
It currently supports basic 2D sprite + mesh rendering via `wgpu`, but some
APIs (e.g. fonts/folder async assets) may still be stubbed.

The CLI expects the wasmtime runtime binary at:

- `<sdkroot>/bin/mgstudio-runtime-native-wasmtime` (bundled in current SDK releases), or
- via `MGSTUDIO_WASMTIME_RUNTIME=/abs/path/to/mgstudio-runtime-native-wasmtime`

In this repo, `./mgstudio-dev run ...` auto-builds and uses the local runtime
if `MGSTUDIO_WASMTIME_RUNTIME` is not set.

macOS (Apple Silicon) workaround: build/run the runtime as `x86_64-apple-darwin`
under Rosetta:

```bash
cd mgstudio-runtime/native-wasmtime
cargo build --release --target x86_64-apple-darwin
export MGSTUDIO_WASMTIME_RUNTIME="$(pwd)/target/x86_64-apple-darwin/release/mgstudio-runtime-native-wasmtime"
cd -
mgstudio run
```

### Web (Browser)

```bash
# auto-discover ./moon.game.json from current directory upwards
mgstudio serve

# or specify a config path explicitly
mgstudio serve --game path/to/moon.game.json

# optional: override bind/port
mgstudio serve --game path/to/moon.game.json --port 8099
```

### Non-Repo Layouts (Distributed Games)

`mgstudio` does not require a full git repo. It runs the game described by `moon.game.json` (or your `--game` path).

`mgstudio serve` uses a staged served root and copies `mgstudio-runtime-web.js`
from the SDK into the served directory (offline by default).

## Install

### Install (SDK)

`mgstudio` expects an SDK directory (configured via `moon.game.json.sdkroot`) that
contains:

- `bin/mgstudio-runtime-native-wasmtime` (for `mgstudio run`)
- `share/mgstudio/assets/` (engine default assets, including built-in shaders)
- `share/mgstudio/web/mgstudio-runtime-web.js` (web runtime bundle, for `mgstudio serve`)

Recommended install (darwin-arm64):

```bash
curl -fsSL https://github.com/moonbit-community/mgstudio/releases/latest/download/mgstudio-install.sh | bash
mgstudio --help
```

Or build and run the binary directly:

```bash
moon -C mgstudio-cli build --release
./mgstudio-cli/_build/native/release/build/cmd/mgstudio/mgstudio.exe --help
```
