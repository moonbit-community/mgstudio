# mgstudio-cli

Developer CLI for mgstudio (native-only).

## Commands

- `mgstudio gen`: scan MoonBit source files for mgstudio tags (currently `#ecs.component`) and generate per-package `ecs.g.mbt`.

## Usage

From the repo root (recommended), use the wrapper script:

```bash
./mgstudio --help
./mgstudio gen --workspace . --write
./mgstudio gen --workspace . --check
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
- finds `#ecs.component` on type declarations
- writes `ecs.g.mbt` into that package directory

The generated file is deterministic. Use `--check` in CI to fail on drift.

## Notes

- Current implementation uses `moonbitlang/parser` to parse source files. If the parser lags behind compiler syntax, `mgstudio gen` may require temporary syntax workarounds until upstream catches up.
