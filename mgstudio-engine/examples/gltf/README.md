# glTF Example Parity (vs `bevy/examples/gltf`)

This folder tracks parity status for Bevy glTF examples.

## Status Matrix

| Bevy Example | mgstudio Example | Status | Notes |
|---|---|---|---|
| `load_gltf.rs` | `examples/gltf/load_gltf` | Done | Standard `AssetServer.load(...) + SceneRoot` flow is implemented and native-checkable. |
| `gltf_skinned_mesh.rs` | `examples/gltf/gltf_skinned_mesh` | Done | Skinned scene spawning now creates `SkinnedMesh` entities and the example drives joint transforms through the shared CPU skinning runtime. |
| `gltf_extension_animation_graph.rs` | `examples/gltf/gltf_extension_animation_graph` | Done | glTF extension callbacks now see collected animations and scene completion, then attach an `AnimationGraph` to the spawned scene root. |
| `load_gltf_extras.rs` | `examples/gltf/load_gltf_extras` | Done | Scene/node/material extras are imported and exposed as ECS components on spawned entities. |
| `query_gltf_primitives.rs` | `examples/gltf/query_gltf_primitives` | Done | Stable scene/node/mesh/primitive metadata is exported during scene spawning for primitive lookup queries. |
| `update_gltf_scene.rs` | `examples/gltf/update_gltf_scene` | Done | Scene root updates, transform changes, and hot-reload-adjacent flow are implemented on the current `SceneRoot` path. |
| `edit_material_on_gltf.rs` | `examples/gltf/edit_material_on_gltf` | Done | Imported primitive/material metadata is sufficient to resolve and edit glTF-backed material assets. |
| `custom_gltf_vertex_attribute.rs` | `examples/gltf/custom_gltf_vertex_attribute` | Done | Custom imported glTF vertex attributes now map into local mesh attributes through the extension registry. |
| `gltf_extension_mesh_2d.rs` | `examples/gltf/gltf_extension_mesh_2d` | Done | Extension callbacks can rewrite spawned glTF primitives into 2D mesh/material entities. |

## Remaining Runtime Gaps

1. Example parity in this folder is complete, but the extension integration surface still uses a hand-written callback registry instead of Bevy's trait-object loader shape.
2. Custom imported vertex attributes currently target the vector formats used by shipped examples rather than a more general typed attribute schema.

## Validation

- `moon check --target native --package-path examples/gltf/load_gltf`
- `moon check --target native --package-path examples/gltf/load_gltf_extras`
- `moon check --target native --package-path examples/gltf/query_gltf_primitives`
- `moon check --target native --package-path examples/gltf/update_gltf_scene`
- `moon check --target native --package-path examples/gltf/edit_material_on_gltf`
- `moon check --target native --package-path examples/gltf/custom_gltf_vertex_attribute`
- `moon check --target native --package-path examples/gltf/gltf_extension_mesh_2d`
- `moon check --target native --package-path examples/gltf/gltf_extension_animation_graph`
- `moon check --target native --package-path examples/gltf/gltf_skinned_mesh`
