# glTF Example Parity (vs `bevy/examples/gltf`)

This folder tracks parity status for Bevy glTF examples.

## Status Matrix

| Bevy Example | mgstudio Example | Status | Notes |
|---|---|---|---|
| `load_gltf.rs` | `examples/gltf/load_gltf` | Done | Standard `AssetServer.load(...) + SceneRoot` flow is implemented and native-checkable. |
| `gltf_skinned_mesh.rs` | N/A | Blocked | Requires skinned mesh runtime, joint matrices, and animated skin playback. |
| `gltf_extension_animation_graph.rs` | N/A | Blocked | Depends on glTF animation-graph extension parsing and integration with the graph runtime. |
| `load_gltf_extras.rs` | N/A | Blocked | Needs Bevy-style extras extraction surface for scene/node/material metadata. |
| `query_gltf_primitives.rs` | N/A | Blocked | Needs exported primitive/entity query metadata beyond current scene spawning flow. |
| `update_gltf_scene.rs` | N/A | Pending | Likely feasible on top of current `SceneRoot` flow, but not implemented in this tranche. |
| `edit_material_on_gltf.rs` | N/A | Pending | Material handles exist, but this example still needs a clean glTF material-lookup path. |
| `custom_gltf_vertex_attribute.rs` | N/A | Pending | Depends on custom vertex-attribute query/edit flow for imported primitives. |
| `gltf_extension_mesh_2d.rs` | N/A | Pending | Depends on the extension surface and 2D glTF mesh import flow. |

## Core Missing Runtime Modules

1. Skinned glTF playback:
   - joint/weight vertex channels
   - skin component/runtime upload path
2. glTF extras surface:
   - exported node/material/scene extras access
3. glTF extension integration:
   - extension parsing hooks exposed to runtime/example flow
4. Primitive/material query helpers:
   - stable entity/material resolution after `SceneRoot` spawning

## Validation

- `moon check --target native --package-path examples/gltf/load_gltf`
