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
    @material.DefaultOpaqueRendererMethod::DefaultOpaqueRendererMethod().renderer_method()
    is @material.OpaqueRendererMethod::Forward,
    content="true",
  )
}

///|
test "material boundary re-exports standard material APIs" {
  let material = @material.StandardMaterial::StandardMaterial()
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
test "mesh material carries its Bevy material family identity" {
  let standard = @material.MeshMaterial3d::new(@asset.Handle::new(42))
  inspect(
    standard.material_family is @material.Material3dFamily::Standard,
    content="true",
  )
  inspect(standard.material_asset_id(), content="42")
  let meshlet_debug = @material.MeshMaterial3d::from_erased_material_id(
    @material.Material3dFamily::MeshletDebug,
    7,
  )
  inspect(
    meshlet_debug.material_family is @material.Material3dFamily::MeshletDebug,
    content="true",
  )
  inspect(meshlet_debug.material_asset_id(), content="7")
  inspect(meshlet_debug.is_standard_material(), content="false")
}

///|
test "standard material defaults align with bevy clearcoat and alpha threshold" {
  let default_material = @material.StandardMaterial::StandardMaterial()
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
test "standard material flip helpers keep bevy uv left-multiply semantics" {
  let sample = @math.Vec2::new(0.25F, 0.6F)
  let horizontal = @material.StandardMaterial::StandardMaterial().flip(
    true, false,
  )
  let horizontal_uv = horizontal.uv_transform.transform_point2(sample)
  debug_inspect(
    material_test_nearly_equal(horizontal_uv.x, 0.75F),
    content="true",
  )
  debug_inspect(
    material_test_nearly_equal(horizontal_uv.y, 0.6F),
    content="true",
  )
  let vertical = @material.StandardMaterial::StandardMaterial().flip(
    false, true,
  )
  let vertical_uv = vertical.uv_transform.transform_point2(sample)
  debug_inspect(
    material_test_nearly_equal(vertical_uv.x, 0.25F),
    content="true",
  )
  debug_inspect(material_test_nearly_equal(vertical_uv.y, 0.4F), content="true")
  let hv = @material.StandardMaterial::StandardMaterial().flipped(true, true)
  let hv_uv = hv.uv_transform.transform_point2(sample)
  debug_inspect(material_test_nearly_equal(hv_uv.x, 0.75F), content="true")
  debug_inspect(material_test_nearly_equal(hv_uv.y, 0.4F), content="true")
}

///|
test "material boundary re-exports material metadata APIs" {
  let metadata = @material.ExtendedMaterialMetadata3d::new(7)
    .with_disable_shadows(true)
    .with_fragment_shader_path(Some("shaders/manual_material.wgsl"))
  let forward_ext = @material.ForwardDecalMaterialExt::new(0.5)
  let renderer_method = @material.DefaultOpaqueRendererMethod::forward()
  let mesh_material = @material.MeshMaterial3d::new(@asset.Handle::new(42)).with_extension_fragment_shader_path(
    Some("shaders/manual_material.wgsl"),
  )
  debug_inspect(metadata.extension_tag, content="7")
  debug_inspect(metadata.disable_shadows, content="true")
  debug_inspect(
    metadata.fragment_shader_path,
    content="Some(\"shaders/manual_material.wgsl\")",
  )
  debug_inspect(forward_ext.depth_fade_factor.to_double(), content="0.5")
  debug_inspect(
    renderer_method.renderer_method() is @material.OpaqueRendererMethod::Forward,
    content="true",
  )
  debug_inspect(
    mesh_material.extended_material.map(fn(ext) { ext.fragment_shader_path }),
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
  let descriptor = @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor().set_layout(
    2, layout,
  )
  inspect(descriptor.layout.length(), content="3")
  let fragment = @render_resource.FragmentState::FragmentState().set_target(
    1,
    @material.ColorTargetState::new(
      @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
      @wgpu.COLOR_WRITE_MASK_ALL,
    ),
  )
  inspect(fragment.targets.length(), content="2")
  let default_descriptor = @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor()
  let default_fragment = @render_resource.FragmentState::FragmentState()
  inspect(default_descriptor.zero_initialize_workgroup_memory, content="true")
  inspect(default_fragment.targets.length(), content="0")
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
  let properties = @material.MaterialProperties::MaterialProperties()
    .with_material_layout(Some(layout))
    .with_bindless(true)
  debug_inspect(
    properties.material_layout.map(fn(layout0) { layout0.label }) ==
    Some("material.layout"),
    content="true",
  )
  inspect(properties.bindless, content="true")
}

///|
test "material boundary defaults mirror bevy derived MaterialProperties default" {
  let properties = @material.MaterialProperties::MaterialProperties()
  inspect(properties.shadows_enabled, content="false")
  inspect(properties.prepass_enabled, content="false")
  inspect(
    properties.render_method is @material.OpaqueRendererMethod::Forward,
    content="true",
  )
  inspect(properties.alpha_mode is @material.AlphaMode::Opaque, content="true")
  inspect(
    @material.AlphaMode3d::default() is @material.AlphaMode::Opaque,
    content="true",
  )
  inspect(
    @material.OpaqueRendererMethod::default()
    is @material.OpaqueRendererMethod::Forward,
    content="true",
  )
  inspect(
    @material.RenderPhaseType::default() is @material.RenderPhaseType::Opaque,
    content="true",
  )
}

///|
test "material boundary exposes bevy-shaped erased key + properties helpers" {
  let mesh_key = @material.ErasedMeshPipelineKey::new(7UL, "MeshKey")
  let material_key = @material.ErasedMaterialKey::new(1UL, "MaterialKey")
  let pipeline_key = @material.ErasedMaterialPipelineKey::new(
    mesh_key, material_key, "PipelineKey",
  )
  let properties = @material.MaterialProperties::MaterialProperties()
    .add_shader("main.fragment", "shaders/pbr.wgsl")
    .add_draw_function("main.opaque", @material.DrawFunctionId::new(3U))
  inspect(mesh_key.downcast_u64("MeshKey"), content="7")
  inspect(pipeline_key.type_tag(), content="PipelineKey")
  inspect(pipeline_key.mesh_key() == mesh_key, content="true")
  inspect(pipeline_key.material_key() == material_key, content="true")
  inspect(material_key.type_tag(), content="MaterialKey")
  debug_inspect(
    properties.get_shader("main.fragment") == Some("shaders/pbr.wgsl"),
    content="true",
  )
  debug_inspect(
    properties.get_draw_function("main.opaque").map(fn(draw) { draw.id() }) ==
    Some(3U),
    content="true",
  )
}

///|
test "material boundary draw functions register stable ids by label" {
  let draw_functions = @material.DrawFunctions::new()
  let opaque_id = draw_functions.register("MainPassOpaqueDrawFunction")
  let transparent = draw_functions.register("MainPassTransparentDrawFunction")
  let duplicate = draw_functions.register("MainPassOpaqueDrawFunction")
  inspect(opaque_id.id(), content="0")
  inspect(transparent.id(), content="1")
  inspect(duplicate.id(), content="0")
  inspect(draw_functions.len(), content="2")
  debug_inspect(
    draw_functions.id("MainPassTransparentDrawFunction").map(fn(id) { id.id() }),
    content="Some(1)",
  )
  inspect(draw_functions.labels()[0], content="MainPassOpaqueDrawFunction")
  inspect(draw_functions.labels()[1], content="MainPassTransparentDrawFunction")
}

///|
test "material boundary dynamic bind group layout entries mirror bevy builder flow" {
  let texture = @material.bind_group_layout_entry_builder(
    @render_resource.BindingType::Texture,
  )
  let sampler = @material.bind_group_layout_entry_builder(
    @render_resource.BindingType::Sampler,
  )
  let dynamic = @material.dynamic_bind_group_layout_entries_sequential(
      @wgpu.SHADER_STAGE_FRAGMENT.to_uint(),
      [texture],
    )
    .extend_sequential([sampler])
    .extend_with_indices([
      (7, texture.visibility(@wgpu.SHADER_STAGE_VERTEX.to_uint())),
    ])
  let entries = dynamic.entries()
  inspect(entries.length(), content="3")
  inspect(entries[0].binding(), content="0")
  inspect(entries[1].binding(), content="1")
  inspect(entries[2].binding(), content="7")
  inspect(entries[2].visibility(), content="1")
  inspect(entries[2].count(), content="0")
  let counted = @material.bind_group_layout_entries_single(
    @wgpu.SHADER_STAGE_FRAGMENT.to_uint(),
    texture.count(4U),
  )
  inspect(counted[0].count(), content="4")
}

///|
fn material_test_base_specialize(
  _world : @ecs.World,
  _key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
  _properties : @material.MaterialProperties,
) -> @material.CachedRenderPipelineId raise @material.SpecializedMeshPipelineError {
  if layout.index() < 0 {
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
  if layout.index() < 0 {
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
  if layout.index() < 0 {
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
fn material_test_mesh_vertex_layout(
  include_unused_attribute? : Bool = false,
) -> @material.MaterialMeshVertexLayout {
  let layouts = @mesh.MeshVertexBufferLayouts::MeshVertexBufferLayouts()
  let attribute_ids = [@mesh.MeshVertexAttribute::position().id()]
  let attributes = [
    @mesh.VertexAttribute::new(
      offset=0,
      format=@mesh.MeshVertexFormat::Float32x3,
      shader_location=0,
    ),
  ]
  if include_unused_attribute {
    attribute_ids.push(@mesh.MeshVertexAttribute::normal().id())
    attributes.push(
      @mesh.VertexAttribute::new(
        offset=0,
        format=@mesh.MeshVertexFormat::Float32x3,
        shader_location=1,
      ),
    )
  }
  layouts.insert(
    @mesh.MeshVertexBufferLayout::new(
      attribute_ids~,
      layout=@mesh.VertexBufferLayout::new(
        array_stride=12,
        step_mode=@mesh.MeshVertexStepMode::Vertex,
        attributes~,
      ),
    ),
  )
}

///|
test "material boundary carries bevy specialize callbacks in material properties" {
  let mesh_key = @material.ErasedMeshPipelineKey::new(9UL, "MeshKey")
  let material_key = @material.ErasedMaterialKey::new(3UL, "MaterialKey")
  let pipeline_key = @material.ErasedMaterialPipelineKey::new(
    mesh_key, material_key, "PipelineKey",
  )
  let world = @ecs.World::new()
  let properties = @material.MaterialProperties::MaterialProperties()
    .with_base_specialize(Some(material_test_base_specialize))
    .with_prepass_specialize(Some(material_test_prepass_specialize))
    .with_user_specialize(Some(material_test_user_specialize))
  let layout = material_test_mesh_vertex_layout()
  let base_id = match properties.base_specialize {
    Some(base_specialize) =>
      (try! @material.material_specialize_base(
        base_specialize, world, pipeline_key, layout, properties,
      )).id()
    None => 0UL
  }
  let prepass_id = match properties.prepass_specialize {
    Some(prepass_specialize) =>
      (try! @material.material_specialize_prepass(
        prepass_specialize, world, pipeline_key, layout, properties,
      )).id()
    None => 0UL
  }
  let user_layout_label : String = match properties.user_specialize {
    Some(user_specialize) =>
      (try! @material.material_specialize_user(
        user_specialize,
        "user.specialize",
        @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor(),
        layout,
        pipeline_key,
      )).layout[0].label
    None => ""
  }
  inspect(base_id, content="11")
  inspect(prepass_id, content="12")
  inspect(user_layout_label, content="user.specialize")
}

///|
fn material_test_specialized_mesh_pipeline(
  _key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
) -> @material.RenderPipelineDescriptor raise @material.SpecializedMeshPipelineError {
  let vertex_layout = match
    layout
    .layout()
    .get_layout([
      @mesh.VertexAttributeDescriptor::new(
        shader_location=0,
        id=@mesh.MeshVertexAttribute::position().id(),
        name="Vertex_Position",
      ),
    ]) {
    Ok(vertex_layout) => vertex_layout
    Err(error) =>
      raise @material.specialized_mesh_pipeline_missing_vertex_attribute_error(
        error,
      )
  }
  @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor().with_vertex(
    @material.VertexState::new(None, [], None, [vertex_layout]),
  )
}

///|
test "specialized mesh pipelines deduplicate final vertex layouts like bevy" {
  let mesh_key = @material.ErasedMeshPipelineKey::new(13UL, "MeshKey")
  let material_key = @material.ErasedMaterialKey::new(5UL, "MaterialKey")
  let pipeline_key = @material.ErasedMaterialPipelineKey::new(
    mesh_key, material_key, "PipelineKey",
  )
  let pipelines = @material.SpecializedMeshPipelines::new()
  let first_layout = material_test_mesh_vertex_layout()
  let second_layout = material_test_mesh_vertex_layout(
    include_unused_attribute=true,
  )
  let first_id = try! pipelines.specialize(
    material_test_specialized_mesh_pipeline, pipeline_key, first_layout,
  )
  let same_mesh_layout_id = try! pipelines.specialize(
    material_test_specialized_mesh_pipeline, pipeline_key, first_layout,
  )
  let compatible_vertex_layout_id = try! pipelines.specialize(
    material_test_specialized_mesh_pipeline, pipeline_key, second_layout,
  )
  inspect(first_id.id(), content="0")
  inspect(same_mesh_layout_id.id(), content="0")
  inspect(compatible_vertex_layout_id.id(), content="0")
  inspect(pipelines.mesh_layout_cache_len(), content="2")
  inspect(pipelines.vertex_layout_cache_len(), content="1")
  inspect(
    pipelines.render_pipeline_descriptor(first_id) is Some(_),
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

///|
fn material_test_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn material_test_nearly_equal(lhs : Float, rhs : Float) -> Bool {
  material_test_abs(lhs - rhs) <= 1.0e-5F
}
