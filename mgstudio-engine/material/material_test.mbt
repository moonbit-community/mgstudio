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
test "material boundary matches bevy opaque renderer defaults" {
  inspect(
    @material.OpaqueRendererMethod::default()
    is @material.OpaqueRendererMethod::Forward,
    content="true",
  )
  inspect(
    @material.DefaultOpaqueRendererMethod::default().renderer_method()
    is @material.OpaqueRendererMethod::Forward,
    content="true",
  )
}

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
test "standard material defaults align with bevy clearcoat and alpha threshold" {
  let default_material = @material.StandardMaterial::default()
  debug_inspect(
    default_material.clearcoat_perceptual_roughness.to_double(),
    content="0.5",
  )
  let blend_material = @material.StandardMaterial::from_color(
    @sprite.Color::new(1.0F, 1.0F, 1.0F, 0.9999F),
  )
  let opaque_material = @material.StandardMaterial::from_color(
    @sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
  )
  debug_inspect(
    blend_material.alpha_mode is @material.AlphaMode::Blend,
    content="true",
  )
  debug_inspect(
    opaque_material.alpha_mode is @material.AlphaMode::Opaque,
    content="true",
  )
}

///|
test "material boundary re-exports material metadata APIs" {
  let metadata = @material.ExtendedMaterialMetadata3d::new(7)
    .with_disable_shadows(true)
    .with_shader_path(Some("shaders/manual_material.wgsl"))
  let forward_ext = @material.ForwardDecalMaterialExt::new(0.5)
  let renderer_method = @material.DefaultOpaqueRendererMethod::forward()
  let mesh_material = @material.MeshMaterial3d::new(@asset.Handle::new(42)).with_extension_shader_path(
    Some("shaders/manual_material.wgsl"),
  )
  debug_inspect(metadata.extension_tag, content="7")
  debug_inspect(metadata.disable_shadows, content="true")
  debug_inspect(
    metadata.shader_path,
    content="Some(\"shaders/manual_material.wgsl\")",
  )
  debug_inspect(forward_ext.depth_fade_factor.to_double(), content="0.5")
  debug_inspect(
    renderer_method.renderer_method() is @material.OpaqueRendererMethod::Forward,
    content="true",
  )
  debug_inspect(
    mesh_material.extended_material.map(fn(ext) { ext.shader_path }),
    content="Some(Some(\"shaders/manual_material.wgsl\"))",
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
test "material boundary exposes bevy-shaped render phase type" {
  let default_phase = @material.RenderPhaseType::default()
  let alpha_mask_phase : @material.MaterialRenderPhaseType = @material.RenderPhaseType::AlphaMask
  let transmissive_phase : @material.MaterialRenderPhaseType = @material.RenderPhaseType::Transmissive
  let transparent_phase : @material.MaterialRenderPhaseType = @material.RenderPhaseType::Transparent
  debug_inspect(
    default_phase is @material.RenderPhaseType::Opaque,
    content="true",
  )
  debug_inspect(
    alpha_mask_phase is @material.RenderPhaseType::AlphaMask,
    content="true",
  )
  debug_inspect(
    transmissive_phase is @material.RenderPhaseType::Transmissive,
    content="true",
  )
  debug_inspect(
    transparent_phase is @material.RenderPhaseType::Transparent,
    content="true",
  )
}

///|
test "material boundary descriptor helpers match bevy layout/target behavior" {
  let entry = @render_resource.BindGroupLayoutEntry::new(
    0,
    @wgpu.SHADER_STAGE_FRAGMENT.to_uint(),
    @render_resource.BindingType::Texture,
  )
  let layout = @material.BindGroupLayoutDescriptor::new("material.layout", [
    entry,
  ])
  let descriptor = @material.RenderPipelineDescriptor::default().set_layout(
    2, layout,
  )
  inspect(descriptor.layout.length(), content="3")
  let fragment = @material.FragmentState::default().set_target(
    1,
    @material.ColorTargetState::new(
      @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
      @wgpu.COLOR_WRITE_MASK_ALL,
    ),
  )
  inspect(fragment.targets.length(), content="2")
}

///|
test "material boundary includes material layout and bindless property builders" {
  let layout_entry = @render_resource.BindGroupLayoutEntry::new(
    0,
    @wgpu.SHADER_STAGE_FRAGMENT.to_uint(),
    @render_resource.BindingType::Texture,
  )
  let layout = @material.BindGroupLayoutDescriptor::new("material.layout", [
    layout_entry,
  ])
  let properties = @material.MaterialProperties::default()
    .with_material_layout(Some(layout))
    .with_bindless(true)
  inspect(
    properties.material_layout.map(fn(layout0) { layout0.label }),
    content="Some(\"material.layout\")",
  )
  inspect(properties.bindless, content="true")
}

///|
test "material boundary exposes bevy-shaped erased key + properties helpers" {
  let mesh_key = @material.ErasedMeshPipelineKey::new(7UL, "MeshKey")
  let material_key = @material.ErasedMaterialKey::new(
    ("albedo", 1),
    "MaterialKey",
  )
  let pipeline_key = @material.ErasedMaterialPipelineKey::new(
    mesh_key, material_key, "PipelineKey",
  )
  let properties = @material.MaterialProperties::default()
    .add_shader("main.fragment", "shaders/pbr.wgsl")
    .add_draw_function("main.opaque", @material.DrawFunctionId::new(3U))
  inspect(mesh_key.downcast_u64("MeshKey"), content="7")
  inspect(pipeline_key.type_tag, content="PipelineKey")
  inspect(material_key.type_tag(), content="MaterialKey")
  inspect(
    properties.get_shader("main.fragment"),
    content="Some(\"shaders/pbr.wgsl\")",
  )
  inspect(
    properties.get_draw_function("main.opaque").map(fn(draw) { draw.id() }),
    content="Some(3)",
  )
}

///|
fn material_test_base_specialize(
  _world : @ecs.World,
  _key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
  _properties : @material.MaterialProperties,
) -> @material.CachedRenderPipelineId raise @material.SpecializedMeshPipelineError {
  if layout < 0 {
    raise @material.missing_vertex_attribute_error("layout")
  }
  @material.CachedRenderPipelineId::new(11UL)
}

///|
fn material_test_prepass_specialize(
  _world : @ecs.World,
  _key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
  _properties : @material.MaterialProperties,
) -> @material.CachedRenderPipelineId raise @material.SpecializedMeshPipelineError {
  if layout < 0 {
    raise @material.missing_vertex_attribute_error("layout")
  }
  @material.CachedRenderPipelineId::new(12UL)
}

///|
fn material_test_user_specialize(
  user_key : String,
  descriptor : @material.RenderPipelineDescriptor,
  layout : @material.MaterialMeshVertexLayout,
  _key : @material.ErasedMaterialPipelineKey,
) -> @material.RenderPipelineDescriptor raise @material.SpecializedMeshPipelineError {
  if layout < 0 {
    raise @material.missing_vertex_attribute_error("layout")
  }
  let entry = @render_resource.BindGroupLayoutEntry::new(
    0,
    @wgpu.SHADER_STAGE_FRAGMENT.to_uint(),
    @render_resource.BindingType::Texture,
  )
  descriptor.set_layout(
    0,
    @material.BindGroupLayoutDescriptor::new(user_key, [entry]),
  )
}

///|
test "material boundary carries bevy specialize callbacks in material properties" {
  let mesh_key = @material.ErasedMeshPipelineKey::new(9UL, "MeshKey")
  let material_key = @material.ErasedMaterialKey::new(3, "MaterialKey")
  let pipeline_key = @material.ErasedMaterialPipelineKey::new(
    mesh_key, material_key, "PipelineKey",
  )
  let world = @ecs.World::new()
  let properties = @material.MaterialProperties::default()
    .with_base_specialize(Some(material_test_base_specialize))
    .with_prepass_specialize(Some(material_test_prepass_specialize))
    .with_user_specialize(Some(material_test_user_specialize))
  let base_id = match properties.base_specialize {
    Some(base_specialize) =>
      (try! @material.material_specialize_base(
        base_specialize, world, pipeline_key, 0, properties,
      )).id()
    None => 0UL
  }
  let prepass_id = match properties.prepass_specialize {
    Some(prepass_specialize) =>
      (try! @material.material_specialize_prepass(
        prepass_specialize, world, pipeline_key, 0, properties,
      )).id()
    None => 0UL
  }
  let user_layout_label : String = match properties.user_specialize {
    Some(user_specialize) =>
      (try! @material.material_specialize_user(
        user_specialize,
        "user.specialize",
        @material.RenderPipelineDescriptor::default(),
        0,
        pipeline_key,
      )).layout[0].label
    None => ""
  }
  inspect(base_id, content="11")
  inspect(prepass_id, content="12")
  inspect(user_layout_label, content="user.specialize")
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
