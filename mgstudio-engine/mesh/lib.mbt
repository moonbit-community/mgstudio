// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
// Bevy source: `bevy/crates/bevy_mesh/src/lib.rs`.
// Runtime owner split out of `mesh/mesh.mbt`.

///|
const MESH_PLUGIN_NAME : String = "mgstudio.mesh.MeshPlugin"

///|
const BASE_MESH_PIPELINE_KEY_MORPH_TARGETS : UInt64 = 0x8000_0000_0000_0000UL

///|
const BASE_MESH_PIPELINE_KEY_PRIMITIVE_TOPOLOGY_MASK_BITS : UInt64 = 0b111UL

///|
const BASE_MESH_PIPELINE_KEY_PRIMITIVE_TOPOLOGY_SHIFT_BITS : Int = 60

///|
const BASE_MESH_PIPELINE_KEY_STRIP_INDEX_FORMAT_MASK_BITS : UInt64 = 0b11UL

///|
const BASE_MESH_PIPELINE_KEY_STRIP_INDEX_FORMAT_SHIFT_BITS : Int = 58

///|
const BASE_MESH_PIPELINE_KEY_STRIP_INDEX_FORMAT_U32 : UInt64 = 0x0400_0000_0000_0000UL

///|
const BASE_MESH_PIPELINE_KEY_STRIP_INDEX_FORMAT_U16 : UInt64 = 0x0800_0000_0000_0000UL

///|
pub let mesh_set_inherit_weight : @app.SystemSet = "mgstudio.mesh.InheritWeightSystems"

///|
pub struct BaseMeshPipelineKey {
  bits : UInt64
}

///|
pub fn BaseMeshPipelineKey::new(bits : UInt64) -> BaseMeshPipelineKey {
  { bits, }
}

///|
pub fn BaseMeshPipelineKey::bits(self : BaseMeshPipelineKey) -> UInt64 {
  self.bits
}

///|
pub fn BaseMeshPipelineKey::morph_targets() -> BaseMeshPipelineKey {
  BaseMeshPipelineKey::new(BASE_MESH_PIPELINE_KEY_MORPH_TARGETS)
}

///|
pub fn BaseMeshPipelineKey::contains_morph_targets(
  self : BaseMeshPipelineKey,
) -> Bool {
  (self.bits & BASE_MESH_PIPELINE_KEY_MORPH_TARGETS) != 0UL
}

///|
pub fn BaseMeshPipelineKey::from_primitive_topology(
  primitive_topology : Mesh3dPrimitiveTopology,
) -> BaseMeshPipelineKey {
  BaseMeshPipelineKey::from_primitive_topology_and_strip_index(
    primitive_topology,
    None,
  )
}

///|
pub fn BaseMeshPipelineKey::from_primitive_topology_and_strip_index(
  primitive_topology : Mesh3dPrimitiveTopology,
  strip_index_format : Mesh3dIndexFormat?,
) -> BaseMeshPipelineKey {
  let index_bits = match primitive_topology {
    LineStrip =>
      match strip_index_format {
        Some(Uint16) => BASE_MESH_PIPELINE_KEY_STRIP_INDEX_FORMAT_U16
        Some(Uint32) => BASE_MESH_PIPELINE_KEY_STRIP_INDEX_FORMAT_U32
        None => 0UL
      }
    _ => 0UL
  }
  let primitive_topology_bits = (
      primitive_topology.to_int().to_uint64() &
      BASE_MESH_PIPELINE_KEY_PRIMITIVE_TOPOLOGY_MASK_BITS
    ) <<
    BASE_MESH_PIPELINE_KEY_PRIMITIVE_TOPOLOGY_SHIFT_BITS
  BaseMeshPipelineKey::new(primitive_topology_bits | index_bits)
}

///|
pub fn BaseMeshPipelineKey::primitive_topology(
  self : BaseMeshPipelineKey,
) -> Mesh3dPrimitiveTopology {
  let primitive_topology_bits = (
      self.bits >> BASE_MESH_PIPELINE_KEY_PRIMITIVE_TOPOLOGY_SHIFT_BITS
    ) &
    BASE_MESH_PIPELINE_KEY_PRIMITIVE_TOPOLOGY_MASK_BITS
  if primitive_topology_bits == 1UL {
    Mesh3dPrimitiveTopology::LineList
  } else if primitive_topology_bits == 2UL {
    Mesh3dPrimitiveTopology::LineStrip
  } else {
    Mesh3dPrimitiveTopology::TriangleList
  }
}

///|
pub fn BaseMeshPipelineKey::strip_index_format(
  self : BaseMeshPipelineKey,
) -> Mesh3dIndexFormat? {
  let index_bits = self.bits &
    (
      BASE_MESH_PIPELINE_KEY_STRIP_INDEX_FORMAT_MASK_BITS <<
      BASE_MESH_PIPELINE_KEY_STRIP_INDEX_FORMAT_SHIFT_BITS
    )
  if index_bits == BASE_MESH_PIPELINE_KEY_STRIP_INDEX_FORMAT_U16 {
    Some(Mesh3dIndexFormat::Uint16)
  } else if index_bits == BASE_MESH_PIPELINE_KEY_STRIP_INDEX_FORMAT_U32 {
    Some(Mesh3dIndexFormat::Uint32)
  } else {
    None
  }
}

///|
pub struct MeshPlugin {}

///|
pub fn MeshPlugin::MeshPlugin() -> MeshPlugin {
  MeshPlugin::{  }
}

///|
pub impl @app.Plugin for MeshPlugin with fn name(_self) {
  MESH_PLUGIN_NAME
}

///|
pub impl @app.Plugin for MeshPlugin with fn build(_self, app) {
  mesh_plugin(app)
}

///|
fn mark_skinned_meshes_as_changed_if_their_assets_changed(
  commands : @app.Commands,
  skinned_meshes : @ecs.Query[@ecs.Read[SkinnedMesh], @ecs.All],
  inverse_bindposes_asset_events : @ecs.MessageReader[
    @asset.AssetEvent[SkinnedMeshInverseBindposes],
  ],
) -> Unit {
  let changed_asset_ids : @hashset.HashSet[Int] = @hashset.HashSet([])
  for inverse_bindposes_asset_event in inverse_bindposes_asset_events.read() {
    if inverse_bindposes_asset_event is @asset.AssetEvent::Modified(handle) {
      changed_asset_ids.add(handle.id())
    }
  }

  if changed_asset_ids.is_empty() {
    return
  }

  try! skinned_meshes.view(fn(entity, skinned_mesh) {
    let component = skinned_mesh.value()
    if changed_asset_ids.contains(component.inverse_bindposes().id()) {
      commands.entity(entity).insert_component(component)
    }
  })
}

///|
fn mark_3d_meshes_as_changed_if_their_assets_changed(
  commands : @app.Commands,
  meshes_3d : @ecs.Query[@ecs.Read[Mesh3d], @ecs.All],
  mesh_asset_events : @ecs.MessageReader[@asset.AssetEvent[Mesh]],
) -> Unit {
  let changed_asset_ids : @hashset.HashSet[Int] = @hashset.HashSet([])
  for mesh_asset_event in mesh_asset_events.read() {
    if mesh_asset_event is @asset.AssetEvent::Modified(handle) {
      changed_asset_ids.add(handle.id())
    }
  }

  if changed_asset_ids.is_empty() {
    return
  }

  try! meshes_3d.view(fn(entity, mesh_3d) {
    let component = mesh_3d.value()
    if changed_asset_ids.contains(component.mesh().id()) {
      commands.entity(entity).insert_component(component)
    }
  })
}

///|
fn mark_2d_meshes_as_changed_if_their_assets_changed(
  commands : @app.Commands,
  meshes_2d : @ecs.Query[@ecs.Read[Mesh2d], @ecs.All],
  mesh_asset_events : @ecs.MessageReader[@asset.AssetEvent[Mesh]],
) -> Unit {
  let changed_asset_ids : @hashset.HashSet[Int] = @hashset.HashSet([])
  for mesh_asset_event in mesh_asset_events.read() {
    if mesh_asset_event is @asset.AssetEvent::Modified(handle) {
      changed_asset_ids.add(handle.id())
    }
  }

  if changed_asset_ids.is_empty() {
    return
  }

  try! meshes_2d.view(fn(entity, mesh_2d) {
    let component = mesh_2d.value()
    if changed_asset_ids.contains(component.mesh().id()) {
      commands.entity(entity).insert_component(component)
    }
  })
}

///|
pub fn mesh_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  ensure_mesh_required_components(app.world())
  @asset.init_asset(
    @asset.init_asset(app, fn() {
      Mesh::from_3d_geometry(Mesh3dGeometry::new([], [], None))
    }),
    fn() { SkinnedMeshInverseBindposes::new([]) },
  )
  .add_post_update_system_config(
    @app.system_config_param3(mark_2d_meshes_as_changed_if_their_assets_changed),
  )
  .add_post_update_system_config(
    @app.system_config_param3(mark_3d_meshes_as_changed_if_their_assets_changed),
  )
  .add_post_update_system_config(
    @app.system_config_param3(
      mark_skinned_meshes_as_changed_if_their_assets_changed,
    ),
  )
}

///|
fn register_mesh_required_components(
  world : @ecs.World,
) -> Unit raise @ecs.RequiredComponentsError {
  world.register_required_components_with(
    ecs_key_mesh2d,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
  world.register_required_components_with(
    ecs_key_mesh3d,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
}

///|
pub fn ensure_mesh_required_components(world : @ecs.World) -> Unit {
  register_mesh_required_components(world) catch {
    @ecs.RequiredComponentsError::DuplicateRegistration(_, _) => ()
    @ecs.RequiredComponentsError::ArchetypeExists(_) => ()
    _ => abort("failed to register mesh required components")
  }
}

///|
pub(all) enum MeshGeometry {
  Geometry2d(Mesh2dGeometry)
  Geometry3d(Mesh3dGeometry)
}

///|
pub struct Mesh {
  geometry : MeshGeometry
  mut skinned_mesh_bounds : SkinnedMeshBounds?
}

///|
pub impl @asset.Asset for Mesh with fn asset_debug_name() {
  "mgstudio_mesh::Mesh"
}

///|
pub impl @asset.Asset for Mesh with fn asset_as_image(_self) {
  None
}

///|
let mesh_asset_resource_keys : @asset.AssetResourceKeys[Mesh] = @asset.register_asset_resource_keys(
  Mesh::asset_debug_name(),
)

///|
pub impl @asset.Asset for Mesh with fn asset_resource_keys() {
  mesh_asset_resource_keys
}
