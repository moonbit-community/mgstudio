# Render Parity Issue Tracker

Last updated: 2026-04-14

## Status Legend

- `TODO`: not started
- `IN_PROGRESS`: currently being fixed
- `BLOCKED`: blocked by platform/public API limitations or external dependency constraints
- `DONE`: fixed and verified locally

## Issues

| ID | Source | Problem | Status | Notes |
| --- | --- | --- | --- | --- |
| RENDER-001 | bevy_pbr/render/skin.rs + mesh.rs | `render3d.prepare` still does skin extraction work instead of extract/prepare split. | DONE | 2026-04-07: `pbr/render3d.mbt` now does skin matrix extraction in extract stage and upload-only in prepare stage; trace check (`/tmp/mgstudio_stress_profile_render_parity/traces/many_foxes.trace.json`) shows `mgstudio.render3d.prepare#3` avg ~`4.863ms` (was ~`56.7ms`). |
| RENDER-002 | bevy_pbr/render/skin.rs | Skin extraction is full-scan every frame; missing changed-joint driven dirty skin extraction path. | DONE | 2026-04-07: added `joint -> skins` reverse mapping + per-skin registration/removal + `Changed<GlobalTransform>` dirty extraction with Bevy-style threshold fallback in `pbr/render3d.mbt`. |
| RENDER-003 | bevy_pbr/render/skin.rs | Skin uniforms use per-skin slot cache, not Bevy-style global allocator + current/prev double buffers. | IN_PROGRESS | 2026-04-12: switched skin binding keys from entity-id binding to global slot allocator with reuse/free-list in `pbr/render/skin.mbt`; 2026-04-14: fixed upload traversal to skip invalid skin keys instead of aborting the whole upload pass (locked by `pbr/render/skin_wbtest.mbt`); remaining work is Bevy-like current/previous skin uniform double-buffer path. |
| RENDER-004 | bevy_pbr/render/mesh.rs | Mesh extract path is not changed/removed incremental at Bevy granularity. | TODO | Align with `extract_meshes_for_gpu_building` query + removed-components reextract logic. |
| RENDER-005 | bevy_pbr/render/mesh.rs | Missing dedicated `set_mesh_motion_vector_flags` stage after skin/morph extraction. | IN_PROGRESS | 2026-04-12: extracted motion-vector requirement detection into `render3d_set_mesh_motion_vector_flags` in PrepareMeshes; remaining work is to converge from current global-flag behavior to Bevy-like per-mesh flag/writeback flow. |
| RENDER-006 | bevy_pbr/render/mesh.rs + mesh_bindings.rs | Mesh bind-group prep still partially deferred to draw/execute paths. | IN_PROGRESS | 2026-04-13: `motion_vector_mesh_bind_group` creation moved out of draw path (`mesh3d_draw_motion_vector_pass`) into preprocess payload upload (`upload_mesh3d_preprocess_camera_payload`); 2026-04-14: main-pass view bind-group creation now uses renderer-side cache entries (`Mesh3dViewBindGroupCacheEntry`) instead of unconditional per-draw allocation; 2026-04-14: `PrepareBindGroups` now prebuilds mesh material bind-group cache entries from queued extracted meshes (via `host_gpu_prepare_mesh3d_material_bind_group`), so draw path no longer pays first-hit material bind-group construction for those entries; remaining work is full view/material ownership migration to Bevy-equivalent prepare paths. |
| RENDER-007 | bevy_pbr/render/mesh_view_bindings.rs | View bind-group preparation order and ownership are not fully equivalent. | IN_PROGRESS | 2026-04-14: renderer now persists/reuses mesh3d view bind groups via explicit cache + texture-change invalidation path; fog uniform preparation also moved from `PrepareBindGroups` to `PrepareResources` to match Bevy stage ownership; remaining gap is full view/material bind-group ownership migration from draw-time lazy creation to prepare-stage construction. |
| RENDER-008 | bevy_pbr/render/gpu_preprocess.rs + mesh.rs | GPU preprocess pipeline stages and flush ordering differ from Bevy. | TODO | Align `PrepareResourcesFlush/PrepareResources/PrepareMeshes` responsibilities and buffer lifecycle. |
| RENDER-009 | bevy_pbr/render/morph.rs | Morph extraction/preparation lifecycle is not yet split and tracked like Bevy. | DONE | 2026-04-12: split to `render3d_extract_morphs` + `render3d_prepare_morphs`; `Render3dPhaseState` now keeps current/prev morph indices and uniform-like weight buffers; render systems call extract in render-extract set and apply in render-prepare set. |
| RENDER-010 | bevy_pbr/render/mesh.rs | Queue/execute still carries non-queue responsibilities (build-time material readiness retries). | IN_PROGRESS | 2026-04-12: moved camera/mesh collection and frame assembly from `render3d_queue_system` into `render3d_prepare_meshes_system` (PrepareMeshes set), and moved camera/mesh motion-blur history ownership from global statics into render queue state resource; next step is to push remaining queue-build ownership out of execute camera passes. |
| RENDER-011 | bevy_pbr/render/mesh.rs + occlusion_culling.wgsl | Occlusion/depth-pyramid preprocess integration is not fully staged like Bevy. | TODO | Match preprocess dispatch and indirect-parameter build boundaries. |
| RENDER-012 | bevy_render schedule + bevy_pbr/render/mod.rs | Render schedule set topology differs from Bevy (`Extract/Prepare*/Queue/Render/Cleanup`). | DONE | 2026-04-14: staged topology is now concretely wired (`prepare meshes -> prepare bind groups -> queue -> execute`) with queue-frame snapshot flow, single-pass prepared-camera queue assembly, queue-sweep mesh-runtime-cache cleanup, extracted topology/static preprocess payload reuse, prepare-stage mesh pipeline prewarm (deduped by specialization key), and `PrepareResources` now runs as explicit `prepare_morphs` + `prepare_skin_bindings` systems instead of one merged prepare function. |

## Current work queue

- RENDER-003
- RENDER-004
- RENDER-005
- RENDER-006
- RENDER-007
- RENDER-008
- RENDER-010
- RENDER-011
