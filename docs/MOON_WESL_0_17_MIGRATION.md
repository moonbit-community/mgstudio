# moon_wesl 0.17.0 migration

## Version boundary

`Milky2018/moon_wesl` is upgraded from `0.1.2` to `0.17.0`. The 0.17 release
uses `Milky2018/wgsl` for WGSL parsing and semantic validation and exposes the
compiled syntax tree through `CompileResult`.

## Compile option API

The former `CompileOptions::with_*` builder methods were removed. Configure
the public record from `CompileOptions::default()` instead. Defaults still
enable imports, conditional compilation, stripping, lazy resolution, and
validation. Mgstudio only overrides `lower`, matching its previous behavior:

```mbt
let options = {
  ..@wesl.CompileOptions::default(),
  lower: true,
  features,
}
```

Feature flags now use `Features` and the four-state `Feature` enum rather than
boolean values stored directly in the options. Mgstudio preserves its existing
`ShaderDefVal::Bool` semantics with `Feature::from_bool(value)`. Integer and
unsigned shader definitions remain ignored by the WESL conditional compiler,
as before.

## Resolver and output behavior

The application-owned `ShaderResolver` still implements the published
`Resolver` trait, so asynchronous asset availability and
`ShaderImportNotYetAvailable` behavior are unchanged. `compile(...)` still
returns an object whose `to_string()` method emits WGSL for the render backend.

No mgstudio public API changes are introduced by this migration.

## Verification

- `moon check shader --target native --deny-warn`
- `moon test shader/shader_cache_test.mbt -f 'shader cache compiles wesl
  through loaded shader assets and bool defs' --target native --release
  --deny-warn`
- `moon test shader/wesl_runtime_test.mbt -f 'shader runtime wesl registration
  compiles after imported module is loaded as shader asset' --target native
  --release --deny-warn`
- `moon check --target native` (`0` errors; the existing 226 warnings are
  tracked by ISS-443)
- frame-90 native capture of `examples/shader/shader_material_wesl`; the run
  log is empty and the WESL material pipeline completes. Its existing visual
  parity work remains part of ISS-157 and is not accepted by this dependency
  migration.
