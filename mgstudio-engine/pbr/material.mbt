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
pub const MESH_PIPELINE_KEY_READS_VIEW_TRANSMISSION_TEXTURE : UInt64 = 0x0001UL

///|
fn render3d_material_properties_for_standard_material(
  material : StandardMaterial,
  extension : ExtendedMaterialMetadata3d?,
  default_opaque_renderer_method : OpaqueRendererMethod,
  prepass_enabled : Bool,
) -> @material.MaterialProperties {
  let render_method = standard_material_opaque_render_method(
    material, default_opaque_renderer_method,
  )
  let reads_view_transmission_texture = standard_material_reads_view_transmission_texture(
    material,
  )
  let mut mesh_pipeline_key_bits : UInt64 = 0UL
  if reads_view_transmission_texture {
    mesh_pipeline_key_bits = mesh_pipeline_key_bits |
      MESH_PIPELINE_KEY_READS_VIEW_TRANSMISSION_TEXTURE
  }
  let shadows_enabled = match extension {
    Some(metadata) => !metadata.disable_shadows
    None => true
  }
  let standard_material_key = standard_material_key_from_material(material)
  let mut properties = @material.MaterialProperties::default()
    .with_render_method(render_method)
    .with_alpha_mode(material.alpha_mode)
    .with_mesh_pipeline_key_bits(
      @material.ErasedMeshPipelineKey::new(
        mesh_pipeline_key_bits, "MeshPipelineKey",
      ),
    )
    .with_depth_bias(material.depth_bias)
    .with_reads_view_transmission_texture(reads_view_transmission_texture)
    .with_render_phase_type(standard_material_render_phase_type(material))
    .with_material_key(
      @material.ErasedMaterialKey::new(
        standard_material_key.bits(),
        "StandardMaterialKey",
      ),
    )
    .with_shadows_enabled(shadows_enabled)
    .with_prepass_enabled(prepass_enabled)
  if extension is Some(metadata) {
    if metadata.shader_path is Some(shader_path) {
      properties = properties.add_shader("material.fragment", shader_path)
    }
  }
  properties
}

///|
fn render3d_material_default_opaque_renderer_method(
  world : @ecs.World,
) -> OpaqueRendererMethod {
  match (try! world.get_resource(ecs_key_default_opaque_renderer_method)) {
    Some(default_method) => default_method.renderer_method()
    None => OpaqueRendererMethod::Forward
  }
}
