# 3D Alignment Worker Post Round 2

Date: 2026-02-28
Owner: render3d post-process parity
Scope: `bloom_3d`, `color_grading`, `auto_exposure`, `depth_of_field`

## Completed This Round

- Expanded `@render3d.Bloom` surface to align with Bevy settings used by `bevy/examples/3d/bloom_3d.rs`:
  - `intensity`
  - `low_frequency_boost`
  - `low_frequency_boost_curvature`
  - `high_pass_frequency`
  - `prefilter { threshold, threshold_softness }`
  - `composite_mode`
  - `max_mip_dimension`
  - `scale`
- Added Bevy-style bloom presets on the API surface (`default`/natural baseline + anamorphic/old_school/screen_blur constructors).
- Wired camera bloom execution in `render3d_execute_system` using existing backend hook `host_gpu_draw_bloom2d`, including tonemapping mode and deband dither forwarding.
- Extended `Camera3dBundle` surface with optional post-process inserts for `Bloom`, `Tonemapping`, and `DebandDither`.
- Updated `examples/3d/bloom_3d/main.mbt` to write the real bloom component fields directly instead of emissive/ambient proxy remapping.
- Updated `examples/3d/auto_exposure/main.mbt` to use a real camera `Skybox` (still proxying exposure adaptation logic).
- Updated `examples/3d/depth_of_field/main.mbt` camera setup to match Bevy-side HDR/tonemapping/bloom context while keeping DOF behavior proxied.

## Remaining Blockers

- `AutoExposure` parity blocker:
  - Missing runtime/backend support for histogram metering + compute adaptation path equivalent to Bevy `AutoExposurePlugin`.
  - Missing compensation-curve asset pipeline and camera component execution hook.
- `DepthOfField` parity blocker:
  - Missing runtime/backend post-process pipeline for Bevy `DepthOfField` (`Gaussian`/`Bokeh` modes) and related camera settings execution.
- Bloom implementation delta:
  - 3D bloom currently reuses the existing bloom2d compositor hook for post-pass compositing, so exact Bevy visual output/pipeline ordering may still differ in edge cases.
- API/component rollout scope blocker:
  - Introducing fully functional `AutoExposure` / `DepthOfField` ECS camera components requires coordinated generator + world aggregation + backend work beyond this owned-file slice.

## Suggested Next Steps

- Add backend host API for `auto_exposure` histogram pass and curve sampling, then introduce `@render3d.AutoExposure` as a true camera component.
- Add backend DOF passes and expose `@render3d.DepthOfField` + mode enum as true camera components.
- After backend support lands, remove proxy behavior from `auto_exposure` and `depth_of_field` examples and switch to direct camera component mutation.
