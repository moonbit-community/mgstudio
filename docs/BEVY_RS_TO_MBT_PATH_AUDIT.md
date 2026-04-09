# Bevy RS -> MBT Path Audit

## Canonical Rule

- Every `bevy/**/*.rs` has a corresponding `mgstudio-engine/**/*.mbt`.
- `mod.rs` is always mapped to `top.mbt`.

## Canonical Commands

- Excluding `bevy/target/**`:
  - `scripts/check_bevy_rs_to_mbt_paths.sh`
- Including `bevy/target/**`:
  - `INCLUDE_TARGET=1 scripts/check_bevy_rs_to_mbt_paths.sh`
- Sync missing mappings:
  - `scripts/sync_bevy_rs_to_mbt_paths.sh`
  - `INCLUDE_TARGET=1 scripts/sync_bevy_rs_to_mbt_paths.sh`

## Current Snapshot (2026-04-08)

- Excluding `bevy/target/**`:
  - `total_rs=1687`
  - `missing=0`
  - `collision_count=0`
  - `mod_rule_violation_count=0`
- Including `bevy/target/**`:
  - `total_rs=1718`
  - `missing=0`
  - `collision_count=0`
  - `mod_rule_violation_count=0`
- Source-shape scaffold status:
  - `pure_anchor_files=0` (`rg -l "Bevy source-shape anchor\\." mgstudio-engine | wc -l`)
  - `scaffold_files_with_explicit_bevy_source=920/920` (`_scaffold_owner` files all carry `Bevy source: ...`)

## Notes

- `examples` are checked in strict same-path mode (`bevy/examples/**.rs -> mgstudio-engine/examples/**.mbt`).
- The checker can also run in non-strict mode internally, but strict mode is the default for audit.
