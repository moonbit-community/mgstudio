Archived completed checklist items moved out of ROADMAP_CHECKLIST to keep line budget under control.

- [x] Issue `pbr/perf_bevymark_3d`: remove prequeue-to-draw-item `O(N^2)` remap hotspot in render3d queue pipeline.
- [x] Issue `pbr/perf_many_materials`: remove prequeue-to-mesh `O(N^2)` resolve hotspot in render3d queue pipeline.
- [x] Issue `pbr/perf_queue_index_maps`: switch preprocessed queue remap/resolve to entity-id index maps with generation-safe fallback.
- [x] Issue `pbr/perf_reprofile`: re-run `bevymark_3d/many_materials` stress profiling after queue-path optimization.
- [x] Issue `render/profiler_hooks`: add render-stage profiling hooks for repeatable stress analysis.
- [x] Issue `render_renderer/pass_timing`: expose per-pass/per-phase timing metrics for regressions.
- [x] Issue `render_renderer/mesh2d_structural_cache_keys`: replace mesh2d material cache key heuristics with structural keys and collision-safe lookup.
- [x] Issue `render_renderer/mesh2d_pass_uniform_sync`: move mesh2d view/global uniform upload from draw path to pass begin path.
