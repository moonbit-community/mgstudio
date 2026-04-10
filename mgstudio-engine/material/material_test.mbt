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
test "material boundary re-exports standard material APIs" {
  let material = @material.StandardMaterial::default()
    .with_metallic(0.25)
    .with_perceptual_roughness(0.75)
    .with_unlit(true)
    .with_alpha_mode(@material.AlphaMode::Blend)
  debug_inspect(material.metallic.to_double(), content="0.25")
  debug_inspect(material.perceptual_roughness.to_double(), content="0.75")
  debug_inspect(material.unlit, content="true")
  debug_inspect(
    material.alpha_mode is @material.AlphaMode::Blend,
    content="true",
  )
}

///|
test "material boundary re-exports material metadata APIs" {
  let metadata = @material.ExtendedMaterialMetadata3d::new(7)
    .with_disable_shadows(true)
    .with_shader_path(Some("shaders/custom/manual_material_3d.wgsl"))
  let forward_ext = @material.ForwardDecalMaterialExt::new(0.5)
  let renderer_method = @material.DefaultOpaqueRendererMethod::forward()
  let mesh_material = @material.MeshMaterial3d::new(@asset.Handle::new(42)).with_extension_shader_path(
    Some("shaders/custom/manual_material_3d.wgsl"),
  )
  debug_inspect(metadata.extension_tag, content="7")
  debug_inspect(metadata.disable_shadows, content="true")
  debug_inspect(
    metadata.shader_path,
    content="Some(\"shaders/custom/manual_material_3d.wgsl\")",
  )
  debug_inspect(forward_ext.depth_fade_factor.to_double(), content="0.5")
  debug_inspect(
    renderer_method.renderer_method() is @material.OpaqueRendererMethod::Forward,
    content="true",
  )
  debug_inspect(
    mesh_material.extended_material.map(fn(ext) { ext.shader_path }),
    content="Some(Some(\"shaders/custom/manual_material_3d.wgsl\"))",
  )
}

///|
test "material boundary resolves auto opaque render method at runtime" {
  let default_method = @material.OpaqueRendererMethod::Deferred
  let resolved_auto = @material.OpaqueRendererMethod::Auto.resolve_runtime(
    default_method,
  )
  let resolved_forward = @material.OpaqueRendererMethod::Forward.resolve_runtime(
    default_method,
  )
  debug_inspect(
    resolved_auto is @material.OpaqueRendererMethod::Deferred &&
    resolved_forward is @material.OpaqueRendererMethod::Forward,
    content="true",
  )
}

///|
test "material boundary Assets::add accepts Color and Image handle inputs" {
  let materials : @asset.Assets[@material.StandardMaterial] = @asset.Assets::new()
  let expected_color = @sprite.Color::srgb(0.1F, 0.2F, 0.3F)
  let color_handle = materials |> add(expected_color)
  let texture : @asset.Handle[@asset.Image] = @asset.Handle::new(7)
  let texture_handle = materials |> add(texture)
  let ok = if materials.get(color_handle) is Some(color_material) {
    if materials.get(texture_handle) is Some(texture_material) {
      color_material.base_color.r == expected_color.r &&
      color_material.base_color.g == expected_color.g &&
      color_material.base_color.b == expected_color.b &&
      texture_material.base_color_texture is Some(base_color_texture) &&
      base_color_texture.id() == 7
    } else {
      false
    }
  } else {
    false
  }
  debug_inspect(ok, content="true")
}
