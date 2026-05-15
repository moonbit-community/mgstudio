# Many Foxes Performance Breakdown

This document records the May 12, 2026 `many_foxes` profiling comparison
between `mgstudio` and the local Bevy 0.19.0-dev checkout, then maps the
measured gaps back to source-level divergences that still need evidence before
they are treated as root causes.

Per the project glossary, any comparable runtime path slower than Bevy by more
than `4x` is a severe performance gap. This document does not attempt to fix
those gaps. It records observed gaps, source-level candidate causes, and the
specific evidence still required to promote a candidate cause to an
evidence-based parity cause.

## Measurement Setup

### mgstudio

Command:

```sh
MGSTUDIO_MANY_FOXES_PROFILE_SECONDS=10 \
MGSTUDIO_MANY_FOXES_START_TIMEOUT_SECONDS=300 \
mgstudio-engine/scripts/profile_many_foxes_breakdown.sh \
  /tmp/mgstudio_many_foxes_breakdown_compare
```

Artifacts:

- Trace: `/tmp/mgstudio_many_foxes_breakdown_compare/many_foxes.trace.json`
- Report: `/tmp/mgstudio_many_foxes_breakdown_compare/frametime_breakdown.md`
- CSV: `/tmp/mgstudio_many_foxes_breakdown_compare/frametime_breakdown.csv`

Result:

- `fps_from_interval`: `11.048`
- Average main frame span: `90.515 ms`
- Steady frames: `76`

### Bevy

Command:

```sh
RUST_LOG='info,wgpu=error,naga=error,cosmic_text=warn' \
TRACE_CHROME=/tmp/bevy_many_foxes_breakdown_compare/many_foxes_trace_debug.json \
cargo run --manifest-path bevy/Cargo.toml \
  --release \
  --no-default-features \
  --features "default_app,3d_bevy_render,bevy_winit,default_font,trace_chrome,debug" \
  --example many_foxes -- --count 1000
```

Notes:

- `multi_threaded` was intentionally not enabled.
- `debug` was enabled so release traces include system names. This adds some
  diagnostic overhead, so the Bevy numbers are conservative for system spans.
- A temporary local `AppExit` system was added to the Bevy example to make
  `tracing-chrome` flush after 240 frames. The patch was reverted after the
  trace was captured.

Artifacts:

- Trace: `/tmp/bevy_many_foxes_breakdown_compare/many_foxes_trace_debug.json`
- Report: `/tmp/bevy_many_foxes_breakdown_compare/bevy_frametime_breakdown.md`
- CSV: `/tmp/bevy_many_foxes_breakdown_compare/bevy_frametime_breakdown.csv`

Result:

- `fps_from_update_interval`: `59.997`
- Average `update` span: `16.524 ms`
- Steady frames: `180`

## Summary Table

| Area | mgstudio avg ms/frame | Bevy single-thread avg ms/frame | Ratio | Status |
| --- | ---: | ---: | ---: | --- |
| Animation target evaluation | `14.594` | `3.451` | `4.2x` | Severe gap; candidate causes only |
| Transform propagation | `11.397` | `0.763` | `14.9x` | Severe gap; candidate causes only |
| Skinned mesh bounds | `8.429` | `0.118` | `71.4x` | Severe gap; candidate causes only |
| Skin extraction/prepare | `5.448` extract only | `0.146 + 0.200` | `15.7x` | Severe gap; candidate causes only |
| Cluster assignment | `0.463` | `0.015` | `30.9x` | Severe gap; needs a dedicated source breakdown |
| Main render execution span | `23.827` | `0.784` render system plus external waits | not directly comparable | Measurement boundaries differ |

The gap is not primarily explained by Bevy's multi-threaded executor. Bevy was
measured without `multi_threaded`, and the largest `mgstudio` CPU systems are
still one to two orders of magnitude slower than their Bevy counterparts.

## Observed Gaps And Candidate Causes

### 1. Animation target evaluation

mgstudio source:

- `mgstudio-engine/animation/lib.mbt`, `animate_targets`, lines 1706-1890.
- The system first builds a per-player cache by querying every
  `(AnimationPlayer, AnimationGraphHandle)` pair.
- It then scans `AnimatedBy + AnimationTargetId` table rows and calls
  `animation_apply_threaded_player_to_target`.
- Component writes use table-row hot writes when possible, but the evaluation
  still passes through `EcsPayloadCodec` decode/encode and dynamic component
  column APIs.

Bevy source:

- `bevy/crates/bevy_animation/src/lib.rs`, `animate_targets`, lines 1029-1080.
- The target query directly yields
  `(Entity, &AnimationTargetId, &AnimatedBy, AnimationEntityMut)`.
- It fetches the player with `players.get(player_id)`, reads
  `Assets<AnimationGraph>` and `ThreadedAnimationGraphs` directly, then mutates
  the target entity through `EntityMutExcept`.
- It uses `Local<ThreadLocal<RefCell<AnimationEvaluationState>>>`, which avoids
  a shared global scratch object and avoids rebuilding broad per-player caches
  as the primary access path.

Observed gap:

- `mgstudio` is `4.2x` slower than Bevy in this measured system, which crosses
  the severe-gap threshold.

Candidate causes:

- mgstudio performs an extra player-cache construction pass every frame.
- mgstudio target mutation goes through erased component columns and payload
  conversion instead of Bevy's typed query fetch and direct `EntityMutExcept`
  access.
- mgstudio still does manual optional writes for transform, morph weights, and
  text color. Bevy's target entity mutator is structured around typed component
  access and does not need fallback `world.set_by_key` staging.

Required evidence before calling this a root cause:

- Add trace spans or counters separating mgstudio player-cache construction,
  target scan, and target mutation cost.
- Add Bevy-side comparable spans for player lookup, target query iteration, and
  target mutation inside `animate_targets`.
- Confirm allocation/copy counts or payload encode/decode counts for the
  mgstudio target mutation path.

Candidate alignment target:

- Replace the two-pass player-cache path with a Bevy-like target query that can
  fetch the referenced player directly by entity.
- Add a typed `EntityMutExcept`-style fast path for animation targets so writes
  do not round-trip through generic component columns.
- Keep the threaded graph cache, but make it a direct resource lookup rather
  than a per-frame scratch cache reconstruction when possible.

### 2. Transform propagation

mgstudio source:

- `mgstudio-engine/transform/systems.mbt`, `mark_dirty_trees`, lines 250-359.
- `propagate_parent_transforms_dense`, lines 476-552.
- `propagate_descendants_dense`, lines 401-473.
- The dense path scans roots with
  `columns.children.for_each_without_fast(parent_column, ...)`.
- For every visited entity, it resolves `(table_id, row_index)` through
  `transform_dense_entity_slot`, decodes `Transform`, decodes `Parent`, writes
  `GlobalTransform`, and decodes `Children`.

Bevy source:

- `bevy/crates/bevy_transform/src/systems.rs`, `mark_dirty_trees`, lines
  109-151.
- The measured single-thread run still used Bevy's `std` implementation,
  `propagate_parent_transforms`, lines 352-427, but with a one-thread task pool.
- `propagate_descendants_unchecked`, lines 525-595, uses a `NodeQuery` over
  `(Ref<Transform>, Mut<GlobalTransform>, Ref<TransformTreeChanged>)` and
  `(Option<Read<Children>>, Read<ChildOf>)`.
- The hot traversal uses `iter_many_unique_unsafe` over the `Children` slice and
  updates `GlobalTransform` through a typed `Mut`.

Observed gap:

- `mgstudio` is `14.9x` slower than Bevy in transform propagation, which crosses
  the severe-gap threshold.

Candidate causes:

- mgstudio re-enters generic `ComponentColumn` APIs for each child. Bevy's
  `NodeQuery` batches component fetch state and then fetches children through
  a typed query path.
- mgstudio decodes `Parent` and `Children` values per row through the erased
  column layer. Bevy traverses borrowed typed components and does not allocate
  or convert payloads in the inner loop.
- Bevy uses `set_if_neq` for `GlobalTransform` in the descendant path. mgstudio
  currently writes `GlobalTransform` on every visited dirty subtree node through
  `set_sequence_only_hot_at_table_row_value`, which always performs a payload
  replacement when the node is visited.
- Bevy's traversal follows the actual `Children` slice with
  `iter_many_unique_unsafe`, avoiding entity-to-table lookup inside the common
  child fetch path. mgstudio still calls `transform_dense_entity_slot` per child.

Required evidence before calling this a root cause:

- Add mgstudio counters for child visits, `transform_dense_entity_slot` calls,
  component-column decodes, and unchanged `GlobalTransform` rewrites.
- Add Bevy-side counters or trace spans for root scans, descendant fetches, and
  `set_if_neq` writes in the same scene.
- Run an A/B measurement with only the `GlobalTransform` unchanged-write behavior
  isolated, so lookup overhead and write amplification are not conflated.

Candidate alignment target:

- Build a transform-specific typed node fetch equivalent to Bevy's `NodeQuery`.
- Store per-child table row locations in hierarchy maintenance, or add a
  `Children`-driven batch fetch that resolves all children in one cursor.
- Add `GlobalTransform::set_if_neq` semantics to avoid marking unchanged global
  transforms as changed.
- Keep the single-thread traversal, but make its inner loop source-level close
  to Bevy's `propagate_descendants_unchecked`.

### 3. Skinned mesh bounds

mgstudio source:

- `mgstudio-engine/camera/primitives/top.mbt`,
  `update_skinned_mesh_bounds_system`, lines 174-244.
- `mgstudio-engine/mesh/skinning.mbt`,
  `entity_aabb_from_skinned_mesh_bounds`, lines 410-474.
- The system now uses a marker-only table-row cursor over
  `Mesh3d + SkinnedMesh + DynamicSkinnedMeshBounds + Aabb`, but each skin still
  calls `entity_aabb_from_skinned_mesh_bounds`.
- That function fetches each joint transform via
  `joint_transforms.get_fast(joint_entity)` for every joint.

Bevy source:

- `bevy/crates/bevy_camera/src/visibility/mod.rs`,
  `update_skinned_mesh_bounds`, lines 515-540.
- `bevy/crates/bevy_mesh/src/skinning.rs`,
  `entity_aabb_from_skinned_mesh_bounds`, lines 188-244.
- Bevy's query directly yields `(&mut Aabb, &Mesh3d, &SkinnedMesh,
  Option<&GlobalTransform>)` with `With<DynamicSkinnedMeshBounds>`, and joint
  transforms are read through a typed `Query<&GlobalTransform>`.

Observed gap:

- `mgstudio` is `71.4x` slower than Bevy in skinned mesh bounds, which crosses
  the severe-gap threshold.

Candidate causes:

- mgstudio still performs a per-joint entity lookup through
  `ComponentColumn::get_fast`. Many foxes have many joints, so this amplifies
  the erased-column cost heavily.
- Bevy's query fetch state is precomputed and typed. The joint query is still an
  entity lookup, but it uses ECS table/sparse metadata without payload
  conversion.
- mgstudio's `SkinnedMesh`/inverse bindpose/joint arrays are MoonBit values
  copied or decoded from the payload layer at the system boundary; Bevy borrows
  them directly.
- mgstudio's bounds update and skin extraction both independently refetch many
  of the same joint transforms. Bevy also has two paths, but each path is typed
  and cheaper; the duplicated work is not as visible.

Required evidence before calling this a root cause:

- Add mgstudio counters for skins processed, joints processed, joint transform
  lookups, payload decodes, and inverse-bindpose accesses.
- Add Bevy-side counters for the same skin and joint counts under the same
  `many_foxes` count.
- Measure whether replacing only the joint transform lookup path changes the
  gap, without changing bounds math or scheduling.

Candidate alignment target:

- Add a typed `Query<&GlobalTransform>`-style fast lookup for joint entities.
- Cache joint `(table_id, row_index)` in `SkinnedMesh` or skin runtime metadata
  only when the mapping is updated, then use table-row fetches in the bounds
  path.
- Avoid decoding `SkinnedMesh` and inverse bindpose values repeatedly when the
  entity/asset did not change.

### 4. Skin extraction and prepare

mgstudio source:

- `mgstudio-engine/pbr/render/skin.mbt`,
  `render3d_add_skin`, lines 467-565.
- `render3d_add_or_delete_skins`, lines 568-615.
- `render3d_extract_joints_for_skin`, lines 618-699.
- `render3d_extract_joints`, lines 702-802.
- `render3d_extract_skin_bindings`, lines 805-843.
- `render3d_prepare_skin_bindings_upload`, lines 846-860.

Bevy source:

- `bevy/crates/bevy_pbr/src/render/skin.rs`,
  `prepare_skins`, lines 200-268.
- `extract_skins`, lines 296-345.
- `add_or_delete_skins`, lines 349-385.
- `extract_joints`, lines 389-455.
- `extract_joints_for_skin`, lines 459-505.
- `add_skin`, lines 508-580.
- `remove_skin`, lines 583-607.

Observed gap:

- `mgstudio` is `15.7x` slower than Bevy in the measured skin
  extraction/prepare path, which crosses the severe-gap threshold.

Candidate causes:

- mgstudio tracks `joint_to_skins` as `Map[UInt64, Array[Entity]]`. Bevy uses a
  `MainEntityHashMap` / `MainEntityHashSet` style keyed by entity without
  converting through `UInt64` on every hot lookup.
- mgstudio has an additional `Render3dWorldTransformCache` and
  `joint_table_ids`/`joint_row_indices` repair path. This helps some lookups,
  but it also adds fallback branches and additional metadata maintenance.
- Bevy's `extract_joints` uses the exact simple threshold check:
  `changed_transforms.iter().nth(threshold).is_some()`. mgstudio counts changed
  rows through `for_each_changed_table_entity` and builds a `Map` of dirty
  skins while checking the threshold.
- Bevy writes `current_staging_buffer[offset + joint_index] = joint_matrix`
  directly. mgstudio goes through helper functions and stores staging data in a
  row-oriented host buffer layout consumed by the compatibility GPU bridge.
- Bevy's `prepare_skins` swaps current/previous GPU buffers and writes only the
  current staging buffer. mgstudio delegates to
  `host_gpu_prepare_mesh3d_skin_bindings`, so the actual upload semantics and
  buffering are not yet source-level identical.

Required evidence before calling this a root cause:

- Add trace spans around mgstudio skin add/delete, dirty-skin collection, joint
  extraction, staging buffer writes, and host upload separately.
- Add Bevy-side spans around `extract_skins`, `add_or_delete_skins`,
  `extract_joints`, and `prepare_skins` for the same workload.
- Record key conversion counts, dirty-skin set sizes, and staging buffer write
  counts for both engines.

Candidate alignment target:

- Replace `UInt64` skin keys and `Map[UInt64, Array[Entity]]` with a typed
  entity-key map/set matching Bevy's `MainEntityHashMap` usage.
- Remove the world-transform cache from the hot path once typed table-row joint
  lookup is available.
- Make the threshold and dirty-skin collection logic source-level equivalent to
  Bevy's `extract_joints`.
- Move the CPU staging buffer to direct matrix indexing semantics so
  `prepare_skins` can be migrated closer to Bevy's buffer swap/write model.

### 5. Render queue / render execution

mgstudio source:

- `mgstudio-engine/pbr/mesh_material.mbt`, render sub-app setup, lines 170-244.
- The render app runs explicit systems for extract, prepare morphs, prepare
  skins, prepare resources, prepare meshes, prepare bind groups, queue meshes,
  queue sweep, and execute.

Bevy source:

- `bevy/crates/bevy_pbr/src/render/mesh.rs`,
  `set_mesh_motion_vector_flags`, lines 1735-1762, and
  `collect_meshes_for_gpu_building`, lines 1775 onward.
- `bevy/crates/bevy_render/src/renderer/mod.rs`, `render_system`, lines 43-75.
- `bevy/crates/bevy_pbr/src/material.rs`, `queue_material_meshes`, starts at
  line 1171.

Observed gap:

- The `render_system` number is not directly comparable. Bevy's Chrome trace
  shows `bevy_render::view::window::prepare_windows` around `8.1 ms`, which is
  likely dominated by surface/window synchronization or driver waiting. mgstudio
  reports large `pass_3d` and `execute_3d` spans, but those spans may include
  different CPU/GPU wait boundaries.
- The CPU-side mesh/material systems are still meaningfully different. Bevy
  defers skin and morph flags so `queue_material_meshes` does not probe skin and
  morph tables in the hot mesh queue loop. The source comment in
  `bevy_pbr/src/render/mesh.rs` explicitly says checking skin/morph tables in
  the hot loop would be too slow.
- mgstudio still has a broad render sub-app sequence where skin extraction,
  mesh preparation, resource flush, queue, and execute are independent
  MoonBit-level systems. Several of these systems are measured at more than
  `1 ms` each in `many_foxes`.

Candidate causes:

- CPU queue costs and GPU submission or driver wait costs are not separated in
  the current mgstudio trace.
- mgstudio still appears to perform more MoonBit-level staging across extract,
  prepare, queue, and execute than Bevy's hot render systems.
- Skin and morph flags may still be consulted later in the mesh/material queue
  path than Bevy's design intends.

Required evidence before calling this a root cause:

- Split mgstudio render timings into CPU queue construction, GPU command
  encoding, queue submission, and wait/surface synchronization spans.
- Compare those spans with Bevy `queue_material_meshes`, `render_system`, and
  window/surface preparation spans under the same example and frame window.
- Add counters for queued meshes, material phase items, pipeline-cache hits,
  bind-group builds, and GPU submissions in both engines.

Candidate alignment target:

- Audit `queue_meshes`, `prepare_meshes`, and `extract_commands` against
  Bevy's `extract_meshes_for_gpu_building`, `collect_meshes_for_gpu_building`,
  and `queue_material_meshes`.
- Ensure skin/morph flags are precomputed outside the hot material queue loop,
  matching Bevy's `set_mesh_motion_vector_flags` design.
- Split CPU queue costs from GPU submission/wait costs in mgstudio trace so
  render-pass timing can be compared fairly.

## Priority Order

1. Skinned mesh bounds and skin extraction. These are the largest observed
   severe gaps and are heavily amplified by many foxes.
2. Transform propagation. The single-thread Bevy implementation is still about
   fifteen times faster, so mgstudio needs a typed node-query inner loop.
3. Animation target evaluation. Replace per-frame cache reconstruction and
   erased writes with direct typed target mutation.
4. Cluster assignment. It crosses the severe-gap threshold but still needs a
   dedicated mgstudio-versus-Bevy source breakdown before assigning causes.
5. Mesh/material queue and render execution. First separate CPU queue work from
   driver/GPU waits, then migrate the hot CPU queue loops to Bevy's layout.

## Validation Requirements For Future Fixes

Every optimization must be validated with both:

```sh
MGSTUDIO_MANY_FOXES_PROFILE_SECONDS=10 \
MGSTUDIO_MANY_FOXES_START_TIMEOUT_SECONDS=300 \
mgstudio-engine/scripts/profile_many_foxes_breakdown.sh \
  /tmp/mgstudio_many_foxes_breakdown_after
```

and the relevant package tests. For ECS/transform/skin work, at minimum:

```sh
moon -C mgstudio-engine check
moon -C mgstudio-engine test ecs
moon -C mgstudio-engine test transform
moon -C mgstudio-engine test mesh
moon -C mgstudio-engine test pbr/render
```

The `animation` package currently has a known native test linker issue
(`tcc: error: file 'Metal' not found`), so `moon test animation` only becomes a
required gate after that linker issue is resolved.
