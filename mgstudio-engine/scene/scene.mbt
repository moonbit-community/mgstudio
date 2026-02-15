// Copyright 2026 International Digital Economy Academy
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
/// Scene asset registry and SceneRoot instantiation pipeline.
///
/// Current scope:
/// - Bevy-like `SceneRoot` component and spawn-once runtime behavior.
/// - glTF scene key path (`GltfAssetLabel::Scene(..).from_asset(..)`).
/// - Runtime glTF loading path for `.gltf + .bin + textures` (subset used by
///   current 3D parity examples).

///|
pub(all) enum GltfAssetLabel {
  Scene(Int)
}

///|
pub fn GltfAssetLabel::from_asset(
  self : GltfAssetLabel,
  asset_path : String,
) -> String {
  match self {
    Scene(index) => asset_path + "#Scene" + index.to_string()
  }
}

///|
pub struct SceneNode3d {
  mesh : @render3d.Mesh3d
  material : @render3d.MeshMaterial3d
  transform : @math.Transform
  visibility_range : @visibility.VisibilityRange?
}

///|
pub fn SceneNode3d::new(
  mesh : @render3d.Mesh3d,
  material : @render3d.MeshMaterial3d,
  transform : @math.Transform,
  visibility_range : @visibility.VisibilityRange?,
) -> SceneNode3d {
  SceneNode3d::{ mesh, material, transform, visibility_range }
}

///|
pub struct Scene {
  nodes3d : Array[SceneNode3d]
  ready : Bool
}

///|
pub fn Scene::new(nodes3d : Array[SceneNode3d]) -> Scene {
  Scene::{ nodes3d, ready: true }
}

///|
fn scene_pending() -> Scene {
  Scene::{ nodes3d: [], ready: false }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct SceneRoot {
  scene : @asset.Handle[Scene]
}

///|
pub fn SceneRoot::new(scene : @asset.Handle[Scene]) -> SceneRoot {
  SceneRoot::{ scene, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct SceneInstanceReady {
  spawned_entities : Int
}

///|
pub fn SceneInstanceReady::new(spawned_entities : Int) -> SceneInstanceReady {
  SceneInstanceReady::{ spawned_entities, }
}

///|
let scene_assets : Ref[@asset.Assets[Scene]] = Ref::new(@asset.Assets::new())

///|
let gltf_scene_registry : Ref[Array[(String, @asset.Handle[Scene])]] = Ref::new([],
)

///|
fn scene_registry_get(asset_path : String) -> @asset.Handle[Scene]? {
  for entry in gltf_scene_registry.val {
    if entry.0 == asset_path {
      return Some(entry.1)
    }
  }
  None
}

///|
pub fn scene_register_gltf_scene(
  asset_path : String,
  scene : Scene,
) -> @asset.Handle[Scene] {
  if scene_registry_get(asset_path) is Some(handle) {
    scene_pending_remove_handle(handle)
    scene_assets.val.set(handle, scene) |> ignore
    return handle
  }
  let handle = scene_assets.val.add(scene)
  gltf_scene_registry.val.push((asset_path, handle))
  scene_pending_remove_handle(handle)
  handle
}

///|
pub fn scene_load_gltf_scene(
  asset_server : @asset.AssetServer,
  asset_path : String,
) -> @asset.Handle[Scene] {
  if scene_registry_get(asset_path) is Some(handle) {
    return handle
  }
  let handle = scene_assets.val.add(scene_pending())
  gltf_scene_registry.val.push((asset_path, handle))
  scene_queue_gltf_request(asset_server, handle, asset_path)
  handle
}

///|
pub fn scene_get(handle : @asset.Handle[Scene]) -> Scene? {
  scene_assets.val.get(handle)
}

///|
pub fn[W] scene_load_pending_system(_world : W) -> Unit {
  scene_process_pending_requests(@asset.AssetServer::new())
}

///|
pub(open) trait SceneSpawnWorld: Has_SceneRoot + Has_SceneInstanceReady + @core.SpawnWorld + @core.ChangeTickWorld + @hierarchy.Has_Parent + @math.Has_Transform + @render3d.Has_Mesh3d + @render3d.Has_MeshMaterial3d + @visibility.Has_VisibilityRange {
}

///|
pub fn[W : SceneSpawnWorld] scene_spawn_roots_system(world : W) -> Unit {
  let scene_root_store = world.get_scene_root_store()
  let ready_store = world.get_scene_instance_ready_store()
  let mesh_store = world.get_mesh3d_store()
  let material_store = world.get_mesh_material3d_store()
  let transform_store = world.get_transform_store()
  let parent_store = world.get_parent_store()
  let visibility_range_store = world.get_visibility_range_store()
  let tick = world.read_change_tick()

  let pending_roots : Array[(@core.Entity, SceneRoot)] = []
  scene_root_store.for_each(fn(entity, root) {
    if !ready_store.contains(entity) {
      pending_roots.push((entity, root))
    }
  })

  for pending in pending_roots {
    let root_entity = pending.0
    let root = pending.1
    guard scene_assets.val.get(root.scene) is Some(scene) else { continue }
    if !scene.ready {
      continue
    }
    let mut spawned_entities = 0
    for node in scene.nodes3d {
      let child = world.spawn_empty()
      mesh_store.insert(child, node.mesh, tick)
      material_store.insert(child, node.material, tick)
      transform_store.insert(child, node.transform, tick)
      parent_store.insert(child, @hierarchy.Parent::new(root_entity), tick)
      if node.visibility_range is Some(range) {
        visibility_range_store.insert(child, range, tick)
      }
      spawned_entities = spawned_entities + 1
    }
    ready_store.insert(
      root_entity,
      SceneInstanceReady::new(spawned_entities),
      tick,
    )
  }
}

///|
pub(open) trait ScenePluginWorld: SceneSpawnWorld {}

///|
pub fn[W : ScenePluginWorld] scene_plugin(app : @app.App[W]) -> @app.App[W] {
  app
  .add_pre_update_system(scene_load_pending_system)
  .add_pre_update_system(scene_spawn_roots_system)
}
