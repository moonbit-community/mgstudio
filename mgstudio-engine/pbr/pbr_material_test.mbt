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
  let material = @material.StandardMaterial::StandardMaterial()
    .with_base_color_texture(Some(@asset.Handle::new(1)))
    .with_emissive_texture(Some(@asset.Handle::new(2)))
    .with_normal_map_texture(Some(@asset.Handle::new(3)))
    .with_diffuse_transmission(0.4)
    .with_specular_transmission(0.2)
    .with_depth_bias(7.0)
  let key = standard_material_key_from_material(material)
  inspect(key.contains(STANDARD_MATERIAL_KEY_BASE_COLOR_UV), content="false")
  inspect(key.contains(STANDARD_MATERIAL_KEY_EMISSIVE_UV), content="false")
  inspect(
    key.contains(STANDARD_MATERIAL_KEY_METALLIC_ROUGHNESS_UV),
    content="false",
  )
  inspect(key.contains(STANDARD_MATERIAL_KEY_OCCLUSION_UV), content="false")
  inspect(key.contains(STANDARD_MATERIAL_KEY_NORMAL_MAP), content="true")
  inspect(
    key.contains(STANDARD_MATERIAL_KEY_DIFFUSE_TRANSMISSION),
    content="true",
  )
  inspect(
    key.contains(STANDARD_MATERIAL_KEY_SPECULAR_TRANSMISSION),
    content="true",
  )
  inspect(key.depth_bias(), content="7")
}

///|
test "pbr material: key matches Bevy clearcoat and anisotropy predicates" {
  let clearcoat_normal_without_clearcoat = @material.StandardMaterial::StandardMaterial().with_clearcoat_normal_texture(
    Some(@asset.Handle::new(1)),
  )
  let clearcoat_normal_key = standard_material_key_from_material(
    clearcoat_normal_without_clearcoat,
  )
  inspect(
    clearcoat_normal_key.contains(STANDARD_MATERIAL_KEY_CLEARCOAT_NORMAL_MAP),
    content="false",
  )
  let clearcoat_normal_with_clearcoat = clearcoat_normal_without_clearcoat.with_clearcoat(
    0.5F,
  )
  let clearcoat_key = standard_material_key_from_material(
    clearcoat_normal_with_clearcoat,
  )
  inspect(
    clearcoat_key.contains(STANDARD_MATERIAL_KEY_CLEARCOAT_NORMAL_MAP),
    content="true",
  )
  let negative_anisotropy = @material.StandardMaterial::StandardMaterial().with_anisotropy_strength(
    -1.0F,
  )
  let negative_anisotropy_key = standard_material_key_from_material(
    negative_anisotropy,
  )
  inspect(
    negative_anisotropy_key.contains(STANDARD_MATERIAL_KEY_ANISOTROPY),
    content="false",
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
  let auto_material = @material.StandardMaterial::StandardMaterial()
  let auto_deferred = standard_material_opaque_render_method(
    auto_material, deferred_default,
  )
  inspect(
    auto_deferred is @material.OpaqueRendererMethod::Deferred,
    content="true",
  )
  let diffuse_transmissive_auto = @material.StandardMaterial::StandardMaterial().with_diffuse_transmission(
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
  let diffuse_only = @material.StandardMaterial::StandardMaterial().with_diffuse_transmission(
    0.7F,
  )
  let specular_only = @material.StandardMaterial::StandardMaterial().with_specular_transmission(
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
  let transparent = @material.StandardMaterial::StandardMaterial()
    .with_alpha_mode(@material.AlphaMode3d::Blend)
    .with_specular_transmission(1.0F)
  let transmissive = @material.StandardMaterial::StandardMaterial().with_specular_transmission(
    1.0F,
  )
  let alpha_mask = @material.StandardMaterial::StandardMaterial().with_alpha_mode(
    @material.AlphaMode3d::Mask(0.5F),
  )
  let opaque_material = @material.StandardMaterial::StandardMaterial()
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

///|
test "pbr material: standard material plugin plan mirrors material plugin build surface" {
  let plan = standard_material_plugin_plan(
    StandardMaterialPlugin::StandardMaterialPlugin(),
  )
  inspect(plan.prepass_enabled(), content="true")
  inspect(
    plan.debug_flags().allow_copies_from_indirect_parameters(),
    content="false",
  )
  inspect(plan.shadows_enabled(), content="true")
  inspect(plan.main_world_steps().length(), content="4")
  inspect(plan.post_update_steps().length(), content="2")
  inspect(plan.render_startup_steps().length(), content="1")
  inspect(plan.extract_schedule_steps().length(), content="4")
  inspect(plan.main_world_steps()[0], content="init_asset<StandardMaterial>")
  inspect(
    plan.main_world_steps()[3],
    content="add_plugin<ErasedRenderAssetPlugin<MeshMaterial3d<StandardMaterial>>>",
  )
  inspect(
    plan.post_update_steps()[1],
    content="check_entities_needing_specialization<StandardMaterial>",
  )
  inspect(
    plan.render_startup_steps()[0],
    content="add_material_bind_group_allocator<StandardMaterial>",
  )
  inspect(
    plan.extract_schedule_steps()[3],
    content="extract_entities_that_need_specializations_removed<StandardMaterial>",
  )
}

///|
test "pbr material: standard material plugin state retains build plan" {
  let plugin = StandardMaterialPlugin::StandardMaterialPlugin()
    .with_prepass_enabled(false)
    .with_debug_flags(
      @render.RenderDebugFlags::RenderDebugFlags().with_allow_copies_from_indirect_parameters(
        true,
      ),
    )
  let state = StandardMaterialPluginState::from_plugin(plugin)
  let plan = state.plan()
  inspect(
    state.debug_flags().allow_copies_from_indirect_parameters(),
    content="true",
  )
  inspect(plan.prepass_enabled(), content="false")
  inspect(
    plan.debug_flags().allow_copies_from_indirect_parameters(),
    content="true",
  )
  inspect(
    plan.extract_schedule_steps()[0],
    content="extract_mesh_materials<StandardMaterial>",
  )
}

///|
test "pbr material: standard material plugin state retains texture feature set" {
  let features = StandardMaterialTextureFeatureSet::StandardMaterialTextureFeatureSet(
    pbr_anisotropy_texture=true,
    pbr_specular_textures=true,
  )
  let plugin = StandardMaterialPlugin::StandardMaterialPlugin().with_standard_material_texture_features(
    features,
  )
  let state = StandardMaterialPluginState::from_plugin(plugin)
  inspect(
    state.standard_material_texture_features() == features,
    content="true",
  )
  inspect(
    state.plan().standard_material_texture_features() == features,
    content="true",
  )
}

///|
fn pbr_material_test_f32_bits(value : Float) -> UInt {
  value.reinterpret_as_uint()
}

///|
fn pbr_material_test_u32le_word(bytes : Bytes, index : Int) -> UInt {
  let offset = index * 4
  bytes[offset].to_uint() |
  (bytes[offset + 1].to_uint() << 8) |
  (bytes[offset + 2].to_uint() << 16) |
  (bytes[offset + 3].to_uint() << 24)
}

///|
test "pbr material: standard material uniform bytes match Bevy WGSL layout" {
  let material = @material.StandardMaterial::StandardMaterial()
    .with_base_color(@color.Color::new(0.25F, 0.5F, 0.75F, 0.875F))
    .with_emissive(@color.Color::new(1.0F, 2.0F, 3.0F, 0.0F))
    .with_base_color_texture(Some(@asset.Handle::new(1)))
    .with_normal_map_texture(Some(@asset.Handle::new(2)))
    .with_flip_normal_map_y(true)
    .with_uv_transform(
      @transform.Affine2::from_cols(
        @math.Vec2::new(2.0F, 3.0F),
        @math.Vec2::new(4.0F, 5.0F),
        @math.Vec2::new(6.0F, 7.0F),
      ),
    )
    .with_reflectance(0.25F)
    .with_specular_tint(@color.Color::new(0.5F, 0.25F, 0.125F, 1.0F))
    .with_perceptual_roughness(0.625F)
    .with_metallic(0.75F)
    .with_diffuse_transmission(0.25F)
    .with_specular_transmission(0.5F)
    .with_thickness(0.375F)
    .with_ior(1.25F)
    .with_clearcoat(0.125F)
    .with_clearcoat_perceptual_roughness(0.25F)
    .with_anisotropy_strength(0.5F)
    .with_alpha_mode(@material.AlphaMode3d::Mask(0.375F))
  let uniform = standard_material_uniform_from_material(material, true)
  let bytes = uniform.to_bytes()
  inspect(bytes.length(), content="192")
  inspect(
    pbr_material_test_u32le_word(bytes, 0),
    content=pbr_material_test_f32_bits(0.25F).to_string(),
  )
  inspect(
    pbr_material_test_u32le_word(bytes, 7),
    content=pbr_material_test_f32_bits(0.0F).to_string(),
  )
  inspect(
    pbr_material_test_u32le_word(bytes, 12),
    content=pbr_material_test_f32_bits(2.0F).to_string(),
  )
  inspect(
    pbr_material_test_u32le_word(bytes, 16),
    content=pbr_material_test_f32_bits(4.0F).to_string(),
  )
  inspect(
    pbr_material_test_u32le_word(bytes, 20),
    content=pbr_material_test_f32_bits(6.0F).to_string(),
  )
  inspect(
    pbr_material_test_u32le_word(bytes, 22),
    content=pbr_material_test_f32_bits(1.0F).to_string(),
  )
  inspect(
    pbr_material_test_u32le_word(bytes, 24),
    content=pbr_material_test_f32_bits(0.125F).to_string(),
  )
  inspect(
    pbr_material_test_u32le_word(bytes, 27),
    content=pbr_material_test_f32_bits(0.625F).to_string(),
  )
  inspect(
    pbr_material_test_u32le_word(bytes, 36),
    content=pbr_material_test_f32_bits(0.5F).to_string(),
  )
  inspect(
    pbr_material_test_u32le_word(bytes, 38),
    content=pbr_material_test_f32_bits(1.0F).to_string(),
  )
  inspect(
    (
      pbr_material_test_u32le_word(bytes, 40) &
      @pbr_render.STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT
    ) !=
    0U,
    content="true",
  )
  inspect(
    (
      pbr_material_test_u32le_word(bytes, 40) &
      @pbr_render.STANDARD_MATERIAL_FLAGS_TWO_COMPONENT_NORMAL_MAP
    ) !=
    0U,
    content="true",
  )
  inspect(
    (
      pbr_material_test_u32le_word(bytes, 40) &
      @pbr_render.STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y
    ) !=
    0U,
    content="true",
  )
  inspect(
    pbr_material_test_u32le_word(bytes, 41),
    content=pbr_material_test_f32_bits(0.375F).to_string(),
  )
  inspect(pbr_material_test_u32le_word(bytes, 45), content="0")
  inspect(pbr_material_test_u32le_word(bytes, 46), content="1")
}

///|
test "pbr material: generic standard material bind group carries Bevy binding payload" {
  let material = @material.StandardMaterial::StandardMaterial()
    .with_base_color_texture(Some(@asset.Handle::new(11)))
    .with_emissive_texture(Some(@asset.Handle::new(12)))
    .with_metallic_roughness_texture(Some(@asset.Handle::new(13)))
    .with_occlusion_texture(Some(@asset.Handle::new(14)))
    .with_depth_map(Some(@asset.Handle::new(15)))
    .with_anisotropy_texture(Some(@asset.Handle::new(16)))
    .with_clearcoat_texture(Some(@asset.Handle::new(17)))
    .with_clearcoat_roughness_texture(Some(@asset.Handle::new(18)))
    .with_clearcoat_normal_texture(Some(@asset.Handle::new(19)))
    .with_specular_transmission_texture(Some(@asset.Handle::new(20)))
    .with_thickness_texture(Some(@asset.Handle::new(21)))
    .with_diffuse_transmission_texture(Some(@asset.Handle::new(22)))
    .with_specular_texture(Some(@asset.Handle::new(23)))
    .with_specular_tint_texture(Some(@asset.Handle::new(24)))
  let prepared = PreparedMaterial::from_material(
    @asset.Handle::new(31),
    material,
    pbr_material_test_standard_material_pipeline(),
    @material.OpaqueRendererMethod::Forward,
    context=pbr_material_test_all_standard_material_texture_features_context(),
  )
  let entries = prepared.bind_group_data().entries()
  inspect(entries.length(), content="31")
  match entries[0].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Uniform(bytes) =>
      inspect(bytes.length(), content="192")
    _ => inspect(false, content="true")
  }
  match entries[1].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Texture(id) =>
      inspect(id, content="11")
    _ => inspect(false, content="true")
  }
  match entries[2].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Sampler(id) =>
      inspect(id, content="11")
    _ => inspect(false, content="true")
  }
  match entries[9].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Texture(id) =>
      inspect(id, content="-1")
    _ => inspect(false, content="true")
  }
  match entries[13].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Texture(id) =>
      inspect(id, content="16")
    _ => inspect(false, content="true")
  }
  match entries[14].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Sampler(id) =>
      inspect(id, content="16")
    _ => inspect(false, content="true")
  }
  match entries[15].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Texture(id) =>
      inspect(id, content="20")
    _ => inspect(false, content="true")
  }
  match entries[17].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Texture(id) =>
      inspect(id, content="21")
    _ => inspect(false, content="true")
  }
  match entries[19].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Texture(id) =>
      inspect(id, content="22")
    _ => inspect(false, content="true")
  }
  match entries[21].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Texture(id) =>
      inspect(id, content="17")
    _ => inspect(false, content="true")
  }
  match entries[25].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Texture(id) =>
      inspect(id, content="19")
    _ => inspect(false, content="true")
  }
  match entries[27].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Texture(id) =>
      inspect(id, content="23")
    _ => inspect(false, content="true")
  }
  match entries[29].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Texture(id) =>
      inspect(id, content="24")
    _ => inspect(false, content="true")
  }
  match entries[30].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Sampler(id) =>
      inspect(id, content="24")
    _ => inspect(false, content="true")
  }
}

///|
test "pbr material: default standard material bind group carries enabled feature payload only" {
  let material = @material.StandardMaterial::StandardMaterial()
    .with_anisotropy_texture(Some(@asset.Handle::new(16)))
    .with_clearcoat_texture(Some(@asset.Handle::new(17)))
    .with_specular_transmission_texture(Some(@asset.Handle::new(20)))
    .with_specular_texture(Some(@asset.Handle::new(23)))
  let prepared = PreparedMaterial::from_material(
    @asset.Handle::new(32),
    material,
    pbr_material_test_standard_material_pipeline(),
    @material.OpaqueRendererMethod::Forward,
  )
  let entries = prepared.bind_group_data().entries()
  inspect(entries.length(), content="15")
  match entries[13].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Texture(id) =>
      inspect(id, content="16")
    _ => inspect(false, content="true")
  }
  match entries[14].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Sampler(id) =>
      inspect(id, content="16")
    _ => inspect(false, content="true")
  }
}

///|
test "pbr material: generic standard material uniform flags carry enabled feature textures" {
  let material = @material.StandardMaterial::StandardMaterial()
    .with_clearcoat_texture(Some(@asset.Handle::new(1)))
    .with_clearcoat_roughness_texture(Some(@asset.Handle::new(2)))
    .with_clearcoat_normal_texture(Some(@asset.Handle::new(3)))
    .with_anisotropy_texture(Some(@asset.Handle::new(4)))
    .with_specular_tint_texture(Some(@asset.Handle::new(5)))
    .with_specular_transmission_texture(Some(@asset.Handle::new(6)))
    .with_thickness_texture(Some(@asset.Handle::new(7)))
    .with_diffuse_transmission_texture(Some(@asset.Handle::new(8)))
    .with_specular_texture(Some(@asset.Handle::new(9)))
  let default_flags = pbr_material_test_prepared_standard_material_flags(
    material,
  )
  inspect(
    (default_flags & @pbr_render.STANDARD_MATERIAL_FLAGS_CLEARCOAT_TEXTURE_BIT) !=
    0U,
    content="false",
  )
  inspect(
    (
      default_flags &
      @pbr_render.STANDARD_MATERIAL_FLAGS_SPECULAR_TRANSMISSION_TEXTURE_BIT
    ) !=
    0U,
    content="false",
  )
  inspect(
    (default_flags & @pbr_render.STANDARD_MATERIAL_FLAGS_SPECULAR_TEXTURE_BIT) !=
    0U,
    content="false",
  )
  inspect(
    (default_flags & @pbr_render.STANDARD_MATERIAL_FLAGS_ANISOTROPY_TEXTURE_BIT) !=
    0U,
    content="true",
  )
  let flags = pbr_material_test_prepared_standard_material_flags(
    material,
    context=pbr_material_test_all_standard_material_texture_features_context(),
  )
  inspect(
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_CLEARCOAT_TEXTURE_BIT) != 0U,
    content="true",
  )
  inspect(
    (
      flags &
      @pbr_render.STANDARD_MATERIAL_FLAGS_CLEARCOAT_ROUGHNESS_TEXTURE_BIT
    ) !=
    0U,
    content="true",
  )
  inspect(
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_CLEARCOAT_NORMAL_TEXTURE_BIT) !=
    0U,
    content="true",
  )
  inspect(
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_ANISOTROPY_TEXTURE_BIT) != 0U,
    content="true",
  )
  inspect(
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_SPECULAR_TINT_TEXTURE_BIT) !=
    0U,
    content="true",
  )
  inspect(
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_SPECULAR_TEXTURE_BIT) != 0U,
    content="true",
  )
  inspect(
    (
      flags &
      @pbr_render.STANDARD_MATERIAL_FLAGS_SPECULAR_TRANSMISSION_TEXTURE_BIT
    ) !=
    0U,
    content="true",
  )
  inspect(
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_THICKNESS_TEXTURE_BIT) != 0U,
    content="true",
  )
  inspect(
    (
      flags &
      @pbr_render.STANDARD_MATERIAL_FLAGS_DIFFUSE_TRANSMISSION_TEXTURE_BIT
    ) !=
    0U,
    content="true",
  )
}

///|
fn pbr_material_test_prepared_standard_material_flags(
  material : @material.StandardMaterial,
  context? : MaterialBindGroupContext = MaterialBindGroupContext::MaterialBindGroupContext(),
) -> UInt {
  let prepared = PreparedMaterial::from_material(
    @asset.Handle::new(37),
    material,
    pbr_material_test_standard_material_pipeline(),
    @material.OpaqueRendererMethod::Forward,
    context~,
  )
  let entries = prepared.bind_group_data().entries()
  match entries[0].resource() {
    @render_resource.MaterialBindGroupResolvedResource::Uniform(bytes) =>
      pbr_material_test_u32le_word(bytes, 40)
    _ => abort("expected standard material uniform binding")
  }
}

///|
fn pbr_material_test_all_standard_material_texture_features_context() -> MaterialBindGroupContext {
  MaterialBindGroupContext::MaterialBindGroupContext().with_standard_material_texture_features(
    StandardMaterialTextureFeatureSet::StandardMaterialTextureFeatureSet(
      pbr_transmission_textures=true,
      pbr_multi_layer_material_textures=true,
      pbr_anisotropy_texture=true,
      pbr_specular_textures=true,
    ),
  )
}

///|
fn pbr_material_test_image_context(
  handle : @asset.Handle[@asset.Image],
  format : @wgpu.TextureFormat,
) -> MaterialBindGroupContext {
  let images : @render.RenderAssets[@render_texture.GpuImage] = @render.RenderAssets::new()
  images.insert(
    handle.id(),
    @render_texture.GpuImage::from_texture_id_and_format(handle.id(), format),
  )
  MaterialBindGroupContext::from_images(images)
}

///|
test "pbr material: generic standard material normal map flag uses render image format" {
  let normal_map = @asset.Handle::new(41)
  let material = @material.StandardMaterial::StandardMaterial().with_normal_map_texture(
    Some(normal_map),
  )
  let flags_without_image = pbr_material_test_prepared_standard_material_flags(
    material,
  )
  inspect(
    (
      flags_without_image &
      @pbr_render.STANDARD_MATERIAL_FLAGS_TWO_COMPONENT_NORMAL_MAP
    ) !=
    0U,
    content="false",
  )
  for
    format in [
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RG8_UNORM),
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RG16_UNORM),
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_BC5_RG_UNORM),
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_EACRG11_UNORM),
    ] {
    let flags = pbr_material_test_prepared_standard_material_flags(
      material,
      context=pbr_material_test_image_context(normal_map, format),
    )
    inspect(
      (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_TWO_COMPONENT_NORMAL_MAP) !=
      0U,
      content="true",
    )
  }
  let rgba_flags = pbr_material_test_prepared_standard_material_flags(
    material,
    context=pbr_material_test_image_context(
      normal_map,
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    ),
  )
  inspect(
    (rgba_flags & @pbr_render.STANDARD_MATERIAL_FLAGS_TWO_COMPONENT_NORMAL_MAP) !=
    0U,
    content="false",
  )
}

///|
test "pbr material: standard material plugin installs render startup allocator" {
  let lifecycle_world_667_0 = @ecs.World::new()
  defer lifecycle_world_667_0.close()
  let app = @app.App::new(lifecycle_world_667_0)
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(MaterialsPlugin::MaterialsPlugin())
    .add_plugins(StandardMaterialPlugin::StandardMaterialPlugin())
  let render_sub_app = app
    .sub_app(@app.RenderApp)
    .set_update_schedule(Some(@render.render_startup_schedule_stage()))
  let render_world = render_sub_app.world()
  match render_world.get_resource(ecs_key_material_bind_group_allocators) {
    Some(allocators) =>
      debug_inspect(allocators.contains("StandardMaterial"), content="false")
    None => debug_inspect(false, content="true")
  }
  ignore(render_sub_app.run_startup())
  match render_world.get_resource(ecs_key_material_bind_group_allocators) {
    Some(allocators) => {
      debug_inspect(allocators.contains("StandardMaterial"), content="true")
      match allocators.get("StandardMaterial") {
        Some(MaterialBindGroupAllocator::NonBindless(_)) =>
          debug_inspect(true, content="true")
        _ => debug_inspect(false, content="true")
      }
    }
    None => debug_inspect(false, content="true")
  }
}

///|
fn pbr_material_test_shader_defs_contain(
  shader_defs : Array[@material.ShaderDefVal],
  name : String,
) -> Bool {
  for shader_def in shader_defs {
    match shader_def {
      @material.ShaderDefVal::Flag(flag) if flag == name => return true
      _ => ()
    }
  }
  false
}

///|
fn pbr_material_test_standard_material_pipeline() -> MaterialPipeline[
  @material.StandardMaterial,
] {
  MaterialPipeline::new(
    None,
    Some(PBR_MESH_FRAGMENT_SHADER_PATH),
    None,
    Some(PBR_MESH_PREPASS_FRAGMENT_SHADER_PATH),
    None,
    Some(PBR_MESH_FRAGMENT_SHADER_PATH),
    Some(PBR_MESH_FRAGMENT_SHADER_PATH),
    Some(PBR_MESH_PREPASS_FRAGMENT_SHADER_PATH),
    Some(PBR_MESH_FRAGMENT_SHADER_PATH),
  )
}

///|
fn pbr_material_test_mesh_layout() -> @mesh.MeshVertexBufferLayoutRef {
  let layouts = @mesh.MeshVertexBufferLayouts::MeshVertexBufferLayouts()
  layouts.insert(
    @mesh.MeshVertexBufferLayout::new(
      attribute_ids=[
        @mesh.MeshVertexAttribute::position().id(),
        @mesh.MeshVertexAttribute::normal().id(),
        @mesh.MeshVertexAttribute::uv_0().id(),
      ],
      layout=@mesh.VertexBufferLayout::new(
        array_stride=32,
        step_mode=@mesh.MeshVertexStepMode::Vertex,
        attributes=[
          @mesh.VertexAttribute::new(
            offset=0,
            format=@mesh.MeshVertexFormat::Float32x3,
            shader_location=0,
          ),
          @mesh.VertexAttribute::new(
            offset=12,
            format=@mesh.MeshVertexFormat::Float32x3,
            shader_location=1,
          ),
          @mesh.VertexAttribute::new(
            offset=24,
            format=@mesh.MeshVertexFormat::Float32x2,
            shader_location=2,
          ),
        ],
      ),
    ),
  )
}

///|
test "pbr material: generic standard material preparation uses typed material key" {
  let material = @material.StandardMaterial::StandardMaterial()
    .with_normal_map_texture(Some(@asset.Handle::new(1)))
    .with_diffuse_transmission(0.5F)
    .with_depth_bias(7.0F)
  let expected_key = standard_material_key_from_material(material)
  let prepared = PreparedMaterial::from_material(
    @asset.Handle::new(11),
    material,
    pbr_material_test_standard_material_pipeline(),
    @material.OpaqueRendererMethod::Deferred,
  )
  inspect(prepared.key.material_key().type_tag(), content="StandardMaterialKey")
  inspect(
    prepared.key.material_key().bits() == expected_key.bits(),
    content="true",
  )
  inspect(
    prepared.properties().material_key.type_tag(),
    content="StandardMaterialKey",
  )
  inspect(
    prepared.properties().material_key.bits() == expected_key.bits(),
    content="true",
  )
  debug_inspect(
    prepared.properties().render_method
    is @material.OpaqueRendererMethod::Forward,
    content="true",
  )
  debug_inspect(
    prepared.properties().get_shader(@material.MATERIAL_FRAGMENT_SHADER_LABEL),
    content="Some(\"pbr/render/pbr.wgsl\")",
  )
  debug_inspect(
    prepared.properties().get_shader(@material.PREPASS_FRAGMENT_SHADER_LABEL),
    content="Some(\"pbr/render/pbr_prepass.wgsl\")",
  )
  debug_inspect(
    prepared.properties().get_shader(@material.DEFERRED_FRAGMENT_SHADER_LABEL),
    content="Some(\"pbr/render/pbr.wgsl\")",
  )
}

///|
test "pbr material: generic standard material user specialize consumes erased typed key" {
  let material = @material.StandardMaterial::StandardMaterial()
    .with_normal_map_texture(Some(@asset.Handle::new(1)))
    .with_depth_bias(3.0F)
  let prepared = PreparedMaterial::from_material(
    @asset.Handle::new(12),
    material,
    pbr_material_test_standard_material_pipeline(),
    @material.OpaqueRendererMethod::Forward,
  )
  guard prepared.properties().user_specialize is Some(user_specialize) else {
    abort("expected generic StandardMaterial user_specialize hook")
  }
  let descriptor = @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor()
    .with_label(Some("standard_material_test_pipeline"))
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
        Some(PBR_MESH_VERTEX_SHADER_PATH),
        [],
        None,
        [],
      ),
    )
    .with_fragment(
      Some(
        @render_resource.FragmentState::new(
          Some(PBR_MESH_FRAGMENT_SHADER_PATH),
          [],
          None,
          [],
        ),
      ),
    )
  let erased_key = @material.ErasedMaterialPipelineKey::new(
    prepared.key.mesh_key(),
    prepared.key.material_key(),
    "StandardMaterial",
  )
  let specialized = try! @material.material_specialize_user(
    user_specialize,
    "PbrMaterialPipeline",
    descriptor,
    pbr_material_test_mesh_layout(),
    erased_key,
  )
  guard specialized.fragment is Some(fragment) else {
    abort("expected specialized StandardMaterial fragment state")
  }
  debug_inspect(
    pbr_material_test_shader_defs_contain(
      fragment.shader_defs,
      "STANDARD_MATERIAL_NORMAL_MAP",
    ),
    content="true",
  )
  guard specialized.depth_stencil is Some(depth_stencil) else {
    abort("expected specialized StandardMaterial depth state")
  }
  inspect(depth_stencil.bias_constant, content="3")
}
