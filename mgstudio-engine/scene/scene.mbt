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
pub struct SceneNode3d {
  name : @ecs.Name?
  mesh : @pbr.Mesh3d
  material : @pbr.MeshMaterial3d
  gltf_scene_index : @gltf.GltfSceneIndex?
  gltf_node_index : @gltf.GltfNodeIndex?
  gltf_mesh_index : @gltf.GltfMeshIndex?
  gltf_primitive_index : @gltf.GltfPrimitiveIndex?
  gltf_material_name : @gltf.GltfMaterialName?
  gltf_extras : @gltf.GltfExtras?
  gltf_mesh_extras : @gltf.GltfMeshExtras?
  gltf_material_extras : @gltf.GltfMaterialExtras?
  transform : @transform.Transform
  visibility_range : @visibility.VisibilityRange?
  animation_target : @animation.AnimationTargetId?
}

///|
pub fn SceneNode3d::new(
  mesh : @pbr.Mesh3d,
  material : @pbr.MeshMaterial3d,
  transform : @transform.Transform,
  visibility_range : @visibility.VisibilityRange?,
  animation_target : @animation.AnimationTargetId?,
  name? : @ecs.Name? = None,
  gltf_scene_index? : @gltf.GltfSceneIndex? = None,
  gltf_node_index? : @gltf.GltfNodeIndex? = None,
  gltf_mesh_index? : @gltf.GltfMeshIndex? = None,
  gltf_primitive_index? : @gltf.GltfPrimitiveIndex? = None,
  gltf_material_name? : @gltf.GltfMaterialName? = None,
  gltf_extras? : @gltf.GltfExtras? = None,
  gltf_mesh_extras? : @gltf.GltfMeshExtras? = None,
  gltf_material_extras? : @gltf.GltfMaterialExtras? = None,
) -> SceneNode3d {
  SceneNode3d::{
    name,
    mesh,
    material,
    gltf_scene_index,
    gltf_node_index,
    gltf_mesh_index,
    gltf_primitive_index,
    gltf_material_name,
    gltf_extras,
    gltf_mesh_extras,
    gltf_material_extras,
    transform,
    visibility_range,
    animation_target,
  }
}

///|
pub struct Scene {
  nodes3d : Array[SceneNode3d]
  gltf_scene_extras : @gltf.GltfSceneExtras?
  ready : Bool
}

///|
pub fn Scene::new(nodes3d : Array[SceneNode3d]) -> Scene {
  Scene::{ nodes3d, gltf_scene_extras: None, ready: true }
}

///|
pub fn Scene::with_gltf_scene_extras(
  self : Scene,
  extras : @gltf.GltfSceneExtras?,
) -> Scene {
  Scene::{ ..self, gltf_scene_extras: extras }
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
let scene_gltf_lod_visibility_policy_ref : Ref[GltfLodVisibilityPolicy] = Ref::new(
  GltfLodVisibilityPolicy::default(),
)

///|
fn scene_pending() -> Scene {
  Scene::{ nodes3d: [], gltf_scene_extras: None, ready: false }
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
pub struct SceneInstance {
  instance_id : Int
}

///|
pub fn SceneInstance::new(instance_id : Int) -> SceneInstance {
  SceneInstance::{ instance_id, }
}

///|
pub impl ToJson for SceneInstance with to_json(self) {
  self.instance_id.to_json()
}

///|
pub impl @json.FromJson for SceneInstance with from_json(json, path) {
  let instance_id : Int = @json.from_json(json, path~)
  SceneInstance::new(instance_id)
}

///|
pub struct SceneInstanceReady {
  instance_id : Int
  spawned_entities : Int
}

///|
pub fn SceneInstanceReady::new(
  instance_id : Int,
  spawned_entities : Int,
) -> SceneInstanceReady {
  SceneInstanceReady::{ instance_id, spawned_entities }
}

///|
pub impl ToJson for SceneInstanceReady with to_json(self) {
  (self.instance_id, self.spawned_entities).to_json()
}

///|
pub impl @json.FromJson for SceneInstanceReady with from_json(json, path) {
  let pair : (Int, Int)? = Some(@json.from_json(json, path~)) catch {
    _ => None
  }
  match pair {
    Some((instance_id, spawned_entities)) =>
      SceneInstanceReady::new(instance_id, spawned_entities)
    None => {
      let spawned_entities : Int = @json.from_json(json, path~)
      SceneInstanceReady::new(0, spawned_entities)
    }
  }
}

///|
priv struct SceneAssetRegistryState {
  scene_registry : Array[(String, @asset.Handle[Scene])]
  animation_registry : Array[(String, @asset.Handle[@animation.AnimationClip])]
  mesh_registry : Array[(String, @asset.Handle[@mesh.Mesh])]
  mut lod_visibility_policy : GltfLodVisibilityPolicy
}

///|
priv struct SceneInstanceState {
  instance_id : Int
  scene_id : Int
  spawned_entities : Array[@core.Entity]
  ready : Bool
}

///|
priv struct SceneRuntimeState {
  mut next_instance_id : Int
  instances : Array[SceneInstanceState]
}

///|
fn SceneRuntimeState::default() -> SceneRuntimeState {
  SceneRuntimeState::{ next_instance_id: 1, instances: [] }
}

///|
fn scene_runtime_state_resource_key() -> @ecs.ResourceKey[SceneRuntimeState] {
  @ecs.register_resource(debug_name="bevy_scene::SceneRuntimeState")
}

///|
impl @app.Resource for SceneRuntimeState with resource() {
  scene_runtime_state_resource_key()
}

///|
fn scene_runtime_state_mut_or_abort(
  world : @ecs.World,
) -> Ref[SceneRuntimeState] {
  match (try! world.get_resource_ref_mut(scene_runtime_state_resource_key())) {
    Some(state) => state
    None =>
      abort(
        "scene runtime state is missing; ScenePlugin must initialize SceneRuntimeState before running SceneRoot lifecycle systems",
      )
  }
}

///|
fn scene_runtime_state_or_abort(world : @ecs.World) -> SceneRuntimeState {
  match (try! world.get_resource(scene_runtime_state_resource_key())) {
    Some(state) => state
    None =>
      abort(
        "scene runtime state is missing; ScenePlugin must initialize SceneRuntimeState before running SceneRoot lifecycle systems",
      )
  }
}

///|
fn scene_runtime_instance_index(
  state : SceneRuntimeState,
  instance_id : Int,
) -> Int? {
  for i in 0..<state.instances.length() {
    if state.instances[i].instance_id == instance_id {
      return Some(i)
    }
  }
  None
}

///|
fn scene_runtime_allocate_instance(
  world : @ecs.World,
  scene : @asset.Handle[Scene],
) -> Int {
  let state_ref = scene_runtime_state_mut_or_abort(world)
  let instance_id = state_ref.val.next_instance_id
  state_ref.val.next_instance_id = instance_id + 1
  state_ref.val.instances.push(SceneInstanceState::{
    instance_id,
    scene_id: scene.id(),
    spawned_entities: [],
    ready: false,
  })
  instance_id
}

///|
fn scene_runtime_get_instance(
  world : @ecs.World,
  instance_id : Int,
) -> SceneInstanceState? {
  let state = scene_runtime_state_or_abort(world)
  guard scene_runtime_instance_index(state, instance_id) is Some(index) else {
    return None
  }
  Some(state.instances[index])
}

///|
fn scene_runtime_remove_instance(
  world : @ecs.World,
  instance_id : Int,
) -> SceneInstanceState? {
  let state_ref = scene_runtime_state_mut_or_abort(world)
  guard scene_runtime_instance_index(state_ref.val, instance_id) is Some(index) else {
    return None
  }
  Some(state_ref.val.instances.remove(index))
}

///|
fn scene_runtime_mark_ready(
  world : @ecs.World,
  instance_id : Int,
  spawned_entities : Array[@core.Entity],
) -> Bool {
  let state_ref = scene_runtime_state_mut_or_abort(world)
  guard scene_runtime_instance_index(state_ref.val, instance_id) is Some(index) else {
    return false
  }
  let state = state_ref.val.instances[index]
  state_ref.val.instances[index] = SceneInstanceState::{
    ..state,
    spawned_entities,
    ready: true,
  }
  true
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
fn scene_registry_from_world(world : @ecs.World) -> SceneAssetRegistryState? {
  try! world.get_resource(scene_asset_registry_resource_key())
}

///|
fn scene_asset_base_path(asset_path : String) -> String {
  let (gltf_path, _label) = scene_split_gltf_asset_path(asset_path)
  @asset.asset_canonical_path(gltf_path)
}

///|
let scene_modified_event_cursor_ref : Ref[Int] = Ref::new(0)

///|
let scene_modified_event_cursor_world_id_ref : Ref[Int] = Ref::new(-1)

///|
pub fn scene_set_gltf_lod_visibility_policy(
  policy : GltfLodVisibilityPolicy,
) -> Unit {
  scene_gltf_lod_visibility_policy_ref.val = policy
  if scene_registry_mut_if_present() is Some(state_ref) {
    state_ref.val.lod_visibility_policy = policy
  }
}

///|
pub fn scene_get_gltf_lod_visibility_policy() -> GltfLodVisibilityPolicy {
  match scene_registry_if_present() {
    Some(state) => state.lod_visibility_policy
    None => scene_gltf_lod_visibility_policy_ref.val
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
pub fn[W] scene_load_pending_system(_world : W) -> Unit {
  scene_process_pending_requests(@asset.AssetServer::new())
}

///|
fn scene_instance_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> SceneInstance? {
  try world.get_by_key(entity, ecs_key_scene_instance) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn scene_remove_ready_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  ignore(
    try world.remove_by_key(entity, ecs_key_scene_instance_ready) catch {
      _ => false
    } noraise {
      value => value
    },
  )
}

///|
fn scene_unregister_instance(world : @ecs.World, instance_id : Int) -> Unit {
  scene_runtime_remove_instance(world, instance_id) |> ignore
}

///|
fn scene_despawn_instance(world : @ecs.World, instance_id : Int) -> Unit {
  guard scene_runtime_remove_instance(world, instance_id) is Some(instance) else {
    return
  }
  for entity in instance.spawned_entities {
    if world.is_alive(entity) {
      try! world.despawn(entity)
    }
  }
}

///|
fn scene_unregister_root_instance(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  guard scene_instance_component(world, entity) is Some(instance) else {
    return
  }
  scene_unregister_instance(world, instance.instance_id)
}

///|
fn scene_root_on_remove(
  world : @ecs.DeferredWorld,
  context : @ecs.HookContext,
) -> Unit {
  scene_unregister_root_instance(world.world(), context.entity)
}

///|
fn scene_instance_on_remove(
  world : @ecs.DeferredWorld,
  context : @ecs.HookContext,
) -> Unit {
  guard (try! world.get_by_key(context.entity, ecs_key_scene_instance))
    is Some(instance) else {
    return
  }
  scene_unregister_instance(world.world(), instance.instance_id)
}

///|
fn scene_register_component_hooks() -> Bool {
  let scene_root_hooks = @ecs.register_component_hooks_for_key(
    ecs_key_scene_root,
  )
  ignore(try! scene_root_hooks.on_remove(scene_root_on_remove))
  let scene_instance_hooks = @ecs.register_component_hooks_for_key(
    ecs_key_scene_instance,
  )
  ignore(try! scene_instance_hooks.on_remove(scene_instance_on_remove))
  true
}

///|
fn init {
  @gltf.gltf_install_loader_registration(scene_register_gltf_asset_loaders)
  @asset.asset_register_reload_hook(scene_reload_asset_path)
  scene_register_component_hooks() |> ignore
}

///|
fn scene_reload_asset_path(
  world : @ecs.World,
  asset_server : @asset.AssetServer,
  canonical_path : String,
) -> Unit {
  guard scene_registry_from_world(world) is Some(registry) else { return }

  let scenes_to_reload : Array[(@asset.Handle[Scene], String)] = []
  for entry in registry.scene_registry {
    if scene_asset_base_path(entry.0) == canonical_path {
      scenes_to_reload.push((entry.1, entry.0))
    }
  }

  let animations_to_reload : Array[
    (@asset.Handle[@animation.AnimationClip], String),
  ] = []
  for entry in registry.animation_registry {
    if scene_asset_base_path(entry.0) == canonical_path {
      animations_to_reload.push((entry.1, entry.0))
    }
  }

  let meshes_to_reload : Array[(@asset.Handle[@mesh.Mesh], String)] = []
  for entry in registry.mesh_registry {
    if scene_asset_base_path(entry.0) == canonical_path {
      meshes_to_reload.push((entry.1, entry.0))
    }
  }

  if scenes_to_reload.length() == 0 &&
    animations_to_reload.length() == 0 &&
    meshes_to_reload.length() == 0 {
    return
  }

  for entry in scenes_to_reload {
    scene_queue_gltf_request(asset_server, entry.0, entry.1)
  }
  for entry in animations_to_reload {
    scene_queue_gltf_animation_request(asset_server, entry.0, entry.1)
  }
  for entry in meshes_to_reload {
    scene_queue_gltf_mesh_request(asset_server, entry.0, entry.1)
  }
}

///|
fn scene_attach_pending_instance(
  world : @ecs.World,
  root_entity : @core.Entity,
  root : SceneRoot,
) -> Int {
  let instance_id = scene_runtime_allocate_instance(world, root.scene)
  scene_remove_ready_component(world, root_entity)
  try! world.set_by_key(
    root_entity,
    ecs_key_scene_instance,
    SceneInstance::new(instance_id),
  )
  instance_id
}

///|
fn scene_spawn_instance_when_ready(
  world : @ecs.World,
  root_entity : @core.Entity,
  root : SceneRoot,
  instance_id : Int,
) -> Unit {
  guard scene_runtime_get_instance(world, instance_id) is Some(instance) else {
    return
  }
  if instance.ready {
    if (try! world.get_by_key(root_entity, ecs_key_scene_instance_ready))
      is None {
      try! world.set_by_key(
        root_entity,
        ecs_key_scene_instance_ready,
        SceneInstanceReady::new(instance_id, instance.spawned_entities.length()),
      )
    }
    return
  }
  guard scene_assets_from_world_or_abort(world).get(root.scene) is Some(scene) else {
    return
  }
  if !scene.ready {
    return
  }

  if scene.gltf_scene_extras is Some(scene_extras) &&
    (try! world.entity(root_entity).get() : @gltf.GltfSceneExtras?) is None {
    try! world.set_by_key(
      root_entity,
      @gltf.GltfSceneExtras::component(),
      scene_extras,
    )
  }

  if (try! world.get_by_key(root_entity, @animation.ecs_key_animation_player))
    is None {
    try! world.set_by_key(
      root_entity,
      @animation.ecs_key_animation_player,
      @animation.AnimationPlayer::default(),
    )
  }

  let spawned_entities : Array[@core.Entity] = []
  for node in scene.nodes3d {
    let child = world.spawn_empty()
    if node.name is Some(name) {
      try! world.set_by_key(child, @ecs.Name::component(), name)
    }
    try! world.set_by_key(child, @pbr.ecs_key_mesh3d, node.mesh)
    try! world.set_by_key(child, @pbr.ecs_key_mesh_material3d, node.material)
    if node.gltf_scene_index is Some(scene_index) {
      try! world.set_by_key(
        child,
        @gltf.GltfSceneIndex::component(),
        scene_index,
      )
    }
    if node.gltf_node_index is Some(node_index) {
      try! world.set_by_key(child, @gltf.GltfNodeIndex::component(), node_index)
    }
    if node.gltf_mesh_index is Some(mesh_index) {
      try! world.set_by_key(child, @gltf.GltfMeshIndex::component(), mesh_index)
    }
    if node.gltf_primitive_index is Some(primitive_index) {
      try! world.set_by_key(
        child,
        @gltf.GltfPrimitiveIndex::component(),
        primitive_index,
      )
    }
    if node.gltf_material_name is Some(material_name) {
      try! world.set_by_key(
        child,
        @gltf.GltfMaterialName::component(),
        material_name,
      )
    }
    if node.gltf_extras is Some(extras) {
      try! world.set_by_key(child, @gltf.GltfExtras::component(), extras)
    }
    if node.gltf_mesh_extras is Some(mesh_extras) {
      try! world.set_by_key(
        child,
        @gltf.GltfMeshExtras::component(),
        mesh_extras,
      )
    }
    if node.gltf_material_extras is Some(material_extras) {
      try! world.set_by_key(
        child,
        @gltf.GltfMaterialExtras::component(),
        material_extras,
      )
    }
    try! world.set_by_key(child, @transform.ecs_key_transform, node.transform)
    try! world.set_by_key(
      child,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(root_entity),
    )
    if node.visibility_range is Some(range) {
      try! world.set_by_key(child, @visibility.ecs_key_visibility_range, range)
    }
    if node.animation_target is Some(target_id) {
      try! world.set_by_key(
        child, @animation.ecs_key_animation_target_id, target_id,
      )
      try! world.set_by_key(
        child,
        @animation.ecs_key_animated_by,
        @animation.AnimatedBy::new(root_entity),
      )
    }
    spawned_entities.push(child)
  }

  scene_runtime_mark_ready(world, instance_id, spawned_entities) |> ignore
  try! world.set_by_key(
    root_entity,
    ecs_key_scene_instance_ready,
    SceneInstanceReady::new(instance_id, spawned_entities.length()),
  )
}

///|
pub fn scene_reload_modified_roots_system(world : @ecs.World) -> Unit {
  let modified_scene_ids : Array[Int] = []
  if scene_modified_event_cursor_world_id_ref.val != world.world_id() {
    scene_modified_event_cursor_world_id_ref.val = world.world_id()
    scene_modified_event_cursor_ref.val = 0
  }
  let message_key : @ecs.MessageKey[@asset.AssetEvent[Scene]] = @ecs.Message::message()
  let reader = world.message_reader(
    message_key, scene_modified_event_cursor_ref,
  )
  for event in (try! reader.read()) {
    match event {
      Modified(handle) => modified_scene_ids.push(handle.id())
      _ => ()
    }
  }
  if modified_scene_ids.length() == 0 {
    return
  }

  let roots : Array[(@core.Entity, SceneRoot)] = []
  let scene_root_query : @ecs.Query[@ecs.Comp[SceneRoot], @ecs.All] = @ecs.query(
    world,
  )
  try! scene_root_query.view(fn(entity, root) {
    roots.push((entity, root.value()))
  })

  for entry in roots {
    let root_entity = entry.0
    let root = entry.1
    let mut should_reload = false
    for scene_id in modified_scene_ids {
      if scene_id == root.scene.id() {
        should_reload = true
        break
      }
    }
    if !should_reload {
      continue
    }
    if scene_instance_component(world, root_entity) is Some(instance) {
      scene_despawn_instance(world, instance.instance_id)
    }
    scene_attach_pending_instance(world, root_entity, root) |> ignore
  }
}

///|
pub fn scene_spawn_roots_system(world : @ecs.World) -> Unit {
  let roots : Array[(@core.Entity, SceneRoot)] = []
  let scene_root_query : @ecs.Query[@ecs.Comp[SceneRoot], @ecs.All] = @ecs.query(
    world,
  )
  try! scene_root_query.view(fn(entity, root) {
    roots.push((entity, root.value()))
  })

  for entry in roots {
    let root_entity = entry.0
    let root = entry.1
    let instance_id = match scene_instance_component(world, root_entity) {
      Some(instance) =>
        match scene_runtime_get_instance(world, instance.instance_id) {
          Some(current) =>
            if current.scene_id == root.scene.id() {
              instance.instance_id
            } else {
              scene_despawn_instance(world, instance.instance_id)
              scene_attach_pending_instance(world, root_entity, root)
            }
          None => scene_attach_pending_instance(world, root_entity, root)
        }
      None => scene_attach_pending_instance(world, root_entity, root)
    }
    scene_spawn_instance_when_ready(world, root_entity, root, instance_id)
  }
}

///|
fn scene_runtime_plugin_base(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { SceneRuntimeState::default() })
  .add_pre_update_system(scene_load_pending_system)
  .add_pre_update_system(scene_reload_modified_roots_system)
  .add_pre_update_system(scene_spawn_roots_system)
}

///|
pub(all) struct ScenePlugin {}

///|
pub const SCENE_PLUGIN_ID : String = "bevy_scene::ScenePlugin"

///|
pub fn ScenePlugin::default() -> ScenePlugin {
  ScenePlugin::{  }
}

///|
pub impl @app.PluginReplacement for ScenePlugin with replacement_id(_self) {
  SCENE_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for ScenePlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    scene_plugin_with(app, self)
  }
}

///|
pub fn scene_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  scene_plugin_with(app, ScenePlugin::default())
}

///|
pub fn scene_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : ScenePlugin,
) -> @app.App[@ecs.World] {
  scene_runtime_plugin_base(
    scene_init_gltf_assets(app)
    .init_resource(fn() {
      let assets : @asset.Assets[Scene] = @asset.Assets::new()
      assets
    })
    .init_resource(fn() {
      SceneAssetRegistryState::{
        scene_registry: [],
        animation_registry: [],
        mesh_registry: [],
        lod_visibility_policy: scene_gltf_lod_visibility_policy_ref.val,
      }
    }),
  )
}
