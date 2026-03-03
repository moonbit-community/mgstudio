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
/// - glTF scene/animation key paths
///   (`GltfAssetLabel::{Scene,Animation}(..).from_asset(..)`).
/// - Runtime glTF loading path for `.gltf + .bin + textures` (subset used by
///   current 3D parity examples).

///|
pub(all) enum GltfAssetLabel {
  Scene(Int)
  Animation(Int)
}

///|
pub fn GltfAssetLabel::from_asset(
  self : GltfAssetLabel,
  asset_path : String,
) -> String {
  match self {
    Scene(index) => asset_path + "#Scene" + index.to_string()
    Animation(index) => asset_path + "#Animation" + index.to_string()
  }
}

///|
pub struct SceneNode3d {
  mesh : @render3d.Mesh3d
  material : @render3d.MeshMaterial3d
  transform : @math.Transform
  visibility_range : @visibility.VisibilityRange?
  animation_target : @animation.AnimationTargetId?
}

///|
pub fn SceneNode3d::new(
  mesh : @render3d.Mesh3d,
  material : @render3d.MeshMaterial3d,
  transform : @math.Transform,
  visibility_range : @visibility.VisibilityRange?,
  animation_target : @animation.AnimationTargetId?,
) -> SceneNode3d {
  SceneNode3d::{ mesh, material, transform, visibility_range, animation_target }
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
const GLTF_LOD_DEFAULT_FIRST_START_MARGIN_MIN : Float = 0.0F

///|
const GLTF_LOD_DEFAULT_FIRST_START_MARGIN_MAX : Float = 0.0F

///|
const GLTF_LOD_DEFAULT_FIRST_END_MARGIN_MIN : Float = 3.0F

///|
const GLTF_LOD_DEFAULT_FIRST_END_MARGIN_MAX : Float = 4.0F

///|
const GLTF_LOD_DEFAULT_STEP : Float = 5.0F

///|
pub struct GltfLodVisibilityPolicy {
  enabled : Bool
  first_start_margin_min : Float
  first_start_margin_max : Float
  first_end_margin_min : Float
  first_end_margin_max : Float
  step : Float
}

///|
pub fn GltfLodVisibilityPolicy::default() -> GltfLodVisibilityPolicy {
  GltfLodVisibilityPolicy::{
    enabled: true,
    first_start_margin_min: GLTF_LOD_DEFAULT_FIRST_START_MARGIN_MIN,
    first_start_margin_max: GLTF_LOD_DEFAULT_FIRST_START_MARGIN_MAX,
    first_end_margin_min: GLTF_LOD_DEFAULT_FIRST_END_MARGIN_MIN,
    first_end_margin_max: GLTF_LOD_DEFAULT_FIRST_END_MARGIN_MAX,
    step: GLTF_LOD_DEFAULT_STEP,
  }
}

///|
pub fn GltfLodVisibilityPolicy::with_enabled(
  self : GltfLodVisibilityPolicy,
  enabled : Bool,
) -> GltfLodVisibilityPolicy {
  GltfLodVisibilityPolicy::{ ..self, enabled, }
}

///|
pub fn GltfLodVisibilityPolicy::with_first_lod_range(
  self : GltfLodVisibilityPolicy,
  start_margin_min : Float,
  start_margin_max : Float,
  end_margin_min : Float,
  end_margin_max : Float,
) -> GltfLodVisibilityPolicy {
  GltfLodVisibilityPolicy::{
    ..self,
    first_start_margin_min: start_margin_min,
    first_start_margin_max: start_margin_max,
    first_end_margin_min: end_margin_min,
    first_end_margin_max: end_margin_max,
  }
}

///|
pub fn GltfLodVisibilityPolicy::with_step(
  self : GltfLodVisibilityPolicy,
  step : Float,
) -> GltfLodVisibilityPolicy {
  let safe_step = if step < 0.0F { 0.0F } else { step }
  GltfLodVisibilityPolicy::{ ..self, step: safe_step }
}

///|
fn scene_pending() -> Scene {
  Scene::{ nodes3d: [], ready: false }
}

///|
pub struct SceneRoot {
  scene : @asset.Handle[Scene]
}

///|
pub fn SceneRoot::new(scene : @asset.Handle[Scene]) -> SceneRoot {
  SceneRoot::{ scene, }
}

///|
pub impl ToJson for SceneRoot with to_json(self) {
  self.scene.id().to_json()
}

///|
pub impl @json.FromJson for SceneRoot with from_json(json, path) {
  let scene_id : Int = @json.from_json(json, path~)
  SceneRoot::new(@asset.Handle::new(scene_id))
}

///|
pub struct SceneInstanceReady {
  spawned_entities : Int
}

///|
pub fn SceneInstanceReady::new(spawned_entities : Int) -> SceneInstanceReady {
  SceneInstanceReady::{ spawned_entities, }
}

///|
pub impl ToJson for SceneInstanceReady with to_json(self) {
  self.spawned_entities.to_json()
}

///|
pub impl @json.FromJson for SceneInstanceReady with from_json(json, path) {
  let spawned_entities : Int = @json.from_json(json, path~)
  SceneInstanceReady::new(spawned_entities)
}

///|
let scene_assets : Ref[@asset.Assets[Scene]] = Ref::new(@asset.Assets::new())

///|
let gltf_scene_registry : Ref[Array[(String, @asset.Handle[Scene])]] = Ref::new([],
)

///|
let gltf_animation_registry : Ref[
  Array[(String, @asset.Handle[@animation.AnimationClip])],
] = Ref::new([])

///|
let gltf_lod_visibility_policy : Ref[GltfLodVisibilityPolicy] = Ref::new(
  GltfLodVisibilityPolicy::default(),
)

///|
pub fn scene_set_gltf_lod_visibility_policy(
  policy : GltfLodVisibilityPolicy,
) -> Unit {
  gltf_lod_visibility_policy.val = policy
}

///|
pub fn scene_get_gltf_lod_visibility_policy() -> GltfLodVisibilityPolicy {
  gltf_lod_visibility_policy.val
}

///|
pub fn scene_reset_gltf_lod_visibility_policy() -> Unit {
  gltf_lod_visibility_policy.val = GltfLodVisibilityPolicy::default()
}

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
fn scene_animation_registry_get(
  asset_path : String,
) -> @asset.Handle[@animation.AnimationClip]? {
  for entry in gltf_animation_registry.val {
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
    scene_pending_remove_scene_handle(handle)
    scene_assets.val.set(handle, scene) |> ignore
    return handle
  }
  let handle = scene_assets.val.add(scene)
  gltf_scene_registry.val.push((asset_path, handle))
  scene_pending_remove_scene_handle(handle)
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
pub fn scene_load_gltf_animation(
  asset_server : @asset.AssetServer,
  asset_path : String,
) -> @asset.Handle[@animation.AnimationClip] {
  if scene_animation_registry_get(asset_path) is Some(handle) {
    return handle
  }
  let handle = @animation.animation_clip_add(@animation.AnimationClip::new())
  gltf_animation_registry.val.push((asset_path, handle))
  scene_queue_gltf_animation_request(asset_server, handle, asset_path)
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
pub fn scene_spawn_roots_system(world : @ecs.World) -> Unit {
  let pending_roots : Array[(@core.Entity, SceneRoot)] = []
  try! world
  .query1(ecs_key_scene_root)
  .view(fn(entity, root) {
    if (try! world.get(entity, ecs_key_scene_instance_ready)) is None {
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

    if (try! world.get(root_entity, @animation.ecs_key_animation_player))
      is None {
      try! world.set(
        root_entity,
        @animation.ecs_key_animation_player,
        @animation.AnimationPlayer::default(),
      )
    }

    let mut spawned_entities = 0
    for node in scene.nodes3d {
      let child = world.spawn_empty()
      try! world.set(child, @render3d.ecs_key_mesh3d, node.mesh)
      try! world.set(child, @render3d.ecs_key_mesh_material3d, node.material)
      try! world.set(child, @math.ecs_key_transform, node.transform)
      try! world.set(
        child,
        @hierarchy.ecs_key_parent,
        @hierarchy.Parent::new(root_entity),
      )
      if node.visibility_range is Some(range) {
        try! world.set(child, @visibility.ecs_key_visibility_range, range)
      }
      if node.animation_target is Some(target_id) {
        try! world.set(child, @animation.ecs_key_animation_target_id, target_id)
        try! world.set(
          child,
          @animation.ecs_key_animated_by,
          @animation.AnimatedBy::new(root_entity),
        )
      }
      spawned_entities = spawned_entities + 1
    }
    try! world.set(
      root_entity,
      ecs_key_scene_instance_ready,
      SceneInstanceReady::new(spawned_entities),
    )
  }
}

///|
pub fn scene_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_pre_update_system(scene_load_pending_system)
  .add_pre_update_system(scene_spawn_roots_system)
}
