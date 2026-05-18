This file must not exceed 200 lines. Excessive done issues should be moved to ARCHIVED_CHECKLIST.md.

The table below is the current authoritative score. Criteria are source-level 1:1 parity: directory/API topology, runtime semantics, upstream test/example coverage, and visual/performance parity. Bands: 95%+ near source-level parity; 80-94% strong but incomplete; 60-79% substantial partial port; 40-59% partial; <40% major gap.

| Scope | Structure | Runtime | Overall | Status | Strict Reassessment |
|---|---:|---:|---:|---|---|
| `app` | 75% | 70% | 70% | 🟡 In Progress | Plugin/schedule surface is useful, but full Bevy scheduler/build-pass/source topology parity is not proven. |
| `ecs` | 72% | 72% | 72% | 🟡 In Progress | Core concepts exist, but storage/query/system internals remain MoonBit-specific and not source-equivalent. |
| `transform` | 78% | 74% | 74% | 🟡 In Progress | Bevy-shaped propagation exists, but dirty-tree/performance/edge-case parity is not complete. |
| `hierarchy` | 76% | 75% | 75% | 🟡 In Progress | Relationship semantics are close enough for main paths, but source/test parity remains incomplete. |
| `render` | 57% | 47% | 47% | 🔴 Major Gap | Render graph/stage names align in places, generic pipeline descriptor ownership has moved down to `render/render_resource`, and mesh3d now consumes material descriptor layout data at pipeline/bind-group creation; renderer ownership, pass layout, and visual parity still diverge substantially. |
| `render/renderer` | 51% | 46% | 46% | 🔴 Major Gap | Too much local renderer architecture remains; renderer ownership, render-graph integration, pass layout, and visual parity still diverge substantially. |
| `core_pipeline` | 55% | 50% | 50% | 🟠 Partial | Shader assets are closer, but postprocess/pass scheduling/runtime behavior are only partially aligned. |
| `pbr` | 53% | 47% | 47% | 🔴 Major Gap | Material pipeline descriptor specialization now mirrors Bevy's mesh-layout + material bind-group path at the pbr boundary, `StandardMaterial` extraction carries the Bevy `AsBindGroup`-derived layout shape into `MaterialProperties`, and standard material properties now install base and prepass specialize hooks; renderer pipeline cache identity now preserves the cached material pipeline id, but lighting/shadows/material pass runtime consumption and examples still show visible divergence. |
| `pbr/render` | 61% | 53% | 53% | 🔴 Major Gap | Bind layouts and extracted data improved, pbr owns Bevy-shaped material and prepass pipeline specializer descriptor paths, `PrepareMeshes` now derives real `MeshVertexBufferLayoutRef` values from mesh assets before warming `SpecializedMeshPipelines`, and the resulting cached pipeline id now flows through extracted mesh payloads, GPU preprocess work items, phase items, binned batch keys, draw payloads, and the renderer mesh3d pipeline cache key. PBR now submits descriptors to renderer for main-pass pipelines and alpha-material shadow prepass pipelines using a distinct prepass runtime id namespace; shadow depth rendering keys pipelines/material bind groups by material pipeline id and consumes the prepass descriptor's shader/layout/depth state. Full Bevy prepass runtime execution and visual output are not 1:1. |
| `pbr/prepass` | 61% | 55% | 55% | 🟠 Partial | Bevy-shaped `PrepassPipeline` descriptor specialization now exists at the PBR material boundary, including prepass view/no-motion layouts, empty group handling, Bevy shader defs, prepass target descriptors, StandardMaterial `pbr_prepass.wgsl` fragment selection, depth-only opaque empty material layout, a separate prepass material pipeline cache, alpha-material shadow prepass descriptor registration, and renderer-side consumption of descriptor shader paths/defs/vertex layout/depth state. Runtime pass execution is still not fully Bevy-equivalent. |
| `pbr/meshlet` | 44% | 32% | 32% | 🔴 Major Gap | Asset loading, meshlet storage buffers, queue buffer planning, descriptor modeling, and material-shade pass planning exist. The remaining root gaps are real visibility-buffer cull/raster/resolve/material-shade GPU pass execution and full meshopt/METIS conversion parity. |
| `material` | 73% | 65% | 65% | 🟠 Partial | Material specialization and descriptor ownership are closer to Bevy, including shared mesh vertex layouts and richer bind-group layout entries. Forward, deferred, and decal integration are still not source-equivalent. |
| `camera` | 65% | 60% | 60% | 🟠 Partial | Camera components/plugins align in parts, but view/projection/render integration is incomplete. |
| `sprite` + `sprite_render` | 60% | 55% | 55% | 🟠 Partial | Basic 2D render path exists; batching/extraction/render parity needs a dedicated audit. |
| `ui` + `ui_render` + `ui_widgets` | 60% | 50% | 50% | 🟠 Partial | Data model is improving, but layout/render/interaction parity is blocked by incomplete deeper taffy/render integration. |
| `feathers` | 45% | 40% | 40% | 🔴 Major Gap | Only a subset of controls/tokens is ported; source-level widget ecosystem parity is not close. |
| `text` | 55% | 45% | 45% | 🔴 Major Gap | Font/layout surfaces exist, but text shaping/visual parity depends on incomplete upstream and local integration. |
| `gltf` + scene import path | 55% | 45% | 45% | 🔴 Major Gap | Loader path works for selected cases, but full asset/animation/material scene parity is not established. |
| `animation` | 60% | 50% | 50% | 🟠 Partial | Graph/runtime work exists, but example behavior and full Bevy test parity are not complete. |
| `scene` static path | 65% | 55% | 55% | 🟠 Partial | Static scene spawning is useful, but dynamic/runtime corner cases and reload parity remain open. |
| `gizmos` + `gizmos_render` | 55% | 45% | 45% | 🔴 Major Gap | API subset exists; real render asset/pipeline and builder coverage are incomplete. |
| `picking` | 60% | 50% | 50% | 🟠 Partial | Main components exist, but pointer-state/event-generation/backend ordering still diverge. |
| `input` | 75% | 70% | 70% | 🟡 In Progress | Event resources are close for common paths; platform/event-order long tail still needs upstream-test parity. |
| `window` + `winit` | 65% | 55% | 55% | 🟠 Partial | Window lifecycle/cursor work progressed, but backend/platform parity is not broad enough for high score. |
| `asset` | 55% | 45% | 45% | 🔴 Major Gap | Asset events and loader slices exist, but source/processor/reload/ready-checker parity remains shallow. |
| `log` + `diagnostic` + `dev_tools` | 60% | 55% | 55% | 🟠 Partial | Useful diagnostics exist; generic deferred diagnostics/material UI paths are not Bevy-equivalent. |
| `anti_alias` | 55% | 40% | 40% | 🔴 Major Gap | Shader assets and components are present, but SMAA/TAA/DLSS runtime pass parity is incomplete. |
| `light` | 55% | 45% | 45% | 🔴 Major Gap | Component ownership moved closer, but clustering/shadow/probe behavior is still materially divergent. |
| `mesh` | 75% | 66% | 66% | 🟠 Partial | Primitive, attribute, vertex-layout, allocator-state, and upload-descriptor surfaces are closer to Bevy. Runtime GPU upload still needs the renderer allocation path migrated off direct mesh creation calls. |
| `image` | 65% | 55% | 55% | 🟠 Partial | Codec table is broader, but exact loader/settings/error behavior parity is not complete. |
| `color` | 75% | 65% | 65% | 🟡 In Progress | Conversion math is comparatively close; remaining work is upstream vector/test coverage breadth. |
| `math` | 80% | 75% | 75% | 🟡 In Progress | Core math and primitives are one of the stronger areas, but generic trait limits still create source-shape gaps. |
| `a11y` | 55% | 45% | 45% | 🔴 Major Gap | Basic forwarding exists; full Bevy/accesskit behavior parity is not established. |
| Rapier integration | 0% | 0% | 0% | ⏸ Out of Bevy Scope | Not present in pinned local `./bevy`; should not count as Bevy parity without a separate third-party reference. |
| stress tests | 45% | 35% | 35% | 🔴 Major Gap | Tooling exists, but heavy examples are not source/behavior/performance equivalent. |
| visual screenshot parity | 45% | 30% | 30% | 🔴 Major Gap | Captures exist, but broad screenshot equivalence is still poor. |
| workspace native validation | 65% | 60% | 60% | 🟠 Partial | `moon check` is stable, but full native test/runtime parity is not yet a reliable gate; native framework linking still blocks some targeted meshlet tests. |


### Active Checklist

- [ ] `pbr/meshlet/upstream wgpu-native C ABI`: Bevy meshlet visibility-buffer resources require Rust `wgpu` native-extension equivalents for `TextureFormat::R64Uint` plus `StorageTextureAccess::Atomic` / WGSL `texture_storage_2d<r64uint, read/write/atomic>`. Remaining blocker: provide supported descriptor-extension symbols from `wgpu-native`/`wgpu_mbt` upstream or a trusted custom `libwgpu_native` build.
- [ ] `pbr/meshlet/from_mesh`: full `MeshletMesh::from_mesh` still needs source-equivalent meshlet generation, partitioning, simplification, and LOD grouping. Remaining blocker: implement or adopt real MoonBit meshopt/METIS equivalents instead of local heuristic simplification.
- [ ] `render/wgpu_mbt` (deferred, upstream): mesh-shader capability surface is still not exposed in `wgpu_mbt`, so `meshlet_adapter_supports_mesh_shader()` remains conservative `false` instead of Bevy-equivalent adapter capability reporting.
- [ ] `text`: finish visual and script-coverage parity for text layout/rendering.
- [ ] `text/moon_cosmic` (upstream): Bevy `Justify::Start` cannot be completed 1:1 yet because `moon_cosmic@0.3.0` exposes `Align::End` but not `Align::Start`; upstream issue `moonbit-community/moon_cosmic#4` tracks adding direction-aware `Start` alignment.
- [ ] `stress_tests`: keep source-level convergence coverage and representative performance/visual regression gates for heavy examples.
