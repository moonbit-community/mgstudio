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
pub const MATERIAL_BIND_GROUP_INDEX : Int = 3

///|
const MATERIALS_PLUGIN_NAME : String = "mgstudio.pbr.MaterialsPlugin"

///|
pub struct MaterialsPlugin {}

///|
pub fn MaterialsPlugin::default() -> MaterialsPlugin {
  MaterialsPlugin::{  }
}

///|
pub struct MaterialsPluginState {}

///|
pub fn MaterialsPluginState::default() -> MaterialsPluginState {
  MaterialsPluginState::{  }
}

///|
pub fn MaterialsPluginState::new() -> MaterialsPluginState {
  MaterialsPluginState::default()
}

///|
pub let ecs_key_materials_plugin_state : @ecs.ResourceKey[MaterialsPluginState] = @ecs.register_resource(
  debug_name="mgstudio_pbr::MaterialsPluginState",
)

///|
fn init_materials_resources(world : @ecs.World) -> Unit {
  let default_opaque_renderer_method = get_default_opaque_renderer_method_resource(
    world,
  )
  if !default_opaque_renderer_method.is_present() {
    default_opaque_renderer_method.insert(
      DefaultOpaqueRendererMethod::forward(),
    )
  }
}

///|
pub impl @app.Plugin for MaterialsPlugin with name(_self) {
  MATERIALS_PLUGIN_NAME
}

///|
pub impl @app.Plugin for MaterialsPlugin with build(_self, app) {
  materials_plugin_install(app)
}

///|
pub fn materials_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_plugins(MaterialsPlugin::default())
}

///|
fn materials_plugin_install(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let app = if app.contains_resource(ecs_key_materials_plugin_state) {
    app
  } else {
    app
    .insert_world_resource(ecs_key_materials_plugin_state, MaterialsPluginState::{

    })
    .add_startup_system(init_materials_resources)
  }
  @pbr_prepass.prepass_plugin(app)
}

///|
pub fn pbr_material_bind_group_index() -> Int {
  MATERIAL_BIND_GROUP_INDEX
}

///|
pub fn pbr_materials_plugin_state_default() -> MaterialsPluginState {
  MaterialsPluginState::default()
}

///|
pub fn pbr_materials_plugin_state_new() -> MaterialsPluginState {
  MaterialsPluginState::new()
}

///|
pub fn pbr_materials_plugin_default() -> MaterialsPlugin {
  MaterialsPlugin::default()
}

///|
pub struct ExtractedMaterialInstance3d {
  entity : @core.Entity
  alpha_mode : AlphaMode3d
  opaque_render_method : OpaqueRendererMethod
  unlit : Bool
  extension_tag : Int?
  extension_shader_path : String?
}

///|
pub struct ExtractedMaterialInstances3d {
  mut by_entity_id : Map[Int, ExtractedMaterialInstance3d]
}

///|
pub fn ExtractedMaterialInstances3d::default() -> ExtractedMaterialInstances3d {
  ExtractedMaterialInstances3d::{ by_entity_id: {} }
}

///|
pub let ecs_key_extracted_material_instances_3d : @ecs.ResourceKey[
  ExtractedMaterialInstances3d,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::ExtractedMaterialInstances3d",
)

///|
pub impl @app.Resource for ExtractedMaterialInstances3d with resource() {
  ecs_key_extracted_material_instances_3d
}

///|
fn render3d_extracted_material_extension_tag(
  extension : ExtendedMaterialMetadata3d?,
) -> Int? {
  match extension {
    Some(metadata) => Some(metadata.extension_tag)
    None => None
  }
}

///|
fn render3d_extracted_material_extension_shader_path(
  extension : ExtendedMaterialMetadata3d?,
) -> String? {
  match extension {
    Some(metadata) => metadata.shader_path
    None => None
  }
}

///|
fn render3d_extracted_material_instance_for_mesh(
  mesh : ExtractedMesh3d,
) -> ExtractedMaterialInstance3d {
  let material = mesh.payload.material
  let extension = mesh.payload.material_extension
  let opaque_render_method = material.opaque_render_method.resolve_runtime(
    OpaqueRendererMethod::Forward,
  )
  ExtractedMaterialInstance3d::{
    entity: mesh.entity.main_entity,
    alpha_mode: material.alpha_mode,
    opaque_render_method,
    unlit: material.unlit,
    extension_tag: render3d_extracted_material_extension_tag(extension),
    extension_shader_path: render3d_extracted_material_extension_shader_path(
      extension,
    ),
  }
}

///|
fn render3d_extracted_material_entity_id(entity : @core.Entity) -> Int {
  entity.id * 131 + entity.generation
}

///|
fn render3d_extracted_material_instances_ref_or_init(
  world : @ecs.World,
) -> Ref[ExtractedMaterialInstances3d] {
  if (try! world.get_resource(ExtractedMaterialInstances3d::resource())) is None {
    world.insert_resource(
      ExtractedMaterialInstances3d::resource(),
      ExtractedMaterialInstances3d::default(),
    )
  }
  match
    (try! world.get_resource_ref_mut(ExtractedMaterialInstances3d::resource())) {
    Some(v) => v
    None => abort("Missing ExtractedMaterialInstances3d resource")
  }
}

///|
fn render3d_extract_material_instances(
  world : @ecs.World,
  meshes : Array[ExtractedMesh3d],
) -> Unit {
  let extracted_ref = render3d_extracted_material_instances_ref_or_init(world)
  let next : Map[Int, ExtractedMaterialInstance3d] = {}
  for mesh in meshes {
    let instance = render3d_extracted_material_instance_for_mesh(mesh)
    let entity_id = render3d_extracted_material_entity_id(instance.entity)
    next.set(entity_id, instance)
  }
  extracted_ref.val.by_entity_id = next
}

///|
pub fn render3d_material_instance_for_entity(
  world : @ecs.World,
  entity : @core.Entity,
) -> ExtractedMaterialInstance3d? {
  match (try! world.get_resource(ExtractedMaterialInstances3d::resource())) {
    Some(instances) =>
      instances.by_entity_id.get(render3d_extracted_material_entity_id(entity))
    None => None
  }
}
