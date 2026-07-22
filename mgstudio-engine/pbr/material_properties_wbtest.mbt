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
test "render3d: extracted material properties carry core bevy runtime fields" {
  let material = @material.StandardMaterial::StandardMaterial()
    .with_alpha_mode(Mask(0.6F))
    .with_depth_bias(5.0F)
    .with_specular_transmission(0.4F)
  let props = render3d_material_properties_for_standard_material(
    material,
    None,
    Deferred,
    true,
  )
  debug_inspect(props.render_method is Deferred, content="true")
  debug_inspect(props.render_phase_type is Transmissive, content="true")
  debug_inspect(
    props.reads_view_transmission_texture &&
    props.depth_bias == 5.0F &&
    props.shadows_enabled &&
    props.material_layout is Some(_),
    content="true",
  )
}

///|
test "render3d: standard material properties carry bevy material bind group layout" {
  let props = render3d_material_properties_for_standard_material(
    StandardMaterial(),
    None,
    Forward,
    true,
  )
  guard props.material_layout is Some(layout) else {
    abort("expected StandardMaterial material layout")
  }
  inspect(layout.label, content="StandardMaterial")
  debug_inspect(layout.entries.length(), content="15")
  debug_inspect(layout.entries[0].binding(), content="0")
  debug_inspect(layout.entries[1].binding(), content="1")
  debug_inspect(layout.entries[11].binding(), content="11")
  debug_inspect(layout.entries[12].binding(), content="12")
  debug_inspect(layout.entries[13].binding(), content="13")
  debug_inspect(layout.entries[14].binding(), content="14")
  debug_inspect(
    match layout.entries[0].kind() {
      BufferBinding(Uniform, false, 192UL) => true
      _ => false
    },
    content="true",
  )
  debug_inspect(
    match layout.entries[1].kind() {
      TextureBinding(Float(true), D2, false) => true
      _ => false
    },
    content="true",
  )
  debug_inspect(
    match layout.entries[2].kind() {
      SamplerBinding(Filtering) => true
      _ => false
    },
    content="true",
  )
}

///|
test "render3d: extended material metadata is reflected into extracted properties" {
  let material = @material.StandardMaterial::StandardMaterial()
  let extension = @material.ExtendedMaterialMetadata3d::ExtendedMaterialMetadata3d()
    .with_disable_shadows(true)
    .with_fragment_shader_path(Some("shaders/extended_material.wgsl"))
  let props = render3d_material_properties_for_standard_material(
    material,
    Some(extension),
    Forward,
    true,
  )
  debug_inspect(!props.shadows_enabled, content="true")
  debug_inspect(
    props.get_shader(@material.MATERIAL_FRAGMENT_SHADER_LABEL),
    content="Some(\"shaders/extended_material.wgsl\")",
  )
}

///|
struct ParityMaterialExtension {}

///|
#warnings("-unnecessary_annotation")
fn ParityMaterialExtension::ParityMaterialExtension() -> ParityMaterialExtension {
  ParityMaterialExtension::{  }
}

///|
impl MaterialExtension for ParityMaterialExtension with fn extension_tag(_self) {
  87
}

///|
impl MaterialExtension for ParityMaterialExtension with fn vertex_shader(_self) {
  None
}

///|
impl MaterialExtension for ParityMaterialExtension with fn fragment_shader(
  _self,
) {
  Some("shaders/extended_material.wgsl")
}

///|
impl MaterialExtension for ParityMaterialExtension with fn prepass_vertex_shader(
  _self,
) {
  None
}

///|
impl MaterialExtension for ParityMaterialExtension with fn prepass_fragment_shader(
  _self,
) {
  None
}

///|
impl MaterialExtension for ParityMaterialExtension with fn deferred_vertex_shader(
  _self,
) {
  None
}

///|
impl MaterialExtension for ParityMaterialExtension with fn deferred_fragment_shader(
  _self,
) {
  Some("shaders/deferred_extended_material.wgsl")
}

///|
impl MaterialExtension for ParityMaterialExtension with fn alpha_mode(_self) {
  None
}

///|
impl MaterialExtension for ParityMaterialExtension with fn opaque_render_method(
  _self,
) {
  None
}

///|
impl MaterialExtension for ParityMaterialExtension with fn enable_prepass(_self) {
  true
}

///|
impl MaterialExtension for ParityMaterialExtension with fn enable_shadows(_self) {
  true
}

///|
impl MaterialExtension for ParityMaterialExtension with fn specialize(_self) {
  None
}

///|
impl MaterialExtension for ParityMaterialExtension with fn bind_group_layout_entries(
  _self,
) {
  []
}

///|
impl MaterialExtension for ParityMaterialExtension with fn bind_group_bindings(
  _self,
) {
  []
}

///|
let parity_extended_material_asset_keys : @asset.AssetResourceKeys[
  ExtendedMaterial[StandardMaterial, ParityMaterialExtension],
] = @asset.register_asset_resource_keys(
  "mgstudio_pbr_test::ExtendedMaterial<StandardMaterial, ParityMaterialExtension>",
)

///|
let parity_extended_material_keys : MaterialKeys[
  ExtendedMaterial[StandardMaterial, ParityMaterialExtension],
] = register_material_keys(
  "mgstudio_pbr_test::ExtendedMaterial<StandardMaterial, ParityMaterialExtension>",
)

///|
impl StandardMaterialExtension for ParityMaterialExtension with fn extended_material_asset_debug_name() {
  "mgstudio_pbr_test::ExtendedMaterial<StandardMaterial, ParityMaterialExtension>"
}

///|
impl StandardMaterialExtension for ParityMaterialExtension with fn extended_material_asset_keys() {
  parity_extended_material_asset_keys
}

///|
impl StandardMaterialExtension for ParityMaterialExtension with fn extended_material_keys() {
  parity_extended_material_keys
}

///|
impl StandardMaterialExtension for ParityMaterialExtension with fn vertex_shader_ref() {
  standard_material_extension_default_vertex_shader_ref()
}

///|
impl StandardMaterialExtension for ParityMaterialExtension with fn fragment_shader_ref() {
  Some("shaders/extended_material.wgsl")
}

///|
impl StandardMaterialExtension for ParityMaterialExtension with fn prepass_vertex_shader_ref() {
  standard_material_extension_default_prepass_vertex_shader_ref()
}

///|
impl StandardMaterialExtension for ParityMaterialExtension with fn prepass_fragment_shader_ref() {
  standard_material_extension_default_prepass_fragment_shader_ref()
}

///|
impl StandardMaterialExtension for ParityMaterialExtension with fn deferred_vertex_shader_ref() {
  standard_material_extension_default_deferred_vertex_shader_ref()
}

///|
impl StandardMaterialExtension for ParityMaterialExtension with fn deferred_fragment_shader_ref() {
  Some("shaders/deferred_extended_material.wgsl")
}

///|
impl StandardMaterialExtension for ParityMaterialExtension with fn meshlet_fragment_shader_ref() {
  standard_material_extension_default_meshlet_fragment_shader_ref()
}

///|
impl StandardMaterialExtension for ParityMaterialExtension with fn meshlet_prepass_fragment_shader_ref() {
  standard_material_extension_default_meshlet_prepass_fragment_shader_ref()
}

///|
impl StandardMaterialExtension for ParityMaterialExtension with fn meshlet_deferred_fragment_shader_ref() {
  standard_material_extension_default_meshlet_deferred_fragment_shader_ref()
}

///|
impl StandardMaterialExtension for ParityMaterialExtension with fn enable_prepass_ref() {
  standard_material_extension_default_enable_prepass_ref()
}

///|
impl StandardMaterialExtension for ParityMaterialExtension with fn enable_shadows_ref() {
  standard_material_extension_default_enable_shadows_ref()
}

///|
impl StandardMaterialExtension for ParityMaterialExtension with fn specialize_ref() {
  standard_material_extension_default_specialize_ref()
}

///|
struct ParityNoPrepassMaterialExtension {}

///|
#warnings("-unnecessary_annotation")
fn ParityNoPrepassMaterialExtension::ParityNoPrepassMaterialExtension() -> ParityNoPrepassMaterialExtension {
  ParityNoPrepassMaterialExtension::{  }
}

///|
impl MaterialExtension for ParityNoPrepassMaterialExtension with fn extension_tag(
  _self,
) {
  88
}

///|
impl MaterialExtension for ParityNoPrepassMaterialExtension with fn vertex_shader(
  _self,
) {
  None
}

///|
impl MaterialExtension for ParityNoPrepassMaterialExtension with fn fragment_shader(
  _self,
) {
  Some("shaders/extended_material.wgsl")
}

///|
impl MaterialExtension for ParityNoPrepassMaterialExtension with fn prepass_vertex_shader(
  _self,
) {
  None
}

///|
impl MaterialExtension for ParityNoPrepassMaterialExtension with fn prepass_fragment_shader(
  _self,
) {
  None
}

///|
impl MaterialExtension for ParityNoPrepassMaterialExtension with fn deferred_vertex_shader(
  _self,
) {
  None
}

///|
impl MaterialExtension for ParityNoPrepassMaterialExtension with fn deferred_fragment_shader(
  _self,
) {
  None
}

///|
impl MaterialExtension for ParityNoPrepassMaterialExtension with fn alpha_mode(
  _self,
) {
  None
}

///|
impl MaterialExtension for ParityNoPrepassMaterialExtension with fn opaque_render_method(
  _self,
) {
  None
}

///|
impl MaterialExtension for ParityNoPrepassMaterialExtension with fn enable_prepass(
  _self,
) {
  false
}

///|
impl MaterialExtension for ParityNoPrepassMaterialExtension with fn enable_shadows(
  _self,
) {
  true
}

///|
impl MaterialExtension for ParityNoPrepassMaterialExtension with fn specialize(
  _self,
) {
  None
}

///|
impl MaterialExtension for ParityNoPrepassMaterialExtension with fn bind_group_layout_entries(
  _self,
) {
  []
}

///|
impl MaterialExtension for ParityNoPrepassMaterialExtension with fn bind_group_bindings(
  _self,
) {
  []
}

///|
test "render3d: material extension prepass flag does not require camera prepasses" {
  let metadata = material_extension_metadata_from_extension(
    ParityMaterialExtension::ParityMaterialExtension(),
  )
  inspect(metadata.requires_depth_prepass, content="false")
  inspect(metadata.requires_deferred_prepass, content="false")
  inspect(metadata.prepass_enabled, content="true")
  let props = render3d_material_properties_for_standard_material(
    StandardMaterial(),
    Some(metadata),
    Forward,
    true,
  )
  inspect(props.prepass_enabled, content="true")
  debug_inspect(
    props.get_shader(@material.MATERIAL_FRAGMENT_SHADER_LABEL),
    content="Some(\"shaders/extended_material.wgsl\")",
  )
}

///|
test "pbr material plugin: prepared extended material preserves runtime metadata" {
  let material = ExtendedMaterial::new(
    StandardMaterial::StandardMaterial(),
    ParityMaterialExtension::ParityMaterialExtension(),
  )
  let material_handle : @asset.Handle[
    ExtendedMaterial[StandardMaterial, ParityMaterialExtension],
  ] = @asset.Handle::new(987)
  let probe : @asset.Handle[
    ExtendedMaterial[StandardMaterial, ParityMaterialExtension],
  ] = @asset.Handle::new(0)
  let prepared = PreparedMaterial::from_material(
    material_handle,
    material,
    material_pipeline_from_material_hooks(probe),
    Deferred,
  )
  let resolved = prepared.resolved_material()
  guard resolved.material_extension() is Some(metadata) else {
    abort("typed ExtendedMaterial must preserve extension metadata")
  }
  inspect(metadata.extension_tag, content="87")
  debug_inspect(
    metadata.fragment_shader_path,
    content="Some(\"shaders/extended_material.wgsl\")",
  )
  debug_inspect(
    metadata.deferred_fragment_shader_path,
    content="Some(\"shaders/deferred_extended_material.wgsl\")",
  )
}

///|
test "render3d: material extension prepass disabled follows Bevy prepared material properties" {
  let metadata = material_extension_metadata_from_extension(
    ParityNoPrepassMaterialExtension::ParityNoPrepassMaterialExtension(),
  )
  inspect(metadata.requires_depth_prepass, content="false")
  inspect(metadata.requires_deferred_prepass, content="false")
  inspect(metadata.prepass_enabled, content="false")
  let props = render3d_material_properties_for_standard_material(
    StandardMaterial(),
    Some(metadata),
    Forward,
    true,
  )
  inspect(props.prepass_enabled, content="false")
  debug_inspect(
    pbr_prepass_material_specialization_decision(
      props,
      0UL,
      MESH_PIPELINE_KEY_DEPTH_PREPASS,
    )
    is Remove,
    content="true",
  )
  let disabled_by_plugin = render3d_material_properties_for_standard_material(
    StandardMaterial(),
    Some(
      material_extension_metadata_from_extension(
        ParityMaterialExtension::ParityMaterialExtension(),
      ),
    ),
    Forward,
    false,
  )
  inspect(disabled_by_plugin.prepass_enabled, content="false")
  debug_inspect(
    props.get_shader(@material.MATERIAL_FRAGMENT_SHADER_LABEL),
    content="Some(\"shaders/extended_material.wgsl\")",
  )
}

///|
test "render3d: forward decal material extension metadata matches Bevy hooks" {
  let metadata = forward_decal_material_extension_metadata(
    ForwardDecalMaterialExt::new(1.0F),
  )
  let props = render3d_material_properties_for_standard_material(
    StandardMaterial(),
    Some(metadata),
    Deferred,
    true,
  )
  debug_inspect(props.alpha_mode is Blend, content="true")
  debug_inspect(props.render_phase_type is Transparent, content="true")
  debug_inspect(props.render_method is Forward, content="true")
  debug_inspect(!props.shadows_enabled, content="true")
  debug_inspect(props.prepass_enabled, content="true")
}

///|
fn shader_defs_has_flag(
  shader_defs : Array[@material.ShaderDefVal],
  expected : String,
) -> Bool {
  for shader_def in shader_defs {
    if shader_def is Flag(name) && name == expected {
      return true
    }
  }
  false
}

///|
test "render3d: forward decal extension specialize mutates descriptor like Bevy" {
  let metadata = forward_decal_material_extension_metadata(
    ForwardDecalMaterialExt::new(1.0F),
  )
  guard metadata.user_specialize is Some(user_specialize) else {
    fail("forward decal metadata must carry a descriptor specialize hook")
  }
  let descriptor = @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor()
    .with_label(Some("opaque_mesh_pipeline"))
    .with_depth_stencil(
      Some(
        @render_resource.DepthStencilState::new(
          @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
          true,
          @wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
        ),
      ),
    )
    .with_vertex(
      @render_resource.VertexState::new(
        Some("pbr/render/mesh.wgsl"),
        [Flag("VERTEX_TANGENTS")],
        None,
        [],
      ),
    )
    .with_fragment(
      Some(
        @render_resource.FragmentState::new(
          Some("pbr/render/pbr.wgsl"),
          [Flag("VERTEX_TANGENTS")],
          None,
          [],
        ),
      ),
    )
  let specialized = try! @material.material_specialize_user(
    user_specialize,
    "PbrMaterialPipeline",
    descriptor,
    pbr_material_specializer_test_layout(),
    pbr_material_specializer_test_key(),
  )
  debug_inspect(
    specialized.label,
    content="Some(\"forward_decal_opaque_mesh_pipeline\")",
  )
  debug_inspect(
    specialized.depth_stencil.map(fn(state) { state.depth_compare }),
    content="Some(8)",
  )
  debug_inspect(
    shader_defs_has_flag(specialized.vertex.shader_defs, "VERTEX_TANGENTS"),
    content="true",
  )
  debug_inspect(
    shader_defs_has_flag(specialized.vertex.shader_defs, "FORWARD_DECAL"),
    content="true",
  )
  let fragment = specialized.fragment.unwrap()
  debug_inspect(
    shader_defs_has_flag(fragment.shader_defs, "VERTEX_TANGENTS"),
    content="true",
  )
  debug_inspect(
    shader_defs_has_flag(fragment.shader_defs, "FORWARD_DECAL"),
    content="true",
  )
}

///|
test "render3d: standard material properties carry Bevy meshlet shader labels" {
  let props = render3d_material_properties_for_standard_material(
    StandardMaterial(),
    None,
    Forward,
    true,
  )
  debug_inspect(
    props.get_shader(@material.MESHLET_FRAGMENT_SHADER_LABEL),
    content="Some(\"pbr/render/pbr.wgsl\")",
  )
  debug_inspect(
    props.get_shader(@material.MESHLET_PREPASS_FRAGMENT_SHADER_LABEL),
    content="Some(\"pbr/render/pbr_prepass.wgsl\")",
  )
  debug_inspect(
    props.get_shader(@material.MESHLET_DEFERRED_FRAGMENT_SHADER_LABEL),
    content="Some(\"pbr/render/pbr.wgsl\")",
  )
}

///|
test "render3d: material extension can override Bevy meshlet shader labels" {
  let extension = @material.ExtendedMaterialMetadata3d::ExtendedMaterialMetadata3d().with_meshlet_fragment_shader_path(
    Some("pbr/meshlet/meshlet_mesh_material.wgsl"),
  )
  let props = render3d_material_properties_for_standard_material(
    StandardMaterial(),
    Some(extension),
    Forward,
    true,
  )
  debug_inspect(
    props.get_shader(@material.MESHLET_FRAGMENT_SHADER_LABEL),
    content="Some(\"pbr/meshlet/meshlet_mesh_material.wgsl\")",
  )
}

///|
test "render3d: extracted material properties prepass flag follows plugin runtime state" {
  let material = @material.StandardMaterial::StandardMaterial()
  let enabled_props = render3d_material_properties_for_standard_material(
    material,
    None,
    Forward,
    true,
  )
  let disabled_props = render3d_material_properties_for_standard_material(
    material,
    None,
    Forward,
    false,
  )
  debug_inspect(enabled_props.prepass_enabled, content="true")
  debug_inspect(disabled_props.prepass_enabled, content="false")
}

///|
test "render3d: pbr material draw function labels mirror bevy prepared material order" {
  let labels = pbr_material_draw_function_labels()
  inspect(labels.length(), content="11")
  inspect(labels[0], content="MainPassOpaqueDrawFunction")
  inspect(labels[1], content="MainPassAlphaMaskDrawFunction")
  inspect(labels[2], content="MainPassTransmissiveDrawFunction")
  inspect(labels[3], content="MainPassTransparentDrawFunction")
  inspect(labels[4], content="PrepassOpaqueDrawFunction")
  inspect(labels[5], content="PrepassAlphaMaskDrawFunction")
  inspect(labels[6], content="PrepassOpaqueDepthOnlyDrawFunction")
  inspect(labels[7], content="DeferredOpaqueDrawFunction")
  inspect(labels[8], content="DeferredAlphaMaskDrawFunction")
  inspect(labels[9], content="ShadowsDrawFunction")
  inspect(labels[10], content="ShadowsDepthOnlyDrawFunction")
}

///|
test "render3d: pbr material properties can carry bevy draw function ids" {
  let draw_functions = @material.DrawFunctions::new()
  let ids = pbr_material_register_draw_functions(draw_functions)
  inspect(draw_functions.len(), content="11")
  let properties = pbr_material_apply_draw_functions(MaterialProperties(), ids)
  debug_inspect(
    properties
    .get_draw_function(MAIN_PASS_OPAQUE_DRAW_FUNCTION_LABEL)
    .map(fn(id) { id.id() }),
    content="Some(0)",
  )
  debug_inspect(
    properties
    .get_draw_function(DEFERRED_ALPHA_MASK_DRAW_FUNCTION_LABEL)
    .map(fn(id) { id.id() }),
    content="Some(8)",
  )
  debug_inspect(
    properties
    .get_draw_function(SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL)
    .map(fn(id) { id.id() }),
    content="Some(10)",
  )
}

///|
test "render3d: standard material properties carry default bevy draw functions" {
  let properties = render3d_material_properties_for_standard_material(
    StandardMaterial(),
    None,
    Deferred,
    true,
  )
  debug_inspect(
    properties
    .get_draw_function(DEFERRED_OPAQUE_DRAW_FUNCTION_LABEL)
    .map(fn(id) { id.id() }),
    content="Some(7)",
  )
  debug_inspect(
    properties
    .get_draw_function(PREPASS_OPAQUE_DEPTH_ONLY_DRAW_FUNCTION_LABEL)
    .map(fn(id) { id.id() }),
    content="Some(6)",
  )
  debug_inspect(
    properties
    .get_draw_function(SHADOWS_DRAW_FUNCTION_LABEL)
    .map(fn(id) { id.id() }),
    content="Some(9)",
  )
}
