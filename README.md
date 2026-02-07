## moon-game-studio (mgstudio)

An experimental Bevy-aligned game engine and tooling stack written in MoonBit.

### Install (end users)

Install the mgstudio SDK + CLI from GitHub Releases (darwin-arm64):

```bash
curl -fsSL https://github.com/moonbit-community/mgstudio/releases/latest/download/mgstudio-install.sh | bash
```

### Repository layout

- `mgstudio-engine/`: engine core (ECS, math, 2D rendering, text, assets, etc.)
- `mgstudio-cli/`: `mgstudio` developer CLI (`gen`, `new`, `run`, `serve`)
- `mgstudio-runtime/`: runtime implementations
  - `mgstudio-runtime/native/`: native runtime (Wasm + host functions, wgpu native)
  - `mgstudio-runtime/web/`: web runtime bundle builder (produces `mgstudio-runtime-web.js`)
  - `mgstudio-runtime/core/`: shared runtime utilities
- `mgstudio-page/`: web page (examples gallery / future GitHub Pages site)
- `bevy/`: vendored Bevy source for reference and migration parity checks

### Quick start (local development)

1. Install the SDK (recommended even for repo dev):
   - `./mgstudio-install.sh`
2. Create a new game:
   - `mgstudio new mygame`
   - For local engine development (path dependency): `./mgstudio-dev new mygame --local-engine`
3. Build the game cart (Wasm GC, from the game directory):
   - `cd mygame && moon build --release --target wasm`
4. Run:
   - Native: `mgstudio run -g mygame/moon.game.json`
   - Web: `mgstudio serve -g mygame/moon.game.json` (plain HTTP)

### Common commands

- `mgstudio gen` — generate `ecs.g.mbt` files from `#ecs.component` / `#ecs.resource`
- `mgstudio new <name>` — scaffold a game project
- `mgstudio run` — run a game in the native runtime
- `mgstudio serve` — serve the web runtime and run a game in the browser

Repo development wrapper:

- `./mgstudio-dev ...` builds `mgstudio-cli` (release) and runs it

Project quality gates (per module):

- `moon check`, `moon test`, `moon fmt`, `moon info`

### SDK and `moon.game.json`

Games are configured via `moon.game.json`. The key field is:

- `sdkroot`: points to the installed SDK root directory (e.g. `$HOME/.local/share/mgstudio/current`)

The CLI uses `sdkroot` to locate:

- `share/mgstudio/assets/` (engine default assets, including built-in shaders)
- `share/mgstudio/web/mgstudio-runtime-web.js` (web runtime bundle for `serve`)
- `lib/libwgpu_native.dylib` (native runtime dependency; current focus is `darwin-arm64`)

### Notes

- Planning artifacts live under `.private/` and should not be committed.
- Use `bd` for task tracking.
