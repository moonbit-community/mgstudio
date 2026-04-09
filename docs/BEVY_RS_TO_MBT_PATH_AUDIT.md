# Bevy RS -> MBT Path Audit

## Canonical Rule

- Every `bevy/**/*.rs` has a corresponding `mgstudio-engine/**/*.mbt`.
- `mod.rs` is always mapped to `top.mbt`.
- Default audit excludes are centralized in `scripts/bevy_rs_to_mbt_excludes.mjs`:
  - `bevy/crates/bevy_ecs/**`
  - `bevy/crates/bevy_reflect/**`
  - `bevy/crates/bevy_tasks/**`
  - `bevy/examples/{async_tasks,reflection,mobile,no_std,ecs/dynamic}.**`

## Canonical Commands

- Excluding `bevy/target/**`:
  - `scripts/check_bevy_rs_to_mbt_paths.sh`
- Including `bevy/target/**`:
  - `INCLUDE_TARGET=1 scripts/check_bevy_rs_to_mbt_paths.sh`
- Including non-goal scope too (`tasks/reflection/ecs + example non-goals`):
  - `INCLUDE_NON_GOAL=1 scripts/check_bevy_rs_to_mbt_paths.sh`
  - `INCLUDE_TARGET=1 INCLUDE_NON_GOAL=1 scripts/check_bevy_rs_to_mbt_paths.sh`
- Including all explicitly excluded modules too:
  - `INCLUDE_EXCLUDED=1 scripts/check_bevy_rs_to_mbt_paths.sh`
  - `INCLUDE_TARGET=1 INCLUDE_NON_GOAL=1 INCLUDE_EXCLUDED=1 scripts/check_bevy_rs_to_mbt_paths.sh`
- Sync missing mappings:
  - `scripts/sync_bevy_rs_to_mbt_paths.sh`
  - `INCLUDE_TARGET=1 scripts/sync_bevy_rs_to_mbt_paths.sh`
  - `INCLUDE_NON_GOAL=1 scripts/sync_bevy_rs_to_mbt_paths.sh`
  - `INCLUDE_NON_GOAL=1 INCLUDE_EXCLUDED=1 scripts/sync_bevy_rs_to_mbt_paths.sh`

## Current Snapshot (2026-04-09)

- Excluding `bevy/target/**`:
  - `total_rs=1687`
  - `considered_rs=1266`
  - `excluded_rs=421` (`non_goal_ecs=190`, `non_goal_reflect=200`, `non_goal_tasks=14`, `non_goal_example=17`)
  - `missing=0`
  - `collision_count=0`
  - `mod_rule_violation_count=0`
- Including `bevy/target/**`:
  - `total_rs=1718`
  - `considered_rs=1297`
  - `excluded_rs=421` (`non_goal_ecs=190`, `non_goal_reflect=200`, `non_goal_tasks=14`, `non_goal_example=17`)
  - `missing=0`
  - `collision_count=0`
  - `mod_rule_violation_count=0`
- Source-shape scaffold status:
  - `pure_anchor_files=0` (`rg -l "Bevy source-shape anchor\\." mgstudio-engine | wc -l`)
  - `scaffold_files_with_explicit_bevy_source=0/0` (`scripts/check_bevy_rs_to_mbt_paths.sh`, `scaffold_without_bevy_source=0`)
  - `_scaffold_owner marker files=0` (`rg -l "_scaffold_owner" mgstudio-engine | wc -l`)

## Notes

- `examples` are checked in strict same-path mode (`bevy/examples/**.rs -> mgstudio-engine/examples/**.mbt`).
- The checker can also run in non-strict mode internally, but strict mode is the default for audit.
