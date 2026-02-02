## moon-game-studio (mgstudio)

An experimental Bevy-aligned game engine and tooling stack written in MoonBit.

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

1. Build and install an SDK (assets + web runtime JS + native wgpu dylib):
   - `scripts/mgstudio-sdk-build` (requires `libwgpu_native.dylib`, see below)
   - `scripts/mgstudio-sdk-install`
2. Create a new game:
   - `./mgstudio new mygame`
   - For local engine development: `./mgstudio new mygame --local-engine`
3. Build the game cart (Wasm GC):
   - `cd mygame && moon build --release --target wasm-gc`
4. Run:
   - Native: `./mgstudio run -g mygame/moon.game.json`
   - Web: `./mgstudio serve -g mygame/moon.game.json` (plain HTTP)

### Common commands

- `./mgstudio gen` — generate `ecs.g.mbt` files from `#ecs.component` / `#ecs.resource`
- `./mgstudio new <name>` — scaffold a game project
- `./mgstudio run` — run a game in the native runtime
- `./mgstudio serve` — serve the web runtime and run a game in the browser

Project quality gates (per module):

- `moon check`, `moon test`, `moon fmt`, `moon info`

### SDK and `moon.game.json`

Games are configured via `moon.game.json`. The key field is:

- `sdkroot`: points to the installed SDK root directory (e.g. `$HOME/.local/share/mgstudio/current`)

The CLI uses `sdkroot` to locate:

- `share/mgstudio/assets/` (engine default assets, including built-in shaders)
- `share/mgstudio/web/mgstudio-runtime-web.js` (web runtime bundle for `serve`)
- `lib/libwgpu_native.dylib` (native runtime dependency; current focus is `darwin-arm64`)

### Installing `libwgpu_native.dylib` (macOS)

`wgpu_mbt` loads `libwgpu_native.dylib` at runtime via `dlopen`. The mgstudio SDK bundles this dylib at:

- `<sdkroot>/lib/libwgpu_native.dylib`

Recommended way to obtain the dylib is via `Milky2018/wgpu_mbt` prebuilt release assets:

```bash
moon new _tmp_wgpu && cd _tmp_wgpu
moon add Milky2018/wgpu_mbt   # downloads to $HOME/.local/lib/libwgpu_native.dylib (postadd hook)
ls -la "$HOME/.local/lib/libwgpu_native.dylib"
```

Then build the SDK:

```bash
scripts/mgstudio-sdk-build --wgpu-lib "$HOME/.local/lib/libwgpu_native.dylib"
```

### Notes

- Planning artifacts live under `.private/` and should not be committed.
- Use `bd` for task tracking.
