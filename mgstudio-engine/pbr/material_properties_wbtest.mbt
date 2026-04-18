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
  let material = StandardMaterial::default()
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
    props.shadows_enabled,
    content="true",
  )
}

///|
test "render3d: extended material metadata is reflected into extracted properties" {
  let material = StandardMaterial::default()
  let extension = @material.ExtendedMaterialMetadata3d::default()
    .with_disable_shadows(true)
    .with_shader_path(Some("shaders/extended_material.wgsl"))
  let props = render3d_material_properties_for_standard_material(
    material,
    Some(extension),
    OpaqueRendererMethod::Forward,
    true,
  )
  debug_inspect(!props.shadows_enabled, content="true")
  debug_inspect(
    props.get_shader("material.fragment"),
    content="Some(\"shaders/extended_material.wgsl\")",
  )
}

///|
test "render3d: extracted material properties prepass flag follows plugin runtime state" {
  let material = StandardMaterial::default()
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
