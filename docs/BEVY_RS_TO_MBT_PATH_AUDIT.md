# Bevy RS -> MBT Path Audit

## Canonical Rule

- Every `bevy/crates/bevy_*/src/**/*.rs` and `bevy/examples/**/*.rs` has a corresponding `mgstudio-engine/**/*.mbt`.
- `mod.rs` is always mapped to `top.mbt`.
- `bevy_workspace` mirror is removed and out of scope.
- Default audit excludes are centralized in `scripts/bevy_rs_to_mbt_excludes.mjs`:
  - `bevy/crates/bevy_ecs/**`
  - `bevy/crates/bevy_reflect/**`
  - `bevy/crates/bevy_tasks/**`
  - `bevy/crates/bevy_remote/**` (scope removed)
  - `bevy/crates/bevy_solari/**` (scope removed)
  - `bevy/examples/{async_tasks,reflection,mobile,no_std,ecs/dynamic}.**`

## Canonical Commands

- Canonical:
  - `scripts/check_bevy_rs_to_mbt_paths.sh`
- Including non-goal scope too (`tasks/reflection/ecs + example non-goals`):
  - `INCLUDE_NON_GOAL=1 scripts/check_bevy_rs_to_mbt_paths.sh`
- Including all explicitly excluded modules too:
  - `INCLUDE_EXCLUDED=1 scripts/check_bevy_rs_to_mbt_paths.sh`
  - `INCLUDE_NON_GOAL=1 INCLUDE_EXCLUDED=1 scripts/check_bevy_rs_to_mbt_paths.sh`
- Sync missing mappings:
  - `scripts/sync_bevy_rs_to_mbt_paths.sh`
  - `INCLUDE_NON_GOAL=1 scripts/sync_bevy_rs_to_mbt_paths.sh`
  - `INCLUDE_NON_GOAL=1 INCLUDE_EXCLUDED=1 scripts/sync_bevy_rs_to_mbt_paths.sh`

## Current Snapshot (2026-04-12)

- Canonical run:
  - `total_rs=1423`
  - `considered_rs=1031`
  - `excluded_rs=392` (`non_goal_ecs=151`, `non_goal_reflect=143`, `non_goal_tasks=12`, `non_goal_platform=27`, `non_goal_macro=16`, `non_goal_dynamic_scene=3`, `scope_removed_remote=6`, `scope_removed_solari=14`, `non_goal_example=20`)
  - `missing=0`
  - `collision_count=0`
  - `mod_rule_violation_count=0`
- Source-shape scaffold status:
  - `pure_anchor_files=0` (`rg -l "Bevy source-shape anchor\\." mgstudio-engine | wc -l`)
  - `scaffold_files_with_explicit_bevy_source=0/0` (`scripts/check_bevy_rs_to_mbt_paths.sh`, `scaffold_without_bevy_source=0`)
  - `_scaffold_owner marker files=0` (`rg -l "_scaffold_owner" mgstudio-engine | wc -l`)

## Notes

- `examples` are checked in strict package-path mode (`bevy/examples/**.rs -> mgstudio-engine/examples/**/main.mbt`).
- The checker can also run in non-strict mode internally, but strict mode is the default for audit.
