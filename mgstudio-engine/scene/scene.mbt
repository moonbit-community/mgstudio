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
  parent_node_index : Int?
  mesh : @pbr.Mesh3d?
  material : @pbr.MeshMaterial3d?
  gltf_scene_index : @gltf.GltfSceneIndex?
  gltf_node_index : @gltf.GltfNodeIndex?
  gltf_mesh_index : @gltf.GltfMeshIndex?
  gltf_primitive_index : @gltf.GltfPrimitiveIndex?
  gltf_skin_index : @gltf.GltfSkinIndex?
  gltf_material_name : @gltf.GltfMaterialName?
  gltf_extras : @gltf.GltfExtras?
  gltf_mesh_extras : @gltf.GltfMeshExtras?
  gltf_material_extras : @gltf.GltfMaterialExtras?
  transform : @transform.Transform
  visibility_range : @visibility.VisibilityRange?
  animation_target : @animation.AnimationTargetId?
  skinned_joint_node_indices : Array[Int]?
  skinned_inverse_bindposes : Array[@mesh.SkinningMat4]?
  default_morph_weights : Array[Float]?
}

///|
pub fn SceneNode3d::new(
  mesh : @pbr.Mesh3d,
  material : @pbr.MeshMaterial3d,
  transform : @transform.Transform,
  visibility_range : @visibility.VisibilityRange?,
  animation_target : @animation.AnimationTargetId?,
  parent_node_index? : Int? = None,
  name? : @ecs.Name? = None,
  gltf_scene_index? : @gltf.GltfSceneIndex? = None,
  gltf_node_index? : @gltf.GltfNodeIndex? = None,
  gltf_mesh_index? : @gltf.GltfMeshIndex? = None,
  gltf_primitive_index? : @gltf.GltfPrimitiveIndex? = None,
  gltf_skin_index? : @gltf.GltfSkinIndex? = None,
  gltf_material_name? : @gltf.GltfMaterialName? = None,
  gltf_extras? : @gltf.GltfExtras? = None,
  gltf_mesh_extras? : @gltf.GltfMeshExtras? = None,
  gltf_material_extras? : @gltf.GltfMaterialExtras? = None,
  skinned_joint_node_indices? : Array[Int]? = None,
  skinned_inverse_bindposes? : Array[@mesh.SkinningMat4]? = None,
  default_morph_weights? : Array[Float]? = None,
) -> SceneNode3d {
  SceneNode3d::{
    name,
    parent_node_index,
    mesh: Some(mesh),
    material: Some(material),
    gltf_scene_index,
    gltf_node_index,
    gltf_mesh_index,
    gltf_primitive_index,
    gltf_skin_index,
    gltf_material_name,
    gltf_extras,
    gltf_mesh_extras,
    gltf_material_extras,
    transform,
    visibility_range,
    animation_target,
    skinned_joint_node_indices,
    skinned_inverse_bindposes,
    default_morph_weights,
  }
}

///|
pub fn SceneNode3d::new_empty(
  transform : @transform.Transform,
  visibility_range : @visibility.VisibilityRange?,
  animation_target : @animation.AnimationTargetId?,
  parent_node_index? : Int? = None,
  name? : @ecs.Name? = None,
  gltf_scene_index? : @gltf.GltfSceneIndex? = None,
  gltf_node_index? : @gltf.GltfNodeIndex? = None,
  gltf_skin_index? : @gltf.GltfSkinIndex? = None,
  gltf_extras? : @gltf.GltfExtras? = None,
) -> SceneNode3d {
  SceneNode3d::{
    name,
    parent_node_index,
    mesh: None,
    material: None,
    gltf_scene_index,
    gltf_node_index,
    gltf_mesh_index: None,
    gltf_primitive_index: None,
    gltf_skin_index,
    gltf_material_name: None,
    gltf_extras,
    gltf_mesh_extras: None,
    gltf_material_extras: None,
    transform,
    visibility_range,
    animation_target,
    skinned_joint_node_indices: None,
    skinned_inverse_bindposes: None,
    default_morph_weights: None,
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
    (
      world.entity(root_entity).get() catch {
        _ => None
      } : @gltf.GltfSceneExtras?)
    is None {
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
  let pending_skinned_meshes : Array[
    (
      Int,
      @asset.Handle[@mesh.Mesh],
      Array[Int],
      Array[@mesh.SkinningMat4],
      @core.Entity?,
    ),
  ] = []
  let mesh_assets_ref = scene_mesh_assets_from_world_mut_or_abort(world)
  let gltf_scene_asset_path = match scene_registry_find_scene_path(root.scene) {
    Some(path) => path
    None => "scene#\{root.scene.id().to_string()}"
  }
  for node in scene.nodes3d {
    let child = world.spawn_empty()
    spawned_entities.push(child)
    if node.name is Some(name) {
      try! world.set_by_key(child, @ecs.Name::component(), name)
    }
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
    if node.gltf_skin_index is Some(skin_index) {
      try! world.set_by_key(child, @gltf.GltfSkinIndex::component(), skin_index)
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
    if node.mesh is Some(mesh_component) {
      let source_mesh_handle = mesh_component.mesh()
      let source_mesh = mesh_assets_ref.val.get(source_mesh_handle)
      let source_geometry = match source_mesh {
        Some(mesh_asset) => mesh_asset.as_3d_geometry()
        None => None
      }
      let has_morph_targets = match source_geometry {
        Some(geometry) => geometry.morph_target_positions() is Some(_)
        None => false
      }
      let needs_instance_mesh = has_morph_targets
      let effective_mesh = if needs_instance_mesh {
        match source_mesh {
          Some(mesh_asset) => {
            let cloned_handle = mesh_assets_ref.val.add(
              scene_clone_mesh_asset(mesh_asset),
            )
            @pbr.Mesh3d::new(cloned_handle)
          }
          None => mesh_component
        }
      } else {
        mesh_component
      }
      try! world.set_by_key(child, @pbr.ecs_key_mesh3d, effective_mesh)
      if node.material is Some(material) {
        try! world.set_by_key(child, @pbr.ecs_key_mesh_material3d, material)
      }
      if has_morph_targets {
        try! world.set_by_key(
          child,
          @mesh.MorphTargetMesh::component(),
          @mesh.MorphTargetMesh::new(source_mesh_handle),
        )
        let default_morph_weights = match node.default_morph_weights {
          Some(weights) => weights
          None => []
        }
        try! world.set_by_key(
          child,
          @mesh.MorphWeights::component(),
          @mesh.MorphWeights::new(default_morph_weights),
        )
      }
      if node.skinned_joint_node_indices is Some(joint_node_indices) &&
        node.skinned_inverse_bindposes is Some(inverse_bindposes) {
        pending_skinned_meshes.push(
          (
            spawned_entities.length() - 1,
            source_mesh_handle,
            joint_node_indices,
            inverse_bindposes,
            Some(child),
          ),
        )
      }
    }
    try! world.set_by_key(child, @transform.ecs_key_transform, node.transform)
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
    if node.gltf_node_index is Some(node_index) {
      @gltf.gltf_extension_notify_node_spawned(
        gltf_scene_asset_path,
        node_index.index(),
        child,
        world,
      )
    }
    if node.gltf_mesh_index is Some(mesh_index) &&
      node.gltf_primitive_index is Some(primitive_index) {
      @gltf.gltf_extension_notify_mesh_spawned(
        gltf_scene_asset_path,
        mesh_index.index(),
        primitive_index.primitive_index(),
        child,
        world,
      )
    }
  }

  for i in 0..<scene.nodes3d.length() {
    let node = scene.nodes3d[i]
    let child = spawned_entities[i]
    let parent_entity = match node.parent_node_index {
      Some(parent_index) =>
        if parent_index >= 0 && parent_index < spawned_entities.length() {
          spawned_entities[parent_index]
        } else {
          root_entity
        }
      None => root_entity
    }
    try! world.set_by_key(
      child,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(parent_entity),
    )
  }

  let spawned_scene_index_by_gltf_node : Array[Int?] = []
  for scene_index, node in scene.nodes3d {
    guard node.gltf_node_index is Some(gltf_node_index) else { continue }
    let gltf_node = gltf_node_index.index()
    if gltf_node < 0 {
      continue
    }
    while spawned_scene_index_by_gltf_node.length() <= gltf_node {
      spawned_scene_index_by_gltf_node.push(None)
    }
    spawned_scene_index_by_gltf_node[gltf_node] = Some(scene_index)
  }

  for pending in pending_skinned_meshes {
    let (
      entity_index,
      source_mesh_handle,
      joint_node_indices,
      inverse_bindposes,
      mesh_root,
    ) = pending
    if entity_index < 0 || entity_index >= spawned_entities.length() {
      continue
    }
    let joint_entities : Array[@core.Entity] = []
    let mut has_all_joints = true
    for joint_node_index in joint_node_indices {
      if joint_node_index >= 0 &&
        joint_node_index < spawned_scene_index_by_gltf_node.length() &&
        spawned_scene_index_by_gltf_node[joint_node_index] is Some(scene_index) &&
        scene_index >= 0 &&
        scene_index < spawned_entities.length() {
        joint_entities.push(spawned_entities[scene_index])
      } else {
        has_all_joints = false
        break
      }
    }
    if !has_all_joints || joint_entities.length() == 0 {
      continue
    }
    let resolved_inverse_bindposes : Array[@mesh.SkinningMat4] = []
    for joint_index in 0..<joint_entities.length() {
      if joint_index < inverse_bindposes.length() {
        resolved_inverse_bindposes.push(inverse_bindposes[joint_index])
      } else {
        resolved_inverse_bindposes.push(@mesh.SkinningMat4::identity())
      }
    }
    try! world.set_by_key(
      spawned_entities[entity_index],
      @mesh.SkinnedMesh::component(),
      @mesh.SkinnedMesh::new(
        source_mesh_handle,
        joint_entities,
        resolved_inverse_bindposes,
        mesh_root~,
      ),
    )
    try! world.set_by_key(
      spawned_entities[entity_index],
      @mesh.DynamicSkinnedMeshBounds::component(),
      @mesh.DynamicSkinnedMeshBounds::new(),
    )
  }

  scene_runtime_mark_ready(world, instance_id, spawned_entities) |> ignore
  try! world.set_by_key(
    root_entity,
    ecs_key_scene_instance_ready,
    SceneInstanceReady::new(instance_id, spawned_entities.length()),
  )
  let spawned_scene_index = if scene.nodes3d.length() > 0 {
    match scene.nodes3d[0].gltf_scene_index {
      Some(scene_index) => scene_index.index()
      None => 0
    }
  } else {
    0
  }
  @gltf.gltf_extension_notify_scene_completed(
    gltf_scene_asset_path, spawned_scene_index, root_entity, world,
  )
}

///|
fn scene_apply_morph_targets(
  base_positions : Array[@math.Vec3],
  morph_targets : Array[Array[@math.Vec3]],
  weights : Array[Float],
) -> Array[@math.Vec3] {
  let positions : Array[@math.Vec3] = []
  for position in base_positions {
    positions.push(position)
  }
  let limit = if morph_targets.length() < weights.length() {
    morph_targets.length()
  } else {
    weights.length()
  }
  for morph_index in 0..<limit {
    let weight = weights[morph_index]
    if weight == 0.0F {
      continue
    }
    let morph_target = morph_targets[morph_index]
    let vertex_limit = if morph_target.length() < positions.length() {
      morph_target.length()
    } else {
      positions.length()
    }
    for vertex_index in 0..<vertex_limit {
      positions[vertex_index] = @math.Vec3::add(
        positions[vertex_index],
        @math.Vec3::mul_scalar(morph_target[vertex_index], weight),
      )
    }
  }
  positions
}

///|
fn scene_sync_and_apply_deformed_meshes(world : @ecs.World) -> Unit {
  let mesh_query : @ecs.Query[
    (@core.Entity, @ecs.Comp[@pbr.Mesh3d], @ecs.Comp[@mesh.MorphTargetMesh]),
    @ecs.All,
  ] = @ecs.query(world)
  let mesh_assets_ref = scene_mesh_assets_from_world_mut_or_abort(world)

  try! mesh_query.view(fn(_entity, data) {
    let (entity, mesh_component, morph_target_mesh_component) = data
    let animation_weights : @animation.AnimationWeights? = try! world
      .entity(entity)
      .get()
    let morph_weights_component : @mesh.MorphWeights? = try! world
      .entity(entity)
      .get()
    let source_mesh_handle = morph_target_mesh_component.value().source_mesh()
    let instance_mesh_handle = mesh_component.value().mesh()
    let source_mesh = match mesh_assets_ref.val.get(source_mesh_handle) {
      Some(value) => value
      None => return
    }
    let source_geometry = match source_mesh.as_3d_geometry() {
      Some(value) => value
      None => return
    }

    let active_morph_weights = match animation_weights {
      Some(weights) => {
        let values = weights.values()
        try! world.set_by_key(
          entity,
          @mesh.MorphWeights::component(),
          @mesh.MorphWeights::new(values),
        )
        values
      }
      None =>
        match morph_weights_component {
          Some(weights) => weights.values()
          None => []
        }
    }

    let mut positions = source_geometry.positions
    if source_geometry.morph_target_positions() is Some(morph_targets) &&
      active_morph_weights.length() > 0 {
      positions = scene_apply_morph_targets(
        positions, morph_targets, active_morph_weights,
      )
    }

    let updated_geometry = scene_clone_mesh3d_geometry(source_geometry)
    guard updated_geometry.replace_positions(positions) else { return }
    guard source_mesh.with_3d_geometry(updated_geometry) is Some(updated_mesh) else {
      return
    }
    ignore(mesh_assets_ref.val.set(instance_mesh_handle, updated_mesh))
  })
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
  .add_pre_update_system(scene_sync_and_apply_deformed_meshes)
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
