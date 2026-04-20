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
/// - Bevy-like `SceneRoot` / `SceneInstance` runtime lifecycle behavior.
/// - Runtime glTF loading path for `.gltf + .bin + textures` (subset used by
///   current 3D parity examples).

///|
priv struct SceneAssetRegistryState {
  scene_registry : Array[(String, @asset.Handle[Scene])]
  animation_registry : Array[(String, @asset.Handle[@animation.AnimationClip])]
  mesh_registry : Array[(String, @asset.Handle[@mesh.Mesh])]
  mut lod_visibility_policy : GltfLodVisibilityPolicy
}

///|
fn scene_asset_registry_resource_key() -> @ecs.ResourceKey[
  SceneAssetRegistryState,
] {
  @ecs.register_resource(debug_name="mgstudio_scene::SceneAssetRegistryState")
}

///|
impl @app.Resource for SceneAssetRegistryState with resource() {
  scene_asset_registry_resource_key()
}

///|
fn scene_current_world_or_abort() -> @ecs.World {
  match @app.current_world() {
    Some(world) => world
    None =>
      abort(
        "scene asset helpers require an active app world; use the world-owned resources directly outside scheduled systems",
      )
  }
}

///|
fn scene_assets_from_world_mut_or_abort(
  world : @ecs.World,
) -> Ref[@asset.Assets[Scene]] {
  let key : @ecs.ResourceKey[@asset.Assets[Scene]] = @asset.assets_resource_key()
  match (try! world.get_resource_ref_mut(key)) {
    Some(assets) => assets
    None =>
      abort(
        "scene assets resource is missing; ScenePlugin must initialize Assets<Scene> before use",
      )
  }
}

///|
fn scene_assets_from_world_or_abort(world : @ecs.World) -> @asset.Assets[Scene] {
  let key : @ecs.ResourceKey[@asset.Assets[Scene]] = @asset.assets_resource_key()
  match (try! world.get_resource(key)) {
    Some(assets) => assets
    None =>
      abort(
        "scene assets resource is missing; ScenePlugin must initialize Assets<Scene> before use",
      )
  }
}

///|
fn scene_mesh_assets_from_world_mut_or_abort(
  world : @ecs.World,
) -> Ref[@asset.Assets[@mesh.Mesh]] {
  let key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  match (try! world.get_resource_ref_mut(key)) {
    Some(assets) => assets
    None =>
      abort(
        "mesh assets resource is missing; Render2dPlugin must initialize Assets<Mesh> before scene glTF primitive loading runs",
      )
  }
}

///|
fn scene_registry_find_scene_path(handle : @asset.Handle[Scene]) -> String? {
  if scene_registry_if_present() is Some(registry) {
    for entry in registry.scene_registry {
      if entry.1.id() == handle.id() {
        return Some(entry.0)
      }
    }
  }
  None
}

///|
fn scene_clone_mesh3d_geometry(
  geometry : @mesh.Mesh3dGeometry,
) -> @mesh.Mesh3dGeometry {
  let positions : Array[@math.Vec3] = []
  for position in geometry.positions {
    positions.push(position)
  }
  let uvs : Array[@math.Vec2] = []
  for uv in geometry.uvs {
    uvs.push(uv)
  }
  let indices = match geometry.indices {
    Some(existing) => {
      let next : Array[Int] = []
      for index in existing {
        next.push(index)
      }
      Some(next)
    }
    None => None
  }
  let colors = match geometry.colors {
    Some(existing) => {
      let next : Array[@math.Vec4] = []
      for color in existing {
        next.push(color)
      }
      Some(next)
    }
    None => None
  }
  let mut cloned = @mesh.Mesh3dGeometry::new_with_topology(
    positions,
    uvs,
    indices,
    geometry.topology,
  ).with_colors(colors)
  if geometry.joint_indices is Some(joint_indices) {
    let copied_indices : Array[@mesh.MeshJointIndices] = []
    for joint_index in joint_indices {
      copied_indices.push(joint_index)
    }
    let copied_weights = match geometry.joint_weights {
      Some(existing) => {
        let next : Array[@math.Vec4] = []
        for weight in existing {
          next.push(weight)
        }
        Some(next)
      }
      None => None
    }
    cloned = cloned.with_joint_data(Some(copied_indices), copied_weights)
  } else if geometry.joint_weights is Some(existing) {
    let next : Array[@math.Vec4] = []
    for weight in existing {
      next.push(weight)
    }
    cloned = cloned.with_joint_data(None, Some(next))
  }
  if geometry.morph_target_positions is Some(morph_targets) {
    let copied_targets : Array[Array[@math.Vec3]] = []
    for morph_target in morph_targets {
      let copied_positions : Array[@math.Vec3] = []
      for position in morph_target {
        copied_positions.push(position)
      }
      copied_targets.push(copied_positions)
    }
    let copied_names = match geometry.morph_target_names {
      Some(existing) => {
        let next : Array[String] = []
        for name in existing {
          next.push(name)
        }
        Some(next)
      }
      None => None
    }
    cloned = cloned.with_morph_targets(
      Some(copied_targets),
      morph_target_names=copied_names,
    )
  }
  for attribute in geometry.custom_attributes_vec3 {
    let values : Array[@math.Vec3] = []
    for value in attribute.values() {
      values.push(value)
    }
    cloned = cloned.with_custom_attribute_vec3(attribute.name(), values)
  }
  if geometry.tangents is Some(existing) {
    let copied : Array[@math.Vec4] = []
    for tangent in existing {
      copied.push(tangent)
    }
    ignore(cloned.replace_tangents(Some(copied)))
  }
  cloned
}

///|
fn scene_clone_mesh_asset(mesh_asset : @mesh.Mesh) -> @mesh.Mesh {
  match mesh_asset.geometry {
    @mesh.MeshGeometry::Geometry2d(geometry2d) =>
      @mesh.Mesh::from_2d_geometry(geometry2d)
    @mesh.MeshGeometry::Geometry3d(geometry3d) =>
      @mesh.Mesh::from_3d_geometry(scene_clone_mesh3d_geometry(geometry3d))
  }
}

///|
fn scene_registry_mut_or_abort() -> Ref[SceneAssetRegistryState] {
  let world = scene_current_world_or_abort()
  match (try! world.get_resource_ref_mut(scene_asset_registry_resource_key())) {
    Some(state) => state
    None =>
      abort(
        "scene registry resource is missing; ScenePlugin must initialize SceneAssetRegistryState before use",
      )
  }
}

///|
fn scene_registry_or_abort() -> SceneAssetRegistryState {
  let world = scene_current_world_or_abort()
  match (try! world.get_resource(scene_asset_registry_resource_key())) {
    Some(state) => state
    None =>
      abort(
        "scene registry resource is missing; ScenePlugin must initialize SceneAssetRegistryState before use",
      )
  }
}

///|
fn scene_registry_mut_if_present() -> Ref[SceneAssetRegistryState]? {
  guard @app.current_world() is Some(world) else { return None }
  try! world.get_resource_ref_mut(scene_asset_registry_resource_key())
}

///|
fn scene_registry_if_present() -> SceneAssetRegistryState? {
  guard @app.current_world() is Some(world) else { return None }
  try! world.get_resource(scene_asset_registry_resource_key())
}

///|
priv struct SceneModifiedEventsCursorState {
  modified_event_cursor : Ref[Int]
  debounced_scene_asset_ages : Ref[Map[Int, Int]]
}

///|
fn SceneModifiedEventsCursorState::default() -> SceneModifiedEventsCursorState {
  SceneModifiedEventsCursorState::{
    modified_event_cursor: Ref::new(0),
    debounced_scene_asset_ages: Ref::new({}),
  }
}

///|
fn scene_modified_events_cursor_state_resource_key() -> @ecs.ResourceKey[
  SceneModifiedEventsCursorState,
] {
  @ecs.register_resource(
    debug_name="mgstudio_scene::SceneModifiedEventsCursorState",
  )
}

///|
impl @app.Resource for SceneModifiedEventsCursorState with resource() {
  scene_modified_events_cursor_state_resource_key()
}

///|
fn scene_modified_events_cursor_ref_or_abort(world : @ecs.World) -> Ref[Int] {
  match
    (try! world.get_resource(scene_modified_events_cursor_state_resource_key())) {
    Some(state) => state.modified_event_cursor
    None =>
      abort(
        "scene modified-events cursor resource is missing; ScenePlugin must initialize SceneModifiedEventsCursorState before running reload systems",
      )
  }
}

///|
fn scene_debounced_scene_asset_ages_ref_or_abort(
  world : @ecs.World,
) -> Ref[Map[Int, Int]] {
  match
    (try! world.get_resource(scene_modified_events_cursor_state_resource_key())) {
    Some(state) => state.debounced_scene_asset_ages
    None =>
      abort(
        "scene modified-events cursor resource is missing; ScenePlugin must initialize SceneModifiedEventsCursorState before running reload systems",
      )
  }
}

///|
pub fn scene_set_gltf_lod_visibility_policy(
  policy : GltfLodVisibilityPolicy,
) -> Unit {
  if scene_registry_mut_if_present() is Some(state_ref) {
    state_ref.val.lod_visibility_policy = policy
  }
}

///|
pub fn scene_get_gltf_lod_visibility_policy() -> GltfLodVisibilityPolicy {
  match scene_registry_if_present() {
    Some(state) => state.lod_visibility_policy
    None => GltfLodVisibilityPolicy::default()
  }
}

///|
pub fn scene_reset_gltf_lod_visibility_policy() -> Unit {
  scene_set_gltf_lod_visibility_policy(GltfLodVisibilityPolicy::default())
}

///|
fn scene_registry_get(asset_path : String) -> @asset.Handle[Scene]? {
  for entry in scene_registry_or_abort().scene_registry {
    if entry.0 == asset_path {
      return Some(entry.1)
    }
  }
  None
}

///|
fn scene_animation_registry_get(
  asset_path : String,
) -> @asset.Handle[@animation.AnimationClip]? {
  for entry in scene_registry_or_abort().animation_registry {
    if entry.0 == asset_path {
      return Some(entry.1)
    }
  }
  None
}

///|
fn scene_mesh_registry_get(asset_path : String) -> @asset.Handle[@mesh.Mesh]? {
  for entry in scene_registry_or_abort().mesh_registry {
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
  let world = scene_current_world_or_abort()
  if scene_registry_get(asset_path) is Some(handle) {
    scene_pending_remove_scene_handle(world, handle)
    scene_assets_from_world_mut_or_abort(world).val.set(handle, scene) |> ignore
    return handle
  }
  let handle = scene_assets_from_world_mut_or_abort(world).val.add(scene)
  scene_registry_mut_or_abort().val.scene_registry.push((asset_path, handle))
  scene_pending_remove_scene_handle(world, handle)
  handle
}

///|
pub fn scene_load_gltf_scene(
  asset_server : @asset.AssetServer,
  asset_path : String,
) -> @asset.Handle[Scene] {
  let world = scene_current_world_or_abort()
  if scene_registry_get(asset_path) is Some(handle) {
    return handle
  }
  let handle = scene_assets_from_world_mut_or_abort(world).val.add(
    scene_pending(),
  )
  scene_registry_mut_or_abort().val.scene_registry.push((asset_path, handle))
  scene_queue_gltf_request(world, asset_server, handle, asset_path)
  handle
}

///|
pub fn scene_load_gltf_animation(
  asset_server : @asset.AssetServer,
  asset_path : String,
) -> @asset.Handle[@animation.AnimationClip] {
  let world = scene_current_world_or_abort()
  if scene_animation_registry_get(asset_path) is Some(handle) {
    return handle
  }
  let handle = @animation.animation_clip_add(@animation.AnimationClip::new())
  scene_registry_mut_or_abort().val.animation_registry.push(
    (asset_path, handle),
  )
  scene_queue_gltf_animation_request(world, asset_server, handle, asset_path)
  handle
}

///|
pub fn scene_load_gltf_mesh_primitive(
  asset_server : @asset.AssetServer,
  asset_path : String,
) -> @asset.Handle[@mesh.Mesh] {
  let world = scene_current_world_or_abort()
  if scene_mesh_registry_get(asset_path) is Some(handle) {
    return handle
  }
  let handle = scene_mesh_assets_from_world_mut_or_abort(world).val.reserve_handle()
  scene_registry_mut_or_abort().val.mesh_registry.push((asset_path, handle))
  scene_queue_gltf_mesh_request(world, asset_server, handle, asset_path)
  handle
}

///|
pub fn scene_register_gltf_asset_loaders() -> Unit {
  @asset.asset_register_loader(fn(asset_server, path) {
    scene_load_gltf_scene(asset_server, path)
  })
  @asset.asset_register_loader(fn(asset_server, path) {
    scene_load_gltf_animation(asset_server, path)
  })
  @asset.asset_register_loader(fn(asset_server, path) {
    scene_load_gltf_mesh_primitive(asset_server, path)
  })
}

///|
pub fn scene_get(handle : @asset.Handle[Scene]) -> Scene? {
  scene_assets_from_world_or_abort(scene_current_world_or_abort()).get(handle)
}

///|
let scene_asset_hooks_installed : Ref[Bool] = Ref::new(false)

///|
pub fn scene_install_asset_hooks() -> Unit {
  if scene_asset_hooks_installed.val {
    return
  }
  @gltf.gltf_install_loader_registration(scene_register_gltf_asset_loaders)
  @asset.asset_register_reload_hook(scene_reload_asset_path)
  scene_asset_hooks_installed.val = true
}
