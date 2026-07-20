# WGSL Dependency 0.16 API Migration

This document records the source-breaking dependency boundary change retained
when the WGSL dependency family moved from `0.15.3` to `0.16.0`.

## Public API changes

The removed `Milky2018/wgsl/common` package must no longer appear in downstream
imports. Use the user-facing `Milky2018/moon_wgsl` facade for public contracts
and project policy:

| 0.15.3 import or call | 0.16.0 replacement |
| --- | --- |
| `Milky2018/wgsl/common` | `Milky2018/moon_wgsl` |
| `@common.default_wgsl_value_defines()` | `@moon_wgsl.bevy_wgsl_value_defines()` |
| direct public `directive` scanner imports | `@moon_wgsl.get_preprocessor_metadata()` and `@moon_wgsl.wgsl_source_define_import_path()` |

This changes the package owner printed for public `ShaderDefValue`,
`WgslComposeOptions`, `WgslSourceFile`, and `WgslSourceScanOptions` types in
generated interfaces. Their mgstudio API meaning is unchanged, but downstream
code with explicit `Milky2018/wgsl/common` imports or type annotations must
move those references to `Milky2018/moon_wgsl`.

Mgstudio still imports `Milky2018/moon_wgsl_naga_oil/compose` at its internal
runtime boundary because it requires the explicit
`compose_wgsl_runtime_valid` entry point. This low-level path is not re-exported
as an mgstudio public type.

## Runtime behavior

The runtime composer now registers the complete embedded shader registry and
lets the 0.16 composer resolve the active import graph. It no longer supplies a
locally precomputed root dependency subset for runtime composition. This is
required for conditional Bevy imports whose active dependencies depend on the
shader definitions passed to composition.

The 0.16 upgrade makes a minimal fully qualified module function call compose
and flatten successfully. The complete pinned-Bevy deferred-lighting graph
still fails on `bevy_pbr::fog::linear_fog`; that remaining external blocker is
tracked by ISS-405 and must not be hidden by rewriting copied WGSL.
