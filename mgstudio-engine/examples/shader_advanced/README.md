# Shader Advanced Example Parity (vs `bevy/examples/shader_advanced`)

This folder tracks parity status for Bevy shader_advanced examples.

## Status Matrix

| Bevy Example | mgstudio Example | Status | Notes |
| --- | --- | --- | --- |
| `manual_material.rs` | `examples/shader_advanced/manual_material` | Done | Mesh3d draw path now supports explicit extension fragment shader override via `MeshMaterial3d::with_extension_fragment_shader_path(...)`. |
| `custom_vertex_attribute.rs` | `examples/shader_advanced/custom_vertex_attribute` | Done | Custom mesh vertex attributes can be authored and consumed from custom mesh3d shader source. |
| `custom_post_processing.rs` | `examples/shader_advanced/custom_post_processing` | Done | Added `CustomPostProcess3d` camera component and generic fullscreen shader stage (`shader_path` + `fragment_entry`) on the 3D post-process chain. |
| `compute_mesh.rs` | N/A | Blocked | Requires compute-driven mesh pipeline integration not exposed on current public runtime path. |
| `custom_phase_item.rs` | N/A | Blocked | Requires custom render phase item/public phase APIs. |
| `custom_render_phase.rs` | N/A | Blocked | Requires custom render phase/public pipeline slot APIs. |
| `custom_shader_instancing.rs` | N/A | Blocked | Requires Bevy-like material specialization and instancing pipeline control. |
| `fullscreen_material.rs` | `examples/shader_advanced/fullscreen_material` | Done | Implemented on `CustomPostProcess3d` with Bevy-like fullscreen shader parameters via `@group(0) @binding(2)` uniform `vec4`. |
| `render_depth_to_texture.rs` | N/A | Blocked | Requires render-to-texture depth pipeline and public extraction hooks. |
| `specialized_mesh_pipeline.rs` | N/A | Blocked | Requires public specialized mesh pipeline/material specialization surface. |
| `texture_binding_array.rs` | N/A | Blocked | Requires bindless or texture array material binding surface. |

## Validation

- `moon check --target native --package-path examples/shader_advanced/manual_material`
- `moon check --target native --package-path examples/shader_advanced/custom_vertex_attribute`
- `moon check --target native --package-path examples/shader_advanced/custom_post_processing`
- `moon check --target native --package-path examples/shader_advanced/fullscreen_material`
