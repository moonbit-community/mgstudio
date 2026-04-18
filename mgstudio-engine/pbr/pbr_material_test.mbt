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
test "pbr material: key encodes common standard material toggles" {
  let material = StandardMaterial::default()
    .with_base_color_texture(Some(@asset.Handle::new(1)))
    .with_emissive_texture(Some(@asset.Handle::new(2)))
    .with_normal_map_texture(Some(@asset.Handle::new(3)))
    .with_diffuse_transmission(0.4)
    .with_specular_transmission(0.2)
  let key = standard_material_key_from_material(material)
  inspect(
    key.contains(STANDARD_MATERIAL_KEY_BASE_COLOR_TEXTURE),
    content="true",
  )
  inspect(key.contains(STANDARD_MATERIAL_KEY_EMISSIVE_TEXTURE), content="true")
  inspect(key.contains(STANDARD_MATERIAL_KEY_NORMAL_MAP), content="true")
  inspect(
    key.contains(STANDARD_MATERIAL_KEY_DIFFUSE_TRANSMISSION),
    content="true",
  )
  inspect(
    key.contains(STANDARD_MATERIAL_KEY_SPECULAR_TRANSMISSION),
    content="true",
  )
}

///|
test "pbr material: key depth bias roundtrips" {
  let key = StandardMaterialKey::empty().with_depth_bias(42U)
  inspect(key.depth_bias(), content="42")
}

///|
test "pbr material: auto opaque renderer method follows bevy diffuse transmission override" {
  let deferred_default = @material.OpaqueRendererMethod::Deferred
  let auto_material = StandardMaterial::default()
  let auto_deferred = standard_material_opaque_render_method(
    auto_material, deferred_default,
  )
  inspect(
    auto_deferred is @material.OpaqueRendererMethod::Deferred,
    content="true",
  )
  let diffuse_transmissive_auto = StandardMaterial::default().with_diffuse_transmission(
    0.5F,
  )
  let auto_forced_forward = standard_material_opaque_render_method(
    diffuse_transmissive_auto, deferred_default,
  )
  inspect(
    auto_forced_forward is @material.OpaqueRendererMethod::Forward,
    content="true",
  )
}

///|
test "pbr material: reads_view_transmission_texture follows specular transmission only" {
  let diffuse_only = StandardMaterial::default().with_diffuse_transmission(0.7F)
  let specular_only = StandardMaterial::default().with_specular_transmission(
    0.2F,
  )
  inspect(
    standard_material_reads_view_transmission_texture(diffuse_only),
    content="false",
  )
  inspect(
    standard_material_reads_view_transmission_texture(specular_only),
    content="true",
  )
}

///|
test "pbr material: render phase type matches bevy ordering" {
  let transparent = StandardMaterial::default()
    .with_alpha_mode(@material.AlphaMode3d::Blend)
    .with_specular_transmission(1.0F)
  let transmissive = StandardMaterial::default().with_specular_transmission(
    1.0F,
  )
  let alpha_mask = StandardMaterial::default().with_alpha_mode(
    @material.AlphaMode3d::Mask(0.5F),
  )
  let opaque_material = StandardMaterial::default()
  inspect(
    standard_material_render_phase_type(transparent)
    is @material.RenderPhaseType::Transparent,
    content="true",
  )
  inspect(
    standard_material_render_phase_type(transmissive)
    is @material.RenderPhaseType::Transmissive,
    content="true",
  )
  inspect(
    standard_material_render_phase_type(alpha_mask)
    is @material.RenderPhaseType::AlphaMask,
    content="true",
  )
  inspect(
    standard_material_render_phase_type(opaque_material)
    is @material.RenderPhaseType::Opaque,
    content="true",
  )
}
