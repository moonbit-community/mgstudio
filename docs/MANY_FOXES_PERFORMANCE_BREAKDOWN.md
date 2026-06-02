# Many Foxes Performance Breakdown

This document records the current `many_foxes` performance shape on
June 2, 2026. It is a current-checkout snapshot only. It does not reuse the
older May 2026 Bevy comparison numbers, and it does not treat historical
payload/erasure findings as current evidence.

The current result is still CPU-bound on the main thread. The no-trace sample
run measured about `15 FPS`, and the timeline-traced run measured
`14.576 FPS` over steady frames. The dominant work is spread across transform
propagation, render execution, animation target evaluation, skinned mesh bounds,
and skin extraction.

## Measurement Setup

### Current mgstudio timeline profile

Command:

```sh
MGSTUDIO_MANY_FOXES_PROFILE_SECONDS=10 \
MGSTUDIO_MANY_FOXES_START_TIMEOUT_SECONDS=300 \
MGSTUDIO_MANY_FOXES_TRACE_FLUSH_FRAMES=30 \
mgstudio-engine/scripts/profile_many_foxes_breakdown.sh \
  /tmp/mgstudio_many_foxes_current_breakdown
```

Notes:

- The script builds and then runs `moon run examples/stress_tests/many_foxes --release`.
- The first build in this pass was slow because native release linking rebuilt the
  example. The successful profile command waited through that build and launch.
- Timeline tracing is useful for named system spans, but it can add overhead.
  The no-trace `sample` run below is used to confirm the same main-thread shape.

Artifacts:

- Trace: `/tmp/mgstudio_many_foxes_current_breakdown/many_foxes.trace.json`
- Report: `/tmp/mgstudio_many_foxes_current_breakdown/frametime_breakdown.md`
- CSV: `/tmp/mgstudio_many_foxes_current_breakdown/frametime_breakdown.csv`
- Log: `/tmp/mgstudio_many_foxes_current_breakdown/many_foxes.log`

Result:

- `fps_from_interval`: `14.576`
- Average frame interval: `68.605 ms`
- `p50_ms`: `68.342`
- `p90_ms`: `71.983`
- `p95_ms`: `73.159`
- Steady frames: `76`
- Excluded frames: `12`
- Runtime spikes excluded: `1145.044 ms` and `323.134 ms`

### Current mgstudio no-trace sample

Command shape:

```sh
cd mgstudio-engine
./_build/native/release/build/examples/stress_tests/many_foxes/many_foxes.exe
sample <pid> 8 -file /tmp/many_foxes_current_20260602.sample.txt
```

Artifacts:

- Sample: `/tmp/many_foxes_current_20260602.sample.txt`
- Runtime log: `/tmp/many_foxes_sample_run.log`

Result at sampling time:

- `many_foxes fps=15.205333709716797`
- `frame_time=65.76639556884766ms`
- Physical footprint: `731.0M`
- Main-thread samples: `6198`
- `redraw_requested`: `6180` samples
- `run_tick`: `5782` samples
- `SubApps::update`: `3594` samples

### Current count scaling

These runs used the same release executable from the `mgstudio-engine`
directory, so asset-relative paths resolve the same way as normal example
execution. Runs from the repository root are invalid for this measurement
because the relative `models/animated/Fox.glb` path can fail and produce a
lightweight or empty scene.

| Count | FPS | Frame time |
| ---: | ---: | ---: |
| `250` | `42.328` | `23.625 ms` |
| `500` | `27.445` | `36.437 ms` |
| `1000` | `15.411` | `64.891 ms` |

The scaling is not a fixed overhead problem. Frame time grows with fox count,
which points at per-entity and per-joint CPU work.

## Summary Table

| Area | Current avg ms/frame | Evidence | Status |
| --- | ---: | --- | --- |
| Transform propagation | `11.677` | top system and `transform_propagate_dense=11.672` | Current hot path |
| Render execution | `11.310` | render system and `execute_3d=11.309` | Current hot path |
| Animation target evaluation | `8.793` | `mgstudio.animation.animate_targets` | Current hot path |
| Skinned mesh bounds | `8.587` | `mgstudio.visibility.update_skinned_mesh_bounds` | Current hot path |
| Skin extraction | `5.652` system / `5.619` render queue | extract commands and `extract_3d_skins` | Current hot path |
| Winit/redraw handling | `3.364` | top system `winit/lib.mbt:105` | Needs naming cleanup before assigning cause |
| Mesh preparation | `3.096` | `mgstudio.render.prepare_meshes` | Current render-side cost |
| Previous transform sync | `0.998` | `pbr/mesh_material.mbt:101` pre-update system | Smaller but always-on cost |
| Cluster assignment | `0.332` | `light/cluster/assign.mbt` | No longer a top blocker in this run |

## Current Frame Breakdown

### Stage totals

| Stage | avg ms/frame | count/frame |
| --- | ---: | ---: |
| `Main` | `40.293` | `1.00` |
| `PostUpdate` | `32.750` | `1.00` |
| `Custom("mgstudio.render")` | `23.714` | `1.00` |
| `PreUpdate` | `5.957` | `1.00` |
| `Update` | `1.177` | `1.00` |

The stage totals overlap because the timeline records nested spans. They are
useful for ownership, not additive frame accounting.

### Top systems

| System | avg ms/frame |
| --- | ---: |
| `mgstudio.transform.propagate_parent_transforms_system` | `11.677` |
| `mgstudio.render.render` | `11.310` |
| `mgstudio.animation.animate_targets` | `8.793` |
| `mgstudio.visibility.update_skinned_mesh_bounds` | `8.587` |
| `mgstudio.render.extract_commands` | `5.652` |
| `winit/lib.mbt:105` | `3.364` |
| `mgstudio.render.prepare_meshes` | `3.096` |
| `mgstudio.animation.trigger_untargeted_events` | `1.522` |
| `mgstudio.render.prepare_resources_flush` | `1.262` |
| `mgstudio.render.prepare_resources` | `1.154` |
| `pbr/mesh_material.mbt:101` | `0.998` |

### Render queue

| Span | avg ms/frame |
| --- | ---: |
| `transform_propagate_dense` | `11.672` |
| `transform_propagate_descendants` | `11.629` |
| `execute_3d` | `11.309` |
| `execute_3d_render_cameras` | `11.301` |
| `extract_3d_skins` | `5.619` |
| `execute_3d_collect_meshes` | `2.559` |
| `prepare_3d_camera_queue_upload` | `1.260` |
| `execute_3d_camera_main_pass` | `0.944` |
| `queue_3d` | `0.633` |
| `prepare_3d_camera_queue_build` | `0.622` |
| `prepare_3d_camera_queue_entry` | `0.609` |

### Render pass

| Span | avg ms/frame | count/frame |
| --- | ---: | ---: |
| `pass_3d(kind=3843)` | `7.806` | `4.00` |
| `pass_3d(kind=2816)` | `0.864` | `1.00` |

## Observed Hot Paths And Candidate Causes

### 1. Transform propagation

mgstudio source:

- `mgstudio-engine/transform/systems.mbt`, `propagate_parent_transforms_dense`,
  lines 556-638.
- `propagate_descendants_dense` is the inner traversal called from that path.

Current evidence:

- Timeline: `11.677 ms/frame`.
- Render queue spans: `transform_propagate_dense=11.672 ms/frame`,
  `transform_propagate_descendants=11.629 ms/frame`.
- macOS sample: `propagate_parent_transforms_system` accounts for `992 / 6198`
  main-thread samples.
- The sample shows the root scan in
  `ComponentColumn::for_each_without_fast<Children, Parent>`, then repeated
  `ComponentTableColumn` and `TypedComponentStorage::get_table_row` lookups for
  `Transform`, `GlobalTransform`, `Parent`, and `Children`.

Candidate causes:

- The transform traversal is still dominated by generic component-column and
  table-row lookup overhead in the inner loop.
- The current dense path resolves table storage repeatedly while walking
  children. It is not yet a Bevy-shaped node-query cursor with precomputed fetch
  state.
- Animation writes many `Transform` rows every frame, which forces transform
  propagation to revisit a large hierarchy.

Required evidence before calling this a root cause:

- Add current counters for roots scanned, descendants visited, table-row lookups,
  and `GlobalTransform` writes.
- Split changed-tree detection from descendant propagation so root scan cost and
  child traversal cost are not conflated.
- Compare against a current Bevy run only after collecting the same counters
  there.

Candidate alignment target:

- Build a transform-specific typed node fetch path equivalent to Bevy's
  transform node query.
- Keep cached child table-row locations valid during hierarchy maintenance.
- Avoid marking unchanged `GlobalTransform` rows changed when the computed value
  is identical.

### 2. Render execution

mgstudio source:

- `mgstudio-engine/pbr/mesh_material.mbt`, render app setup.
- `mgstudio-engine/pbr/render_shadow_phase.mbt`,
  `render3d_prewarm_shadow_material_pipeline`, lines 249-312.
- `mgstudio-engine/pbr/render_execute_previous_data_sync.mbt`,
  `update_mesh_previous_global_transforms`, lines 102-160.

Current evidence:

- Timeline: `mgstudio.render.render=11.310 ms/frame`.
- Render queue: `execute_3d=11.309 ms/frame`,
  `execute_3d_render_cameras=11.301 ms/frame`,
  `execute_3d_collect_meshes=2.559 ms/frame`.
- Render pass spans: four `pass_3d(kind=3843)` passes cost
  `7.806 ms/frame` total, plus one `pass_3d(kind=2816)` at `0.864 ms/frame`.
- macOS sample still shows `render3d_execute_collect_meshes` and
  `render3d_prewarm_shadow_material_pipeline` in the hot symbol list, but GPU
  buffer writes are not the dominant sample count.

Candidate causes:

- Render execution still mixes CPU collection, draw payload construction,
  material/pipeline lookup, GPU command encoding, and pass timing in broad
  spans.
- Shadow material pipeline prewarm is called from the per-item shadow phase
  execution loop. Even when caches hit, this path rebuilds render-mesh layout
  state and checks specialization state in a hot loop.
- Previous transform sync writes all existing `PreviousGlobalTransform`
  components every frame when prepass is enabled. This is smaller than the top
  systems, but it contributes steady write pressure.

Required evidence before calling this a root cause:

- Split `execute_3d` into CPU collection, shadow phase construction, main pass
  construction, pipeline lookup, command encoding, submission, and present/wait
  spans.
- Add counters for shadow phase items, main pass draw items, pipeline-cache
  hits, descriptor registrations, and `PreviousGlobalTransform` writes.
- Re-run with shadows disabled only as a diagnostic probe, then remove the probe.

Candidate alignment target:

- Move pipeline prewarm/specialization out of per-item pass execution where
  possible.
- Make previous-transform sync dirty-driven or otherwise source-equivalent to
  the upstream ownership model.
- Separate CPU render-queue costs from GPU/pass/wait costs in the trace.

### 3. Animation target evaluation

mgstudio source:

- `mgstudio-engine/animation/lib.mbt`, `animate_targets`, lines 2051-2295.

Current evidence:

- Timeline: `8.793 ms/frame`.
- macOS sample: `animate_targets` accounts for `808 / 6198` main-thread
  samples.
- The sample shows the target loop inside
  `ComponentColumn::for_each3_fast_table_row_mark_third_changed`.
- The inner `process_target` path accounts for `486` samples in the sampled
  call tree.

Candidate causes:

- The system builds a per-player prepared cache every frame before walking
  targets.
- Target mutation still goes through custom column loops and explicit changed
  marking. It is typed now, but it is not yet equivalent to Bevy's direct target
  entity mutation shape.
- The animation output writes `Transform` every frame for many targets, which
  creates downstream transform propagation and previous-transform sync pressure.

Required evidence before calling this a root cause:

- Split `animate_targets` into player preparation, target query iteration,
  curve sampling, target writes, and event emission spans.
- Count targets processed, players prepared, transform writes, morph weight
  writes, and text color writes.
- Measure the effect of pausing animation in the same executable, using input or
  a temporary diagnostic probe that is removed afterwards.

Candidate alignment target:

- Replace broad per-frame player-cache reconstruction with direct player lookup
  where possible.
- Add a target-entity mutation path that matches Bevy's ownership model more
  closely.
- Make unchanged target writes avoid downstream dirty work.

### 4. Skinned mesh bounds

mgstudio source:

- `mgstudio-engine/camera/primitives/top.mbt`,
  `update_skinned_mesh_bounds_system`, lines 174-244.
- `mgstudio-engine/mesh/skinning.mbt`,
  `entity_aabb_from_skinned_mesh_bounds_with_fetch`, lines 410-474.

Current evidence:

- Timeline: `8.587 ms/frame`.
- The bounds system scans `Mesh3d + SkinnedMesh + DynamicSkinnedMeshBounds +
  Aabb`.
- Each entity calls `entity_aabb_from_skinned_mesh_bounds_cached`, which then
  walks the mesh's skinned bounds and fetches joint global transforms.
- macOS sample keeps `entity_aabb_from_skinned_mesh_bounds_with_fetch` visible
  in the top symbol list.

Candidate causes:

- Dynamic skinned bounds are recalculated every frame for every skinned fox.
- Per-joint global transform lookup remains expensive at this scale even with
  cached joint row helpers.
- The bounds path and skin extraction path both need joint transforms, so the
  workload repeats across systems.

Required evidence before calling this a root cause:

- Add counters for skinned entities processed, joint bounds processed, joint
  global transform cache hits/misses, and AABB writes.
- Measure static or disabled dynamic bounds as a diagnostic probe only, then
  remove the probe.
- Compare bounds cost with and without animation paused.

Candidate alignment target:

- Keep joint table-row caches current and use them as the primary fetch path.
- Avoid recalculating unchanged bounds when the relevant joint transforms did
  not change.
- Share or reuse joint transform fetch state between skin extraction and bounds
  where this can be done without changing semantics.

### 5. Skin extraction

mgstudio source:

- `mgstudio-engine/pbr/render/skin.mbt`, skin add/delete, joint extraction, and
  skin binding upload paths.

Current evidence:

- Timeline: `mgstudio.render.extract_commands=5.652 ms/frame`.
- Render queue: `extract_3d_skins=5.619 ms/frame`.
- macOS sample shows `render3d_extract_joints_for_skin` in the top symbol list.

Candidate causes:

- The render extraction path walks many joints and writes staging data every
  frame for animated skins.
- Dirty-skin collection and joint extraction still carry custom metadata and
  fallback paths that are not obviously source-equivalent to Bevy.
- The skin extraction path duplicates some joint access pressure already present
  in dynamic bounds.

Required evidence before calling this a root cause:

- Split extraction into add/delete, dirty-skin collection, joint extraction,
  staging writes, and upload preparation.
- Count skins, joints, dirty skins, staging rows, and upload bytes.
- Verify whether any per-frame metadata repair path is firing after scene load.

Candidate alignment target:

- Make dirty-skin threshold and dirty-skin collection source-equivalent to Bevy.
- Use direct staging-buffer indexing semantics for joint matrices.
- Remove fallback repair paths from the hot loop once ECS and skin metadata
  invariants are strong enough.

## Current Priority Order

1. Transform propagation and animation target writes. These two amplify each
   other: animation marks many transforms changed, then transform propagation
   pays the hierarchy traversal cost.
2. Skinned mesh bounds and skin extraction. These both depend on joint transform
   access and are amplified by fox count.
3. Render execution. Split CPU queue/pipeline work from GPU/pass timing before
   making architecture changes.
4. Previous transform sync. It is smaller than the top systems, but it is a
   steady per-frame write path and may amplify change tracking.
5. Cluster assignment. It is no longer a top cost in this current snapshot.

## Validation Requirements For Future Fixes

For performance changes, collect both timeline and no-trace evidence:

```sh
MGSTUDIO_MANY_FOXES_PROFILE_SECONDS=10 \
MGSTUDIO_MANY_FOXES_START_TIMEOUT_SECONDS=300 \
MGSTUDIO_MANY_FOXES_TRACE_FLUSH_FRAMES=30 \
mgstudio-engine/scripts/profile_many_foxes_breakdown.sh \
  /tmp/mgstudio_many_foxes_after
```

```sh
cd mgstudio-engine
./_build/native/release/build/examples/stress_tests/many_foxes/many_foxes.exe
sample <pid> 8 -file /tmp/many_foxes_after.sample.txt
```

Also record count scaling from the `mgstudio-engine` working directory:

```sh
./_build/native/release/build/examples/stress_tests/many_foxes/many_foxes.exe --count=250
./_build/native/release/build/examples/stress_tests/many_foxes/many_foxes.exe --count=500
./_build/native/release/build/examples/stress_tests/many_foxes/many_foxes.exe
```

For ECS, transform, animation, mesh, or PBR changes, run the relevant targeted
package tests with `--release` when native tcc linkage is not sufficient:

```sh
moon -C mgstudio-engine check --target native
moon -C mgstudio-engine test transform --release
moon -C mgstudio-engine test animation --release
moon -C mgstudio-engine test mesh --release
moon -C mgstudio-engine test pbr/render --release
```
