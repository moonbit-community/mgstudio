# WGSL dependency 0.17.0 migration

## Version boundary

The synchronized WGSL dependency set is upgraded from `0.16.0` to `0.17.0`:

- `Milky2018/moon_wgsl`
- `Milky2018/wgsl`
- `Milky2018/moon_wgsl_naga`
- `Milky2018/moon_wgsl_naga_oil`

These packages must remain on the same release version.

## Runtime composition fix

Version `0.17.0` resolves fully qualified calls discovered through a transitive
module import. This fixes the external blocker tracked by ISS-405 and upstream
issue `moonbit-community/moon_wgsl#17`. In particular, the pinned Bevy PBR
shader paths containing `bevy_pbr::fog::linear_fog` and
`irradiance_volume::irradiance_volume_light` now compose without invalid WGSL
IR errors.

`WgslComposeOptions` also gained the required `immediate_specializations`
field. Mgstudio initializes it to an empty array, preserving the previous
behavior until a shader explicitly requires an immediate-value
specialization.

## Filesystem adapter ownership

The upstream release removed `WgslSourceScanOptions` and
`scan_wgsl_source_files` from the published runtime packages. Their maintained
implementation now lives in the upstream repository's unpublished
`tools/wgsl_io` adapter package.

Mgstudio already owns shader asset and filesystem access in `shader/source`, so
that package now contains the upstream `0.17.0` scan adapter implementation.
The public mgstudio API remains source-compatible:

```mbt
let options = @shader_source.ShaderSourceScanOptions::default()
let files = @shader_source.scan_shader_source_files(root, options)
```

The option fields and defaults are unchanged: recursive scanning is enabled,
`.wgsl` is the default extension, and no path prefixes are excluded.

## Verification

- `moon test shader/compile/namespace_function_external_blocker_test.mbt
  --target native --release --deny-warn`
- `moon test shader/source/scan_test.mbt --target native --release
  --deny-warn`
- `moon test pbr/render/wgsl_entrypoint_wbtest.mbt --target native --release
  --deny-warn`
- `moon check --target native` (`0` errors; existing warnings are tracked by
  ISS-443)
- frame-90 native capture of `examples/3d/deferred_rendering`
- frame-90 native capture of `examples/3d/anti_aliasing`
- frame-90 native capture of `examples/3d/irradiance_volumes`

All three runtime logs were empty. The `irradiance_volumes` image still has an
existing visual-parity defect owned by ISS-019; this migration establishes
successful shader composition, not visual acceptance of that example.
