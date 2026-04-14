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
// Bevy source: `bevy/crates/bevy_gltf/src/loader/mod.rs`.
pub using @gltf_gltf_ext {type GltfAssetLabel}

///|
pub using @gltf_loader_extensions {type GltfExtensionHandler}

///|
pub using @gltf_loader_extensions {type GltfExtensionHandlers}

///|
pub type GltfLoaderRegistration = () -> Unit

///|
pub type GltfLoaderSettings = @asset.ImageLoaderSettings

///|
pub using @gltf_gltf_ext {type GltfExtras}

///|
pub using @gltf_gltf_ext {type GltfMaterialExtras}

///|
pub using @gltf_gltf_ext {type GltfMaterialName}

///|
pub using @gltf_gltf_ext {type GltfMeshExtras}

///|
pub using @gltf_gltf_ext {type GltfMeshIndex}

///|
pub using @gltf_gltf_ext {type GltfNodeIndex}

///|
pub using @gltf_gltf_ext {type GltfPrimitiveIndex}

///|
pub using @gltf_gltf_ext {type GltfSceneExtras}

///|
pub using @gltf_gltf_ext {type GltfSceneIndex}

///|
pub using @gltf_gltf_ext {type GltfSkinIndex}

///|
pub struct GltfCustomVertexAttribute {
  gltf_name : String
  mapped_name : String
}

///|
pub fn GltfCustomVertexAttribute::new(
  gltf_name : String,
  mapped_name : String,
) -> GltfCustomVertexAttribute {
  { gltf_name, mapped_name }
}

///|
pub fn GltfCustomVertexAttribute::gltf_name(
  self : GltfCustomVertexAttribute,
) -> String {
  self.gltf_name
}

///|
pub fn GltfCustomVertexAttribute::mapped_name(
  self : GltfCustomVertexAttribute,
) -> String {
  self.mapped_name
}

///|
pub(all) struct GltfConvertCoordinates {
  rotate_scene_entity : Bool
  rotate_meshes : Bool
}

///|
pub fn gltf_convert_coordinates_vec3(value : @math.Vec3) -> @math.Vec3 {
  @math.Vec3::new(-value.x, value.y, -value.z)
}

///|
pub fn gltf_convert_coordinates_quat(value : @math.Quat) -> @math.Quat {
  @math.Quat::new(-value.x, value.y, -value.z, value.w)
}

///|
pub fn gltf_convert_coordinates_vec3_components(
  value : (Float, Float, Float),
) -> (Float, Float, Float) {
  (-value.0, value.1, -value.2)
}

///|
pub fn GltfConvertCoordinates::default() -> GltfConvertCoordinates {
  { rotate_scene_entity: false, rotate_meshes: false }
}

///|
fn gltf_coordinate_conversion_transform() -> @transform.Transform {
  @transform.Transform::from_rotation(@math.Quat::from_rotation_y(@math.pi()))
}

///|
pub fn GltfConvertCoordinates::scene_conversion_transform(
  self : GltfConvertCoordinates,
) -> @transform.Transform {
  if self.rotate_scene_entity {
    gltf_coordinate_conversion_transform()
  } else {
    @transform.Transform::identity()
  }
}

///|
pub fn GltfConvertCoordinates::mesh_conversion_transform(
  self : GltfConvertCoordinates,
) -> @transform.Transform {
  if self.rotate_meshes {
    gltf_coordinate_conversion_transform()
  } else {
    @transform.Transform::identity()
  }
}

///|
pub fn GltfConvertCoordinates::mesh_conversion_transform_inverse(
  self : GltfConvertCoordinates,
) -> @transform.Transform {
  self.mesh_conversion_transform()
}

///|
pub(all) enum GltfSkinnedMeshBoundsPolicy {
  BindPose
  Dynamic
  NoFrustumCulling
} derive(Eq)

///|
const GLTF_PLUGIN_NAME : String = "mgstudio.gltf.loader.GltfPlugin"

///|
pub fn GltfSkinnedMeshBoundsPolicy::default() -> GltfSkinnedMeshBoundsPolicy {
  Dynamic
}

///|
pub struct GltfPlugin {
  pbr_material_handler_enabled : Bool
  convert_coordinates : GltfConvertCoordinates
  custom_vertex_attributes : Array[GltfCustomVertexAttribute]
  extension_handlers : Array[GltfExtensionHandler]
  skinned_mesh_bounds_policy : GltfSkinnedMeshBoundsPolicy
}

///|
pub fn GltfPlugin::default() -> GltfPlugin {
  {
    pbr_material_handler_enabled: true,
    convert_coordinates: GltfConvertCoordinates::default(),
    custom_vertex_attributes: [],
    extension_handlers: [],
    skinned_mesh_bounds_policy: GltfSkinnedMeshBoundsPolicy::default(),
  }
}

///|
pub impl @app.PluginReplacement for GltfPlugin with plugin_name(_self) {
  GLTF_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for GltfPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    gltf_plugin_with(app, self)
  }
}

///|
pub fn GltfPlugin::with_pbr_material_handler_enabled(
  self : GltfPlugin,
  enabled : Bool,
) -> GltfPlugin {
  { ..self, pbr_material_handler_enabled: enabled }
}

///|
pub fn GltfPlugin::add_custom_vertex_attribute(
  self : GltfPlugin,
  gltf_name : String,
  mapped_name : String,
) -> GltfPlugin {
  {
    ..self,
    custom_vertex_attributes: [
      ..self.custom_vertex_attributes,
      GltfCustomVertexAttribute::new(gltf_name, mapped_name),
    ],
  }
}

///|
pub fn GltfPlugin::with_convert_coordinates(
  self : GltfPlugin,
  convert_coordinates : GltfConvertCoordinates,
) -> GltfPlugin {
  { ..self, convert_coordinates, }
}

///|
pub fn GltfPlugin::add_extension_handler(
  self : GltfPlugin,
  handler : GltfExtensionHandler,
) -> GltfPlugin {
  { ..self, extension_handlers: [..self.extension_handlers, handler] }
}

///|
pub fn GltfPlugin::with_skinned_mesh_bounds_policy(
  self : GltfPlugin,
  policy : GltfSkinnedMeshBoundsPolicy,
) -> GltfPlugin {
  { ..self, skinned_mesh_bounds_policy: policy }
}

///|
priv struct GltfLoaderPluginRuntimeState {
  mut registration : GltfLoaderRegistration?
  mut registered : Bool
}

///|
fn GltfLoaderPluginRuntimeState::from_bootstrap() -> GltfLoaderPluginRuntimeState {
  GltfLoaderPluginRuntimeState::{
    registration: gltf_loader_registration_bootstrap_ref.val,
    registered: gltf_loader_registered_bootstrap_ref.val,
  }
}

///|
pub struct GltfLoaderRuntimeState {
  mut default_convert_coordinates : GltfConvertCoordinates
  mut default_skinned_mesh_bounds_policy : GltfSkinnedMeshBoundsPolicy
  custom_vertex_attributes : Array[GltfCustomVertexAttribute]
}

///|
fn GltfLoaderRuntimeState::from_bootstrap() -> GltfLoaderRuntimeState {
  let custom_vertex_attributes : Array[GltfCustomVertexAttribute] = []
  for attribute in gltf_custom_vertex_attributes_bootstrap {
    custom_vertex_attributes.push(attribute)
  }
  GltfLoaderRuntimeState::{
    default_convert_coordinates: gltf_default_convert_coordinates_bootstrap_ref.val,
    default_skinned_mesh_bounds_policy: gltf_default_skinned_mesh_bounds_policy_bootstrap_ref.val,
    custom_vertex_attributes,
  }
}

///|
let gltf_loader_registration_bootstrap_ref : Ref[GltfLoaderRegistration?] = Ref::new(
  None,
)

///|
let gltf_loader_registered_bootstrap_ref : Ref[Bool] = Ref::new(false)

///|
let gltf_custom_vertex_attributes_bootstrap : Array[GltfCustomVertexAttribute] = []

///|
let gltf_default_convert_coordinates_bootstrap_ref : Ref[GltfConvertCoordinates] = Ref::new(
  GltfConvertCoordinates::default(),
)

///|
let gltf_default_skinned_mesh_bounds_policy_bootstrap_ref : Ref[
  GltfSkinnedMeshBoundsPolicy,
] = Ref::new(GltfSkinnedMeshBoundsPolicy::default())

///|
let ecs_res_key_gltf_loader_plugin_runtime_state : @ecs.ResourceKey[
  GltfLoaderPluginRuntimeState,
] = @ecs.register_resource(debug_name="gltf.loader.plugin_runtime_state")

///|
pub let ecs_res_key_gltf_loader_runtime_state : @ecs.ResourceKey[
  GltfLoaderRuntimeState,
] = @ecs.register_resource(debug_name="gltf.loader.runtime_state")

///|
pub impl @app.Resource for GltfLoaderRuntimeState with resource() {
  ecs_res_key_gltf_loader_runtime_state
}

///|
fn gltf_loader_plugin_runtime_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  if app.contains_resource(ecs_res_key_gltf_loader_plugin_runtime_state) {
    app
  } else {
    app.insert_world_resource(
      ecs_res_key_gltf_loader_plugin_runtime_state,
      GltfLoaderPluginRuntimeState::from_bootstrap(),
    )
  }
}

///|
fn gltf_loader_plugin_runtime_state_ref_if_present() -> Ref[
  GltfLoaderPluginRuntimeState,
]? {
  guard @app.current_world() is Some(world) else { return None }
  try! world.get_resource_ref_mut(ecs_res_key_gltf_loader_plugin_runtime_state)
}

///|
pub fn gltf_loader_runtime_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  if app.contains_resource(ecs_res_key_gltf_loader_runtime_state) {
    app
  } else {
    let next = app.insert_world_resource(
      ecs_res_key_gltf_loader_runtime_state,
      GltfLoaderRuntimeState::from_bootstrap(),
    )
    gltf_custom_vertex_attributes_bootstrap.clear()
    gltf_default_convert_coordinates_bootstrap_ref.val = GltfConvertCoordinates::default()
    gltf_default_skinned_mesh_bounds_policy_bootstrap_ref.val = GltfSkinnedMeshBoundsPolicy::default()
    next
  }
}

///|
fn gltf_loader_runtime_state_ref_if_present() -> Ref[GltfLoaderRuntimeState]? {
  guard @app.current_world() is Some(world) else { return None }
  try! world.get_resource_ref_mut(ecs_res_key_gltf_loader_runtime_state)
}

///|
fn gltf_attribute_name_matches(
  registered_name : String,
  attribute_name : String,
) -> Bool {
  if registered_name == attribute_name {
    return true
  }
  if attribute_name.length() > 0 && attribute_name.code_unit_at(0) == 95 {
    return registered_name ==
      attribute_name[1:attribute_name.length()].to_string()
  }
  false
}

///|
fn gltf_upsert_custom_vertex_attribute(
  registry : Array[GltfCustomVertexAttribute],
  name : String,
  mapped_name : String,
) -> Unit {
  for i in 0..<registry.length() {
    if registry[i].gltf_name() == name {
      registry[i] = GltfCustomVertexAttribute::new(name, mapped_name)
      return
    }
  }
  registry.push(GltfCustomVertexAttribute::new(name, mapped_name))
}

///|
pub fn gltf_add_custom_vertex_attribute(
  name : String,
  mapped_name : String,
) -> Unit {
  if gltf_loader_runtime_state_ref_if_present() is Some(state_ref) {
    gltf_upsert_custom_vertex_attribute(
      state_ref.val.custom_vertex_attributes,
      name,
      mapped_name,
    )
  } else {
    gltf_upsert_custom_vertex_attribute(
      gltf_custom_vertex_attributes_bootstrap, name, mapped_name,
    )
  }
}

///|
pub fn gltf_clear_custom_vertex_attributes() -> Unit {
  if gltf_loader_runtime_state_ref_if_present() is Some(state_ref) {
    state_ref.val.custom_vertex_attributes.clear()
  } else {
    gltf_custom_vertex_attributes_bootstrap.clear()
  }
}

///|
pub fn gltf_custom_vertex_attributes() -> Array[GltfCustomVertexAttribute] {
  if gltf_loader_runtime_state_ref_if_present() is Some(state_ref) {
    state_ref.val.custom_vertex_attributes
  } else {
    gltf_custom_vertex_attributes_bootstrap
  }
}

///|
pub fn gltf_install_loader_registration(
  registration : GltfLoaderRegistration,
) -> Unit {
  gltf_loader_registration_bootstrap_ref.val = Some(registration)
  gltf_loader_registered_bootstrap_ref.val = false
  if gltf_loader_plugin_runtime_state_ref_if_present() is Some(state_ref) {
    state_ref.val.registration = Some(registration)
    state_ref.val.registered = false
  }
}

///|
pub fn gltf_pbr_material_handler_enabled() -> Bool {
  @gltf_loader_extensions.gltf_pbr_material_handler_enabled()
}

///|
pub fn gltf_plugin_with(
  app : @app.App[@ecs.World],
  plugin : GltfPlugin,
) -> @app.App[@ecs.World] {
  gltf_set_pbr_material_handler_enabled(plugin.pbr_material_handler_enabled)
  gltf_set_default_convert_coordinates(plugin.convert_coordinates)
  gltf_set_default_skinned_mesh_bounds_policy(plugin.skinned_mesh_bounds_policy)
  gltf_clear_custom_vertex_attributes()
  for custom_attribute in plugin.custom_vertex_attributes {
    gltf_add_custom_vertex_attribute(
      custom_attribute.gltf_name(),
      custom_attribute.mapped_name(),
    )
  }
  @gltf_loader_extensions.gltf_clear_extension_handlers()
  for handler in plugin.extension_handlers {
    gltf_register_extension_handler(handler)
  }
  let app = @gltf_loader_extensions.gltf_extension_runtime_plugin(app)
  let app = gltf_loader_plugin_runtime_plugin(app)
  let app = gltf_loader_runtime_plugin(app)
  gltf_register_asset_loaders_once()
  app
}

///|
pub fn gltf_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  gltf_plugin_with(app, GltfPlugin::default())
}

///|
pub fn gltf_register_extension_handler(handler : GltfExtensionHandler) -> Unit {
  @gltf_loader_extensions.gltf_register_extension_handler(handler)
}

///|
pub fn gltf_resolve_custom_vertex_attribute_name(name : String) -> String? {
  for attribute in gltf_custom_vertex_attributes() {
    if gltf_attribute_name_matches(attribute.gltf_name(), name) {
      return Some(attribute.mapped_name())
    }
  }
  None
}

///|
pub fn gltf_set_pbr_material_handler_enabled(enabled : Bool) -> Unit {
  @gltf_loader_extensions.gltf_set_pbr_material_handler_enabled(enabled)
}

///|
pub fn gltf_default_skinned_mesh_bounds_policy() -> GltfSkinnedMeshBoundsPolicy {
  if gltf_loader_runtime_state_ref_if_present() is Some(state_ref) {
    state_ref.val.default_skinned_mesh_bounds_policy
  } else {
    gltf_default_skinned_mesh_bounds_policy_bootstrap_ref.val
  }
}

///|
pub fn gltf_set_default_skinned_mesh_bounds_policy(
  policy : GltfSkinnedMeshBoundsPolicy,
) -> Unit {
  if gltf_loader_runtime_state_ref_if_present() is Some(state_ref) {
    state_ref.val.default_skinned_mesh_bounds_policy = policy
  } else {
    gltf_default_skinned_mesh_bounds_policy_bootstrap_ref.val = policy
  }
}

///|
pub fn gltf_default_convert_coordinates() -> GltfConvertCoordinates {
  if gltf_loader_runtime_state_ref_if_present() is Some(state_ref) {
    state_ref.val.default_convert_coordinates
  } else {
    gltf_default_convert_coordinates_bootstrap_ref.val
  }
}

///|
pub fn gltf_set_default_convert_coordinates(
  convert_coordinates : GltfConvertCoordinates,
) -> Unit {
  if gltf_loader_runtime_state_ref_if_present() is Some(state_ref) {
    state_ref.val.default_convert_coordinates = convert_coordinates
  } else {
    gltf_default_convert_coordinates_bootstrap_ref.val = convert_coordinates
  }
}

///|
fn gltf_register_asset_loaders_once() -> Unit {
  if gltf_loader_plugin_runtime_state_ref_if_present() is Some(state_ref) {
    if state_ref.val.registered {
      return
    }
    let register = match state_ref.val.registration {
      Some(value) => value
      None =>
        abort(
          "gltf plugin loader registration is not installed; add scene loader wiring before running gltf_plugin",
        )
    }
    register()
    state_ref.val.registered = true
    gltf_loader_registered_bootstrap_ref.val = true
    return
  }
  if gltf_loader_registered_bootstrap_ref.val {
    return
  }
  let register = match gltf_loader_registration_bootstrap_ref.val {
    Some(value) => value
    None =>
      abort(
        "gltf plugin loader registration is not installed; add scene loader wiring before running gltf_plugin",
      )
  }
  register()
  gltf_loader_registered_bootstrap_ref.val = true
}

///|
pub fn gltf_extras(value : String) -> GltfExtras {
  @gltf_gltf_ext.gltf_extras(value)
}

///|
pub fn gltf_material_name(name : String) -> GltfMaterialName {
  @gltf_gltf_ext.gltf_material_name(name)
}

///|
pub fn gltf_material_extras(value : String) -> GltfMaterialExtras {
  @gltf_gltf_ext.gltf_material_extras(value)
}

///|
pub fn gltf_mesh_extras(value : String) -> GltfMeshExtras {
  @gltf_gltf_ext.gltf_mesh_extras(value)
}

///|
pub fn gltf_scene_extras(value : String) -> GltfSceneExtras {
  @gltf_gltf_ext.gltf_scene_extras(value)
}

///|
pub fn gltf_mesh_index(mesh_index : Int) -> GltfMeshIndex {
  @gltf_gltf_ext.gltf_mesh_index(mesh_index)
}

///|
pub fn gltf_primitive_index(
  mesh_index : Int,
  primitive_index : Int,
) -> GltfPrimitiveIndex {
  @gltf_gltf_ext.gltf_primitive_index(mesh_index, primitive_index)
}

///|
pub fn gltf_skin_index(skin_index : Int) -> GltfSkinIndex {
  @gltf_gltf_ext.gltf_skin_index(skin_index)
}

///|
pub fn gltf_scene_index(scene_index : Int) -> GltfSceneIndex {
  @gltf_gltf_ext.gltf_scene_index(scene_index)
}

///|
pub fn gltf_node_index(node_index : Int) -> GltfNodeIndex {
  @gltf_gltf_ext.gltf_node_index(node_index)
}

///|
pub fn gltf_scene_asset_label(scene_index : Int) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_scene_asset_label(scene_index)
}

///|
pub fn gltf_node_asset_label(node_index : Int) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_node_asset_label(node_index)
}

///|
pub fn gltf_mesh_asset_label(mesh_index : Int) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_mesh_asset_label(mesh_index)
}

///|
pub fn gltf_primitive_asset_label(
  mesh_index : Int,
  primitive_index : Int,
) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_primitive_asset_label(mesh_index, primitive_index)
}

///|
pub fn gltf_skin_asset_label(skin_index : Int) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_skin_asset_label(skin_index)
}

///|
pub fn gltf_material_asset_label(
  material_index : Int,
  is_scale_inverted : Bool,
) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_material_asset_label(material_index, is_scale_inverted)
}

///|
pub fn gltf_default_material_asset_label() -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_default_material_asset_label()
}

///|
pub fn gltf_animation_asset_label(animation_index : Int) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_animation_asset_label(animation_index)
}

///|
pub fn gltf_inverse_bind_matrices_asset_label(
  skin_index : Int,
) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_inverse_bind_matrices_asset_label(skin_index)
}

///|
pub fn gltf_texture_asset_label(texture_index : Int) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_texture_asset_label(texture_index)
}
