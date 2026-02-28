# 3D Alignment Round 4: Temporal/Tonemap/Fog Camera Scope

Date: 2026-02-28

## Scope implemented

- Runtime-executed camera components now consumed in `render3d_execute_system`:
  - `Hdr`
  - `Fxaa` (postprocess enable path)
  - `TemporalJitter`
  - `TemporalAntiAliasing`
  - `MotionVectorPrepass`
- Added standalone tonemap/deband postprocess path when bloom is absent.
  - Implemented via `host_gpu_draw_bloom2d(enabled=0)` with bloom weight forced to zero.
- Fullscreen postprocess parameters are now plumbed from camera components into
  `host_gpu_draw_bloom2d` for both bloom and tonemap-only paths:
  - `Fxaa` (`enabled`, `edge_threshold`, `edge_threshold_min`)
  - `ChromaticAberration` (`intensity`, `max_samples`)
  - `Vignette` (`intensity`, `radius`, `smoothness`, `roundness`, `center`,
    `edge_compensation`, `color`)
- Removed object-space chromatic/vignette color approximation from mesh draw to
  prevent double application once fullscreen pass is active.
- Reconciled `gpu_draw_bloom2d` ABI across runtimes (web/native/wasmtime) to
  match the expanded engine host signature and preserve parameter ordering:
  - `view_width/view_height` + LUT ids now read from the new tail slots.
  - FXAA/chromatic/vignette uniforms now consume the intended postprocess slots
    in all runtimes (fixed native uniform layout offset mismatch).
- Motion-vector prepass can now run without motion blur if camera requests it.
- Temporal jitter now offsets sub-camera projection bias.
- `fog` and `atmospheric_fog` examples moved from global fog mutation to camera-scoped fog (`Camera3d.distance_fog`).
- `fog_volumes`, `scrolling_fog`, and `volumetric_fog` also moved to camera-scoped fog updates (still proxy volumetric behavior, but no longer global fog mutation).

## Validation

- `moon check -p render3d`
- `moon check -p examples/3d/fog`
- `moon check -p examples/3d/atmospheric_fog`
- `moon check -p examples/3d/fog_volumes`
- `moon check -p examples/3d/scrolling_fog`
- `moon check -p examples/3d/volumetric_fog`
- `moon check` in `mgstudio-runtime/web`
- `cargo build --release` in `mgstudio-runtime/native-wasmtime`
- `for pkg in $(find examples/3d -mindepth 1 -maxdepth 1 -type d | sort); do moon check -p "$pkg"; done`
- `./scripts/smoke_bevy_examples.sh`
- Full 3d smoke: `ALL_3D_PASS_ROUND6`

## Remaining non-exact gaps (unchanged)

- No true TAA resolve/history accumulation.
- No true FXAA/SMAA/DLSS/CAS implementation.
- No dedicated standalone chromatic/vignette pass yet (currently piggybacks on
  the bloom2d fullscreen composite path).
- Deferred, volumetrics, decals, shadows, SSR/SSAO, probe/lightmap parity still pending.
