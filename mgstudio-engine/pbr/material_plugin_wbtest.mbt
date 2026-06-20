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
struct ParityCustomMaterial {
  color : Bytes
  texture : @asset.Handle[@asset.Image]?
}

///|
fn ParityCustomMaterial::ParityCustomMaterial() -> ParityCustomMaterial {
  ParityCustomMaterial::{
    color: Bytes::makei(4, fn(index) { (index + 1).to_byte() }),
    texture: Some(@asset.Handle::new(9)),
  }
}

///|
impl @asset.Asset for ParityCustomMaterial with fn asset_debug_name() {
  "mgstudio_pbr_test::ParityCustomMaterial"
}

///|
impl @asset.Asset for ParityCustomMaterial with fn asset_as_image(_self) {
  None
}

///|
let parity_custom_material_asset_keys : @asset.AssetResourceKeys[
  ParityCustomMaterial,
] = @asset.register_asset_resource_keys(
  ParityCustomMaterial::asset_debug_name(),
)

///|
impl @asset.Asset for ParityCustomMaterial with fn asset_resource_keys() {
  parity_custom_material_asset_keys
}

///|
let parity_custom_material_keys : MaterialKeys[ParityCustomMaterial] = register_material_keys(
  ParityCustomMaterial::asset_debug_name(),
)

///|
impl Material for ParityCustomMaterial with fn material_debug_name() {
  "mgstudio_pbr_test::ParityCustomMaterial"
}

///|
impl Material for ParityCustomMaterial with fn material_keys() {
  parity_custom_material_keys
}

///|
impl Material for ParityCustomMaterial with fn vertex_shader() {
  material_default_vertex_shader()
}

///|
impl Material for ParityCustomMaterial with fn fragment_shader() {
  Some("shaders/tonemapping_test_patterns.wgsl")
}

///|
impl Material for ParityCustomMaterial with fn prepass_vertex_shader() {
  material_default_vertex_shader()
}

///|
impl Material for ParityCustomMaterial with fn prepass_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ParityCustomMaterial with fn deferred_vertex_shader() {
  material_default_vertex_shader()
}

///|
impl Material for ParityCustomMaterial with fn deferred_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ParityCustomMaterial with fn meshlet_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ParityCustomMaterial with fn meshlet_prepass_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ParityCustomMaterial with fn meshlet_deferred_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ParityCustomMaterial with fn alpha_mode(self) {
  ignore(self)
  material_default_alpha_mode()
}

///|
impl Material for ParityCustomMaterial with fn opaque_render_method(self) {
  ignore(self)
  material_default_opaque_render_method()
}

///|
impl Material for ParityCustomMaterial with fn depth_bias(self) {
  ignore(self)
  material_default_depth_bias()
}

///|
impl Material for ParityCustomMaterial with fn reads_view_transmission_texture(
  self,
) {
  ignore(self)
  material_default_reads_view_transmission_texture()
}

///|
impl Material for ParityCustomMaterial with fn enable_prepass() {
  material_default_enable_prepass()
}

///|
impl Material for ParityCustomMaterial with fn enable_shadows() {
  material_default_enable_shadows()
}

///|
impl Material for ParityCustomMaterial with fn bind_group(self) {
  MaterialBindGroup::new([
    MaterialBinding::uniform(0, self.color),
    MaterialBinding::texture(1, self.texture),
    MaterialBinding::sampler(2, self.texture),
  ])
}

///|
impl Material for ParityCustomMaterial with fn specialize(
  descriptor,
  layout,
  key,
) {
  material_default_specialize(descriptor, layout, key)
}

///|
test "pbr material plugin: typed bind group owns uniform texture and sampler bindings" {
  let material = ParityCustomMaterial::ParityCustomMaterial()
  let bind_group = material.bind_group()
  inspect(
    bind_group.layout_key(),
    content="0:uniform;1:texture(float,2d);2:sampler",
  )
  inspect(
    bind_group.bind_group_data(),
    content="0:uniform(len=4:1,2,3,4);1:texture(9,float,2d);2:sampler(9)",
  )
  let resolved = bind_group.resolved_data().entries()
  inspect(resolved.length(), content="3")
  debug_inspect(
    match resolved[0].resource() {
      @render_resource.MaterialBindGroupResolvedResource::Uniform(bytes) =>
        bytes.length() == 4
      _ => false
    },
    content="true",
  )
  debug_inspect(
    match resolved[1].resource() {
      @render_resource.MaterialBindGroupResolvedResource::Texture(9) => true
      _ => false
    },
    content="true",
  )
  debug_inspect(
    match resolved[2].resource() {
      @render_resource.MaterialBindGroupResolvedResource::Sampler(9) => true
      _ => false
    },
    content="true",
  )
}

///|
test "pbr material plugin: prepared material carries shader hooks and typed bindings" {
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let material = ParityCustomMaterial::ParityCustomMaterial()
  let prepared = PreparedMaterial::from_material(
    @asset.Handle::new(7),
    material,
    material_pipeline_from_material_hooks(probe),
  )
  debug_inspect(
    prepared.properties().get_shader(@material.MATERIAL_FRAGMENT_SHADER_LABEL),
    content="Some(\"shaders/tonemapping_test_patterns.wgsl\")",
  )
  inspect(prepared.bind_group_data().entries().length(), content="3")
}

///|
test "pbr material plugin: plugin registers assets typed component and render resources" {
  let plugin : MaterialPlugin[ParityCustomMaterial] = MaterialPlugin::MaterialPlugin().with_asset_init(fn() {
      ParityCustomMaterial::ParityCustomMaterial()
    },
  )
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(plugin)
  let main_assets_key : @ecs.ResourceKey[@asset.Assets[ParityCustomMaterial]] = @asset.assets_resource_key()
  let render_pipeline_key : @ecs.ResourceKey[
    MaterialPipeline[ParityCustomMaterial],
  ] = MaterialPipeline::resource()
  let render_instances_key : @ecs.ResourceKey[
    RenderMaterial3dInstances[ParityCustomMaterial],
  ] = RenderMaterial3dInstances::resource()
  let prepared_assets_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial[ParityCustomMaterial]],
  ] = @render.RenderAssets::resource()
  let component_key : @ecs.ComponentKey[
    MeshMaterial3dTyped[ParityCustomMaterial],
  ] = MeshMaterial3dTyped::component()
  let render_world = app.sub_app(@app.RenderApp).world()
  debug_inspect(app.contains_resource(main_assets_key), content="true")
  debug_inspect(
    render_world.get_resource(render_pipeline_key) is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(render_instances_key) is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(prepared_assets_key) is Some(_),
    content="true",
  )
  inspect(
    component_key.debug_name(),
    content="mgstudio_pbr::MeshMaterial3d<mgstudio_pbr_test::ParityCustomMaterial>",
  )
}

///|
test "pbr material plugin: debug flags mirror Bevy plugin configuration" {
  let default_plugin : MaterialPlugin[ParityCustomMaterial] = MaterialPlugin::MaterialPlugin()
  inspect(
    default_plugin.debug_flags().allow_copies_from_indirect_parameters(),
    content="false",
  )
  let plugin = default_plugin.with_debug_flags(
    @render.RenderDebugFlags::RenderDebugFlags().with_allow_copies_from_indirect_parameters(
      true,
    ),
  )
  inspect(
    plugin.debug_flags().allow_copies_from_indirect_parameters(),
    content="true",
  )
}
