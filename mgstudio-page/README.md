# Moon Game Studio Page

`mgstudio-page` is a static website for showcasing engine examples in the browser.

This folder builds browser-ready example bundles directly from `mgstudio-engine`
(`--target js`) and serves them as static assets.

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
