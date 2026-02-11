# mgstudio-cli

Developer CLI for mgstudio.

## Commands

- `mgstudio gen`: scan MoonBit source files for `#ecs.component` / `#ecs.resource` and generate `ecs.g.mbt`.
- `mgstudio run`: auto-build and run a game from `moon.game.json` in native mode.
- `mgstudio serve`: auto-build and serve a game from `moon.game.json` for browser testing.
- `mgstudio new`: create a new MoonBit game template.

## Usage

```bash
mgstudio --help

# Run codegen in a module directory
(cd mgstudio-engine && mgstudio gen)

# Run a game
mgstudio run --game mgstudio-engine/examples/2d/sprite/moon.game.json

# Serve a game
mgstudio serve --game mgstudio-engine/examples/2d/sprite/moon.game.json
```

## Game Config (`moon.game.json`)

Minimal example:

```json
{
  "mgstudio": "0.1.0",
  "sdkroot": "$HOME/.local/share/mgstudio/current",
  "web": { "addr": "127.0.0.1", "port": 8099 },
  "assets_allow_sdk_override": false
}
```

Notes:

- `moon.game.json` must live in the target package directory (the one containing `moon.pkg`).
- The game package should expose `pub fn game_main() -> Unit` and keep `fn main { game_main() }`.
- Paths are resolved relative to the config file directory.
- `sdkroot` supports `$HOME` and `~/` expansion.
- `assets` and `data` are optional. Defaults are `./assets` (if present) and `./tmp/data`.
- `mgstudio run/serve` auto-build from the package inferred by the config directory; no prebuilt cart path is required.

## SDK Expectations

`sdkroot` should contain:

- `share/mgstudio/assets/` (engine default assets, including built-in shaders)
- `lib/libwgpu_native.dylib` (native rendering via `wgpu_mbt`)

## Generated Output

For each package directory containing `moon.pkg`, `mgstudio gen`:

- scans `.mbt` sources (skipping `_test.mbt`, `_wbtest.mbt`, and `*.g.mbt`)
- finds `#ecs.component` / `#ecs.resource`
- writes `ecs.g.mbt` in that package directory
