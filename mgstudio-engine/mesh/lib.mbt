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
pub struct MeshPlugin {}

///|
pub fn MeshPlugin::default() -> MeshPlugin {
  MeshPlugin::{  }
}

///|
pub impl @app.Plugin for MeshPlugin with name(_self) {
  MESH_PLUGIN_NAME
}

///|
pub impl @app.Plugin for MeshPlugin with build(_self, app) {
  mesh_plugin(app)
}

///|
fn mark_skinned_meshes_as_changed_if_their_assets_changed(
  commands : @app.Commands,
  skinned_meshes : @ecs.Query[@ecs.Comp[SkinnedMesh], @ecs.All],
  inverse_bindposes_asset_events : @ecs.MessageReader[
    @asset.AssetEvent[SkinnedMeshInverseBindposes],
  ],
) -> Unit {
  let changed_asset_ids : Map[Int, Bool] = {}
  for
    inverse_bindposes_asset_event in (try! inverse_bindposes_asset_events.read()) {
    if inverse_bindposes_asset_event is @asset.AssetEvent::Modified(handle) {
      changed_asset_ids.set(handle.id(), true)
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
  meshes_3d : @ecs.Query[@ecs.Comp[Mesh3d], @ecs.All],
  mesh_asset_events : @ecs.MessageReader[@asset.AssetEvent[Mesh]],
) -> Unit {
  let changed_asset_ids : Map[Int, Bool] = {}
  for mesh_asset_event in (try! mesh_asset_events.read()) {
    if mesh_asset_event is @asset.AssetEvent::Modified(handle) {
      changed_asset_ids.set(handle.id(), true)
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
pub fn mesh_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() {
    let assets : @asset.Assets[Mesh] = @asset.Assets::new()
    assets
  })
  .init_resource(fn() {
    let assets : @asset.Assets[SkinnedMeshInverseBindposes] = @asset.Assets::new()
    assets
  })
  .add_post_update_system(
    @app.system_param3(mark_3d_meshes_as_changed_if_their_assets_changed),
  )
  .add_post_update_system(
    @app.system_param3(mark_skinned_meshes_as_changed_if_their_assets_changed),
  )
}

///|
pub(all) enum MeshGeometry {
  Geometry2d(Mesh2dGeometry)
  Geometry3d(Mesh3dGeometry)
}

///|
pub struct Mesh {
  geometry : MeshGeometry
}
