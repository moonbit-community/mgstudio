# Render Parity Issue Tracker

Last updated: 2026-04-07

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
| RENDER-003 | bevy_pbr/render/skin.rs | Skin uniforms use per-skin slot cache, not Bevy-style global allocator + current/prev double buffers. | TODO | Introduce `SkinUniforms`-equivalent resource and migrate motion-vector previous skin data path. |
| RENDER-004 | bevy_pbr/render/mesh.rs | Mesh extract path is not changed/removed incremental at Bevy granularity. | TODO | Align with `extract_meshes_for_gpu_building` query + removed-components reextract logic. |
| RENDER-005 | bevy_pbr/render/mesh.rs | Missing dedicated `set_mesh_motion_vector_flags` stage after skin/morph extraction. | TODO | Add explicit prepare-meshes stage update for previous skin/morph flags. |
| RENDER-006 | bevy_pbr/render/mesh.rs + mesh_bindings.rs | Mesh bind-group prep still partially deferred to draw/execute paths. | TODO | Move remaining bind-group creation to prepare-bind-groups stage. |
| RENDER-007 | bevy_pbr/render/mesh_view_bindings.rs | View bind-group preparation order and ownership are not fully equivalent. | TODO | Align per-view bind-group resources and stage ordering with Bevy render schedule. |
| RENDER-008 | bevy_pbr/render/gpu_preprocess.rs + mesh.rs | GPU preprocess pipeline stages and flush ordering differ from Bevy. | TODO | Align `PrepareResourcesFlush/PrepareResources/PrepareMeshes` responsibilities and buffer lifecycle. |
| RENDER-009 | bevy_pbr/render/morph.rs | Morph extraction/preparation lifecycle is not yet split and tracked like Bevy. | TODO | Add `extract_morphs/prepare_morphs` parity path and previous-frame indices behavior. |
| RENDER-010 | bevy_pbr/render/mesh.rs | Queue/execute still carries non-queue responsibilities (build-time material readiness retries). | TODO | Move toward Bevy `collect_meshes_for_gpu_building` model and queue-only hot path. |
| RENDER-011 | bevy_pbr/render/mesh.rs + occlusion_culling.wgsl | Occlusion/depth-pyramid preprocess integration is not fully staged like Bevy. | TODO | Match preprocess dispatch and indirect-parameter build boundaries. |
| RENDER-012 | bevy_render schedule + bevy_pbr/render/mod.rs | Render schedule set topology differs from Bevy (`Extract/Prepare*/Queue/Render/Cleanup`). | IN_PROGRESS | 2026-04-07: added `prepare_resources_flush / prepare_resources / prepare_meshes / prepare_bind_groups` set families and ordered them in `pbr/mesh_render_plugin.mbt`; next step is to move concrete mesh/bindgroup work into each dedicated set. |

## Current work queue

- RENDER-003
- RENDER-004
- RENDER-005
- RENDER-006
- RENDER-007
- RENDER-008
- RENDER-009
- RENDER-010
- RENDER-011
- RENDER-012
