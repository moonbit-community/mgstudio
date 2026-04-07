Archived completed checklist items moved out of ROADMAP_CHECKLIST to keep line budget under control.

- [x] Issue `pbr/perf_bevymark_3d`: remove prequeue-to-draw-item `O(N^2)` remap hotspot in render3d queue pipeline.
- [x] Issue `pbr/perf_many_materials`: remove prequeue-to-mesh `O(N^2)` resolve hotspot in render3d queue pipeline.
- [x] Issue `pbr/perf_queue_index_maps`: switch preprocessed queue remap/resolve to entity-id index maps with generation-safe fallback.
- [x] Issue `pbr/perf_reprofile`: re-run `bevymark_3d/many_materials` stress profiling after queue-path optimization.
