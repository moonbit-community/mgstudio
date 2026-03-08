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
  Node(Int)
  Mesh(Int)
  Primitive(Int, Int)
  MorphTarget(Int, Int)
  Texture(Int)
  Material(Int, Bool)
  DefaultMaterial
  Animation(Int)
  Skin(Int)
  InverseBindMatrices(Int)
}

///|
const GLTF_ASSET_LABEL_MESH_PREFIX : String = "Mesh"

///|
const GLTF_ASSET_LABEL_PRIMITIVE_SEGMENT : String = "/Primitive"

///|
const GLTF_ASSET_LABEL_MORPH_TARGET_SUFFIX : String = "/MorphTargets"

///|
const GLTF_ASSET_LABEL_MATERIAL_PREFIX : String = "Material"

///|
const GLTF_ASSET_LABEL_MATERIAL_INVERTED_SUFFIX : String = " (inverted)"

///|
const GLTF_ASSET_LABEL_SKIN_PREFIX : String = "Skin"

///|
const GLTF_ASSET_LABEL_INVERSE_BIND_MATRICES_SUFFIX : String = "/InverseBindMatrices"

///|
fn gltf_parse_non_negative_int(payload : String) -> Int? {
  let parsed = @strconv.parse_int(payload[:], base=10) catch { _ => -1 }
  if parsed < 0 {
    None
  } else {
    Some(parsed)
  }
}

///|
fn gltf_parse_prefixed_index(label : String, prefix : String) -> Int? {
  if !label.has_prefix(prefix) {
    return None
  }
  let suffix = (try! label[prefix.length():label.length()]).to_string()
  if suffix.length() == 0 {
    None
  } else {
    gltf_parse_non_negative_int(suffix)
  }
}

///|
fn gltf_parse_mesh_primitive_label(label : String) -> (Int, Int)? {
  if !label.has_prefix(GLTF_ASSET_LABEL_MESH_PREFIX) {
    return None
  }
  guard label.find(GLTF_ASSET_LABEL_PRIMITIVE_SEGMENT) is Some(split_index) else {
    return None
  }
  let mesh_start = GLTF_ASSET_LABEL_MESH_PREFIX.length()
  let primitive_start = split_index +
    GLTF_ASSET_LABEL_PRIMITIVE_SEGMENT.length()
  let mesh_text = (try! label[mesh_start:split_index]).to_string()
  let primitive_text = (try! label[primitive_start:label.length()]).to_string()
  if mesh_text.length() == 0 || primitive_text.length() == 0 {
    return None
  }
  guard gltf_parse_non_negative_int(mesh_text) is Some(mesh_index) else {
    return None
  }
  guard gltf_parse_non_negative_int(primitive_text) is Some(primitive_index) else {
    return None
  }
  Some((mesh_index, primitive_index))
}

///|
fn gltf_parse_material_label(label : String) -> (Int, Bool)? {
  if !label.has_prefix(GLTF_ASSET_LABEL_MATERIAL_PREFIX) {
    return None
  }
  let payload = (try! label[GLTF_ASSET_LABEL_MATERIAL_PREFIX.length():label.length()]).to_string()
  if payload.length() == 0 {
    return None
  }
  let mut is_scale_inverted = false
  let mut index_payload = payload
  if payload.has_suffix(GLTF_ASSET_LABEL_MATERIAL_INVERTED_SUFFIX) {
    let end = payload.length() -
      GLTF_ASSET_LABEL_MATERIAL_INVERTED_SUFFIX.length()
    if end <= 0 {
      return None
    }
    index_payload = (try! payload[0:end]).to_string()
    is_scale_inverted = true
  }
  guard gltf_parse_non_negative_int(index_payload) is Some(index) else {
    return None
  }
  Some((index, is_scale_inverted))
}

///|
pub fn GltfAssetLabel::to_label(self : GltfAssetLabel) -> String {
  match self {
    Scene(index) => "Scene" + index.to_string()
    Node(index) => "Node" + index.to_string()
    Mesh(index) => "Mesh" + index.to_string()
    Primitive(mesh, primitive) =>
      GLTF_ASSET_LABEL_MESH_PREFIX +
      mesh.to_string() +
      GLTF_ASSET_LABEL_PRIMITIVE_SEGMENT +
      primitive.to_string()
    MorphTarget(mesh, primitive) =>
      GLTF_ASSET_LABEL_MESH_PREFIX +
      mesh.to_string() +
      GLTF_ASSET_LABEL_PRIMITIVE_SEGMENT +
      primitive.to_string() +
      GLTF_ASSET_LABEL_MORPH_TARGET_SUFFIX
    Texture(index) => "Texture" + index.to_string()
    Material(index, is_scale_inverted) => {
      let inverted_suffix = if is_scale_inverted {
        GLTF_ASSET_LABEL_MATERIAL_INVERTED_SUFFIX
      } else {
        ""
      }
      GLTF_ASSET_LABEL_MATERIAL_PREFIX + index.to_string() + inverted_suffix
    }
    DefaultMaterial => "DefaultMaterial"
    Animation(index) => "Animation" + index.to_string()
    Skin(index) => "Skin" + index.to_string()
    InverseBindMatrices(index) =>
      GLTF_ASSET_LABEL_SKIN_PREFIX +
      index.to_string() +
      GLTF_ASSET_LABEL_INVERSE_BIND_MATRICES_SUFFIX
  }
}

///|
pub fn GltfAssetLabel::parse(label : String) -> GltfAssetLabel? {
  if label == "DefaultMaterial" {
    return Some(DefaultMaterial)
  }
  if label.has_suffix(GLTF_ASSET_LABEL_MORPH_TARGET_SUFFIX) {
    let end = label.length() - GLTF_ASSET_LABEL_MORPH_TARGET_SUFFIX.length()
    if end <= 0 {
      return None
    }
    let primitive_label = (try! label[0:end]).to_string()
    if gltf_parse_mesh_primitive_label(primitive_label)
      is Some((mesh, primitive)) {
      return Some(MorphTarget(mesh, primitive))
    }
    return None
  }
  if gltf_parse_mesh_primitive_label(label) is Some((mesh, primitive)) {
    return Some(Primitive(mesh, primitive))
  }
  if label.has_suffix(GLTF_ASSET_LABEL_INVERSE_BIND_MATRICES_SUFFIX) &&
    label.has_prefix(GLTF_ASSET_LABEL_SKIN_PREFIX) {
    let end = label.length() -
      GLTF_ASSET_LABEL_INVERSE_BIND_MATRICES_SUFFIX.length()
    if end <= GLTF_ASSET_LABEL_SKIN_PREFIX.length() {
      return None
    }
    let index_payload = (try! label[GLTF_ASSET_LABEL_SKIN_PREFIX.length():end]).to_string()
    if gltf_parse_non_negative_int(index_payload) is Some(index) {
      return Some(InverseBindMatrices(index))
    }
    return None
  }
  if gltf_parse_material_label(label) is Some((index, is_scale_inverted)) {
    return Some(Material(index, is_scale_inverted))
  }
  if gltf_parse_prefixed_index(label, "Scene") is Some(index) {
    return Some(Scene(index))
  }
  if gltf_parse_prefixed_index(label, "Node") is Some(index) {
    return Some(Node(index))
  }
  if gltf_parse_prefixed_index(label, "Mesh") is Some(index) {
    return Some(Mesh(index))
  }
  if gltf_parse_prefixed_index(label, "Texture") is Some(index) {
    return Some(Texture(index))
  }
  if gltf_parse_prefixed_index(label, "Animation") is Some(index) {
    return Some(Animation(index))
  }
  if gltf_parse_prefixed_index(label, "Skin") is Some(index) {
    return Some(Skin(index))
  }
  None
}

///|
pub fn gltf_split_asset_path_with_label(
  asset_path : String,
) -> (String, GltfAssetLabel?) {
  if asset_path.rev_find("#") is Some(index) {
    let base_path = (try! asset_path[0:index]).to_string()
    let label_start = index + 1
    if label_start >= asset_path.length() {
      return (base_path, None)
    }
    let label = (try! asset_path[label_start:asset_path.length()]).to_string()
    (base_path, GltfAssetLabel::parse(label))
  } else {
    (asset_path, None)
  }
}

///|
pub fn GltfAssetLabel::from_asset(
  self : GltfAssetLabel,
  asset_path : String,
) -> String {
  asset_path + "#" + self.to_label()
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
priv struct SceneAssetRegistryState {
  scene_registry : Array[(String, @asset.Handle[Scene])]
  animation_registry : Array[(String, @asset.Handle[@animation.AnimationClip])]
  mesh_registry : Array[(String, @asset.Handle[@mesh.Mesh])]
  mut lod_visibility_policy : GltfLodVisibilityPolicy
}

///|
fn SceneAssetRegistryState::default() -> SceneAssetRegistryState {
  SceneAssetRegistryState::{
    scene_registry: [],
    animation_registry: [],
    mesh_registry: [],
    lod_visibility_policy: GltfLodVisibilityPolicy::default(),
  }
}

///|
fn scene_asset_registry_resource_key() -> @ecs.ResourceKey[
  SceneAssetRegistryState,
] {
  @ecs.register_resource(debug_name="bevy_scene::SceneAssetRegistryState")
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
  match (try! world.get_resource_ref_mut(key, 0)) {
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
  match (try! world.get_resource_ref_mut(key, 0)) {
    Some(assets) => assets
    None =>
      abort(
        "mesh assets resource is missing; Render2dPlugin must initialize Assets<Mesh> before scene glTF primitive loading runs",
      )
  }
}

///|
fn scene_registry_mut_or_abort() -> Ref[SceneAssetRegistryState] {
  let world = scene_current_world_or_abort()
  match
    (try! world.get_resource_ref_mut(scene_asset_registry_resource_key(), 0)) {
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
pub fn scene_set_gltf_lod_visibility_policy(
  policy : GltfLodVisibilityPolicy,
) -> Unit {
  scene_registry_mut_or_abort().val.lod_visibility_policy = policy
}

///|
pub fn scene_get_gltf_lod_visibility_policy() -> GltfLodVisibilityPolicy {
  scene_registry_or_abort().lod_visibility_policy
}

///|
pub fn scene_reset_gltf_lod_visibility_policy() -> Unit {
  scene_registry_mut_or_abort().val.lod_visibility_policy = GltfLodVisibilityPolicy::default()
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
    scene_pending_remove_scene_handle(handle)
    scene_assets_from_world_mut_or_abort(world).val.set(handle, scene) |> ignore
    return handle
  }
  let handle = scene_assets_from_world_mut_or_abort(world).val.add(scene)
  scene_registry_mut_or_abort().val.scene_registry.push((asset_path, handle))
  scene_pending_remove_scene_handle(handle)
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
  scene_registry_mut_or_abort().val.animation_registry.push(
    (asset_path, handle),
  )
  scene_queue_gltf_animation_request(asset_server, handle, asset_path)
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
  scene_queue_gltf_mesh_request(asset_server, handle, asset_path)
  handle
}

///|
fn scene_register_asset_loaders() -> Unit {
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
    guard scene_assets_from_world_or_abort(world).get(root.scene) is Some(scene) else {
      continue
    }
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
  scene_register_asset_loaders()
  app
  .init_resource(fn() {
    let assets : @asset.Assets[Scene] = @asset.Assets::new()
    assets
  })
  .init_resource(fn() { SceneAssetRegistryState::default() })
  .add_pre_update_system(scene_load_pending_system)
  .add_pre_update_system(scene_spawn_roots_system)
}
