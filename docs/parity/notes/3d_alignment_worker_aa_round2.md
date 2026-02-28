# 3D Alignment Worker AA Round 2 Notes

- Date: 2026-02-28
- Owner: `AA/skybox/motion-blur/spherical lights/oit`
- Scope:
  - `mgstudio-engine/render3d/*`
  - `mgstudio-engine/examples/3d/anti_aliasing/main.mbt`
  - `mgstudio-engine/examples/3d/skybox/main.mbt`
  - `mgstudio-engine/examples/3d/motion_blur/main.mbt`
  - `mgstudio-engine/examples/3d/spherical_area_lights/main.mbt`
  - `mgstudio-engine/examples/3d/order_independent_transparency/main.mbt`

## Completed in This Pass

1. `render3d` API surface alignment
- `Msaa`
  - Added `samples()` and `from_samples(Int)` so example-level AA controls can map to Bevy-style sample-count semantics.
- `Fxaa`
  - Expanded from marker-like `enabled` state to tunable thresholds:
    - `edge_threshold : FxaaSensitivity`
    - `edge_threshold_min : FxaaSensitivity`
  - Added builder-style APIs (`new_with_sensitivity`, `with_edge_threshold`, `with_edge_threshold_min`, `with_sensitivity`).
- `TemporalAntiAliasing`
  - Expanded to explicit `reset : Bool` setting with `new`/`with_reset`.
- `OrderIndependentTransparencySettings`
  - Expanded from marker to explicit settings:
    - `sorted_fragment_max_count : Int`
    - `fragments_per_pixel_average : Float`
    - `alpha_threshold : Float`
  - Added value sanitization/clamping and builder-style updates.
- `Skybox`
  - Updated default `brightness` to `0.0` to match Bevy semantics.
- `PointLight`
  - Added `affects_lightmapped_mesh_diffuse : Bool` with Bevy-like default `true` and builder helpers.

2. Example parity updates
- `anti_aliasing`
  - Added explicit camera-component wiring for each AA mode:
    - MSAA: inserts mapped `Msaa` sample count.
    - FXAA: inserts configured `Fxaa` sensitivity component.
    - TAA: inserts `TemporalAntiAliasing`, `TemporalJitter`, `DepthPrepass`, `MotionVectorPrepass`.
    - NoAA/SMAA/DLSS fallback paths keep unsupported modes explicit and disable conflicting components.
- `skybox`
  - Kept Bevy-style TAA component placement with clear fallback note for runtimes where it is marker/no-op.
- `motion_blur`
  - Added explicit camera `Msaa::Off` behavior note and wiring to match Bevy web compatibility path.
- `spherical_area_lights`
  - Kept `PointLight.radius` control parity and improved runtime approximation by mapping radius to effective intensity/range.
- `order_independent_transparency`
  - Added camera OIT settings propagation (`OrderIndependentTransparencySettings::new(...)`) from live controls.
  - Added runtime fallback mode synchronization for transparent materials (`Blend` vs `AlphaToCoverage`) when OIT is toggled.
  - Added live controls for OIT settings fields and HUD diagnostics.

## Verification Notes (Web + Wasmtime)

### Web path checks
- Commands run from `mgstudio-engine/`:
  - `moon check -p render3d --target wasm`
  - `moon check -p examples/3d/anti_aliasing --target wasm`
  - `moon check -p examples/3d/skybox --target wasm`
  - `moon check -p examples/3d/motion_blur --target wasm`
  - `moon check -p examples/3d/spherical_area_lights --target wasm`
  - `moon check -p examples/3d/order_independent_transparency --target wasm`
  - `moon check -p render3d --target js`
  - `moon check -p examples/3d/anti_aliasing --target js`
  - `moon check -p examples/3d/skybox --target js`
  - `moon check -p examples/3d/motion_blur --target js`
  - `moon check -p examples/3d/spherical_area_lights --target js`
  - `moon check -p examples/3d/order_independent_transparency --target js`
- Result:
  - All listed checks passed (including `--deny-warn` runs).
  - No warnings or errors were reported on these web-target checks.

### Wasmtime/native path checks
- Commands run from `mgstudio-engine/`:
  - `moon check -p render3d --target native`
  - `moon check -p examples/3d/anti_aliasing --target native`
  - `moon check -p examples/3d/skybox --target native`
  - `moon check -p examples/3d/motion_blur --target native`
  - `moon check -p examples/3d/spherical_area_lights --target native`
  - `moon check -p examples/3d/order_independent_transparency --target native`
- Result:
  - All native checks fail before reaching feature-specific packages due to shared core bindings:
    - `core/host_bytes.mbt` (lines 22, 25, 28, 31, 34)
    - `core/host_string.mbt` (lines 23, 26, 29, 32)
  - Error code: `[4156]` with message equivalent to: import syntax unsupported on native backend; use `extern "C"`.
- Behavioral conclusion:
  - Web compile-path verification is green.
  - Wasmtime/native parity behavior cannot be validated in this pass because the build fails in shared core before owned example/runtime code is type-checked for native.

## Remaining Hard Blockers

1. Native/wasmtime baseline build blocker
- Shared `core` host FFI declarations currently block all `--target native` checks.
- Until this is fixed, native behavioral parity for AA/skybox/motion blur/spherical lights/OIT cannot be validated by compile gate.

2. Anti-aliasing feature ceiling
- SMAA and DLSS are still runtime-fallback modes; no native implementation parity with Bevy post-processing pipeline.

3. Temporal effects completeness
- TAA/motion-blur camera components are now aligned at API level, but full temporal resolve quality parity depends on backend support for history/motion-vector integration details.

4. Spherical area light shading model
- Bevy-style area-light influence from `PointLight.radius` is approximated via intensity/range mapping; physically-matched spherical area-light shading is not yet exposed.

5. OIT renderer parity
- Camera OIT settings API is exposed and wired, but full Bevy OIT pipeline behavior still depends on backend implementation depth (fragment storage/resolve path parity).
