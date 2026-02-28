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
- Motion-vector prepass can now run without motion blur if camera requests it.
- Temporal jitter now offsets sub-camera projection bias.
- `fog` and `atmospheric_fog` examples moved from global fog mutation to camera-scoped fog (`Camera3d.distance_fog`).

## Validation

- `moon check -p render3d`
- `moon check -p examples/3d/fog`
- `moon check -p examples/3d/atmospheric_fog`
- `moon check` in `mgstudio-runtime/web`
- `cargo build --release` in `mgstudio-runtime/native-wasmtime`

## Remaining non-exact gaps (unchanged)

- No true TAA resolve/history accumulation.
- No true FXAA/SMAA/DLSS/CAS implementation.
- No full-screen dedicated chromatic/vignette post stack.
- Deferred, volumetrics, decals, shadows, SSR/SSAO, probe/lightmap parity still pending.
