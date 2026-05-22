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
    .with_alpha_mode(@material.AlphaMode3d::Mask(0.6F))
    .with_depth_bias(5.0F)
    .with_specular_transmission(0.4F)
  let props = render3d_material_properties_for_standard_material(
    material,
    None,
    OpaqueRendererMethod::Deferred,
    true,
  )
  debug_inspect(
    props.render_method is OpaqueRendererMethod::Deferred,
    content="true",
  )
  debug_inspect(
    props.render_phase_type is @material.RenderPhaseType::Transmissive,
    content="true",
  )
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
    @material.StandardMaterial::StandardMaterial(),
    None,
    OpaqueRendererMethod::Forward,
    true,
  )
  guard props.material_layout is Some(layout) else {
    abort("expected StandardMaterial material layout")
  }
  inspect(layout.label, content="StandardMaterial")
  inspect(layout.entries.length(), content="17")
  inspect(layout.entries[0].binding(), content="0")
  inspect(layout.entries[1].binding(), content="1")
  inspect(layout.entries[14].binding(), content="14")
  inspect(layout.entries[15].binding(), content="29")
  inspect(layout.entries[16].binding(), content="30")
  debug_inspect(
    match layout.entries[0].kind() {
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Uniform,
        false,
        192UL
      ) => true
      _ => false
    },
    content="true",
  )
  debug_inspect(
    match layout.entries[1].kind() {
      @render_resource.BindingType::TextureBinding(
        @render_resource.TextureSampleType::Float(true),
        @render_resource.TextureViewDimension::D2,
        false
      ) => true
      _ => false
    },
    content="true",
  )
  debug_inspect(
    match layout.entries[2].kind() {
      @render_resource.BindingType::SamplerBinding(
        @render_resource.SamplerBindingType::Filtering
      ) => true
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
    OpaqueRendererMethod::Forward,
    true,
  )
  debug_inspect(!props.shadows_enabled, content="true")
  debug_inspect(
    props.get_shader(@material.MATERIAL_FRAGMENT_SHADER_LABEL),
    content="Some(\"shaders/extended_material.wgsl\")",
  )
}

///|
test "render3d: extracted material properties prepass flag follows plugin runtime state" {
  let material = @material.StandardMaterial::StandardMaterial()
  let enabled_props = render3d_material_properties_for_standard_material(
    material,
    None,
    OpaqueRendererMethod::Forward,
    true,
  )
  let disabled_props = render3d_material_properties_for_standard_material(
    material,
    None,
    OpaqueRendererMethod::Forward,
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
  let properties = pbr_material_apply_draw_functions(
    @material.MaterialProperties::MaterialProperties(),
    ids,
  )
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
