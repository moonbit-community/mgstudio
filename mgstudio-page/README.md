# Moon Game Studio Page

`mgstudio-page` is a docs-only static website for native example discovery.

It no longer embeds a web runtime or loads WASM binaries.

## Build

```bash
./build.sh
```

The output is written to `dist/`.

## Serve Locally

```bash
./serve.sh
```

## Deploy

`main` branch pushes deploy `mgstudio-page/dist` to GitHub Pages via `.github/workflows/pages.yml`.
