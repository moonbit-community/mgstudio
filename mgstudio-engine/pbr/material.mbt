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
pub const MAIN_PASS_OPAQUE_DRAW_FUNCTION_LABEL : @material.DrawFunctionLabel = "MainPassOpaqueDrawFunction"

///|
pub const MAIN_PASS_ALPHA_MASK_DRAW_FUNCTION_LABEL : @material.DrawFunctionLabel = "MainPassAlphaMaskDrawFunction"

///|
pub const MAIN_PASS_TRANSMISSIVE_DRAW_FUNCTION_LABEL : @material.DrawFunctionLabel = "MainPassTransmissiveDrawFunction"

///|
pub const MAIN_PASS_TRANSPARENT_DRAW_FUNCTION_LABEL : @material.DrawFunctionLabel = "MainPassTransparentDrawFunction"

///|
pub const PREPASS_OPAQUE_DRAW_FUNCTION_LABEL : @material.DrawFunctionLabel = "PrepassOpaqueDrawFunction"

///|
pub const PREPASS_ALPHA_MASK_DRAW_FUNCTION_LABEL : @material.DrawFunctionLabel = "PrepassAlphaMaskDrawFunction"

///|
pub const PREPASS_OPAQUE_DEPTH_ONLY_DRAW_FUNCTION_LABEL : @material.DrawFunctionLabel = "PrepassOpaqueDepthOnlyDrawFunction"

///|
pub const DEFERRED_OPAQUE_DRAW_FUNCTION_LABEL : @material.DrawFunctionLabel = "DeferredOpaqueDrawFunction"

///|
pub const DEFERRED_ALPHA_MASK_DRAW_FUNCTION_LABEL : @material.DrawFunctionLabel = "DeferredAlphaMaskDrawFunction"

///|
pub const SHADOWS_DRAW_FUNCTION_LABEL : @material.DrawFunctionLabel = "ShadowsDrawFunction"

///|
pub const SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL : @material.DrawFunctionLabel = "ShadowsDepthOnlyDrawFunction"

///|
pub struct MaterialsPlugin {}

///|
pub fn MaterialsPlugin::MaterialsPlugin() -> MaterialsPlugin {
  MaterialsPlugin::{  }
}

///|
pub struct MaterialsPluginState {}

///|
pub fn MaterialsPluginState::MaterialsPluginState() -> MaterialsPluginState {
  MaterialsPluginState::{  }
}

///|
pub fn MaterialsPluginState::new() -> MaterialsPluginState {
  MaterialsPluginState::MaterialsPluginState()
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
  if world.get_resource(ecs_key_entity_specialization_ticks) is None {
    world.insert_resource(
      ecs_key_entity_specialization_ticks,
      EntitySpecializationTicks::EntitySpecializationTicks(),
    )
  }
  if world.get_resource(ecs_key_specialized_material_pipeline_cache) is None {
    world.insert_resource(
      ecs_key_specialized_material_pipeline_cache,
      SpecializedMaterialPipelineCache::SpecializedMaterialPipelineCache(),
    )
  }
  if world.get_resource(ecs_key_render_material_instances) is None {
    world.insert_resource(
      ecs_key_render_material_instances,
      RenderMaterialInstances::RenderMaterialInstances(),
    )
  }
  if world.get_resource(ecs_key_material_bind_group_allocators) is None {
    world.insert_resource(
      ecs_key_material_bind_group_allocators,
      MaterialBindGroupAllocators::MaterialBindGroupAllocators(),
    )
  }
}

///|
pub impl @app.Plugin for MaterialsPlugin with fn name(_self) {
  MATERIALS_PLUGIN_NAME
}

///|
pub impl @app.Plugin for MaterialsPlugin with fn build(_self, app) {
  materials_plugin_install(app)
}

///|
pub fn materials_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_plugins(MaterialsPlugin::MaterialsPlugin())
}

///|
fn configure_materials_render_sub_app(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  init_materials_resources(sub_app.world())
  sub_app
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
  let app = @render.try_with_render_app(app, configure_materials_render_sub_app)
  @pbr_prepass.prepass_plugin(app)
}

///|
pub fn pbr_material_bind_group_index() -> Int {
  MATERIAL_BIND_GROUP_INDEX
}

///|
pub fn pbr_materials_plugin_state_default() -> MaterialsPluginState {
  MaterialsPluginState::MaterialsPluginState()
}

///|
pub fn pbr_materials_plugin_state_new() -> MaterialsPluginState {
  MaterialsPluginState::new()
}

///|
pub fn pbr_materials_plugin_default() -> MaterialsPlugin {
  MaterialsPlugin::MaterialsPlugin()
}

///|
pub struct PbrMaterialDrawFunctionIds {
  main_pass_opaque : @material.DrawFunctionId
  main_pass_alpha_mask : @material.DrawFunctionId
  main_pass_transmissive : @material.DrawFunctionId
  main_pass_transparent : @material.DrawFunctionId
  prepass_opaque : @material.DrawFunctionId
  prepass_alpha_mask : @material.DrawFunctionId
  prepass_opaque_depth_only : @material.DrawFunctionId
  deferred_opaque : @material.DrawFunctionId
  deferred_alpha_mask : @material.DrawFunctionId
  shadows : @material.DrawFunctionId
  shadows_depth_only : @material.DrawFunctionId
}

///|
pub fn pbr_material_draw_function_labels() -> Array[@material.DrawFunctionLabel] {
  [
    MAIN_PASS_OPAQUE_DRAW_FUNCTION_LABEL,
    MAIN_PASS_ALPHA_MASK_DRAW_FUNCTION_LABEL,
    MAIN_PASS_TRANSMISSIVE_DRAW_FUNCTION_LABEL,
    MAIN_PASS_TRANSPARENT_DRAW_FUNCTION_LABEL,
    PREPASS_OPAQUE_DRAW_FUNCTION_LABEL,
    PREPASS_ALPHA_MASK_DRAW_FUNCTION_LABEL,
    PREPASS_OPAQUE_DEPTH_ONLY_DRAW_FUNCTION_LABEL,
    DEFERRED_OPAQUE_DRAW_FUNCTION_LABEL,
    DEFERRED_ALPHA_MASK_DRAW_FUNCTION_LABEL,
    SHADOWS_DRAW_FUNCTION_LABEL,
    SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL,
  ]
}

///|
pub fn pbr_material_register_draw_functions(
  draw_functions : @material.DrawFunctions,
) -> PbrMaterialDrawFunctionIds {
  PbrMaterialDrawFunctionIds::{
    main_pass_opaque: draw_functions.register(
      MAIN_PASS_OPAQUE_DRAW_FUNCTION_LABEL,
    ),
    main_pass_alpha_mask: draw_functions.register(
      MAIN_PASS_ALPHA_MASK_DRAW_FUNCTION_LABEL,
    ),
    main_pass_transmissive: draw_functions.register(
      MAIN_PASS_TRANSMISSIVE_DRAW_FUNCTION_LABEL,
    ),
    main_pass_transparent: draw_functions.register(
      MAIN_PASS_TRANSPARENT_DRAW_FUNCTION_LABEL,
    ),
    prepass_opaque: draw_functions.register(PREPASS_OPAQUE_DRAW_FUNCTION_LABEL),
    prepass_alpha_mask: draw_functions.register(
      PREPASS_ALPHA_MASK_DRAW_FUNCTION_LABEL,
    ),
    prepass_opaque_depth_only: draw_functions.register(
      PREPASS_OPAQUE_DEPTH_ONLY_DRAW_FUNCTION_LABEL,
    ),
    deferred_opaque: draw_functions.register(
      DEFERRED_OPAQUE_DRAW_FUNCTION_LABEL,
    ),
    deferred_alpha_mask: draw_functions.register(
      DEFERRED_ALPHA_MASK_DRAW_FUNCTION_LABEL,
    ),
    shadows: draw_functions.register(SHADOWS_DRAW_FUNCTION_LABEL),
    shadows_depth_only: draw_functions.register(
      SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL,
    ),
  }
}

///|
pub fn pbr_material_apply_draw_functions(
  properties : @material.MaterialProperties,
  ids : PbrMaterialDrawFunctionIds,
) -> @material.MaterialProperties {
  properties
  .add_draw_function(MAIN_PASS_OPAQUE_DRAW_FUNCTION_LABEL, ids.main_pass_opaque)
  .add_draw_function(
    MAIN_PASS_ALPHA_MASK_DRAW_FUNCTION_LABEL,
    ids.main_pass_alpha_mask,
  )
  .add_draw_function(
    MAIN_PASS_TRANSMISSIVE_DRAW_FUNCTION_LABEL,
    ids.main_pass_transmissive,
  )
  .add_draw_function(
    MAIN_PASS_TRANSPARENT_DRAW_FUNCTION_LABEL,
    ids.main_pass_transparent,
  )
  .add_draw_function(PREPASS_OPAQUE_DRAW_FUNCTION_LABEL, ids.prepass_opaque)
  .add_draw_function(
    PREPASS_ALPHA_MASK_DRAW_FUNCTION_LABEL,
    ids.prepass_alpha_mask,
  )
  .add_draw_function(
    PREPASS_OPAQUE_DEPTH_ONLY_DRAW_FUNCTION_LABEL,
    ids.prepass_opaque_depth_only,
  )
  .add_draw_function(DEFERRED_OPAQUE_DRAW_FUNCTION_LABEL, ids.deferred_opaque)
  .add_draw_function(
    DEFERRED_ALPHA_MASK_DRAW_FUNCTION_LABEL,
    ids.deferred_alpha_mask,
  )
  .add_draw_function(SHADOWS_DRAW_FUNCTION_LABEL, ids.shadows)
  .add_draw_function(
    SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL,
    ids.shadows_depth_only,
  )
}

///|
pub const MESH_PIPELINE_KEY_READS_VIEW_TRANSMISSION_TEXTURE : UInt64 = 2048UL

///|
pub const MESH_PIPELINE_KEY_LIGHTMAPPED : UInt64 = 4096UL

///|
pub const MESH_PIPELINE_KEY_LIGHTMAP_BICUBIC_SAMPLING : UInt64 = 8192UL

///|
const MESH_PIPELINE_KEY_MAY_DISCARD : UInt64 = 64UL

///|
const MESH_PIPELINE_KEY_BLEND_PREMULTIPLIED_ALPHA : UInt64 = 268435456UL

///|
const MESH_PIPELINE_KEY_BLEND_MULTIPLY : UInt64 = 536870912UL

///|
const MESH_PIPELINE_KEY_BLEND_ALPHA : UInt64 = 805306368UL

///|
const MESH_PIPELINE_KEY_BLEND_ALPHA_TO_COVERAGE : UInt64 = 1073741824UL

///|
fn alpha_mode_pipeline_key(
  alpha_mode : @material.AlphaMode3d,
  msaa_samples? : Int = 1,
) -> UInt64 {
  match alpha_mode {
    @material.AlphaMode3d::Premultiplied =>
      MESH_PIPELINE_KEY_BLEND_PREMULTIPLIED_ALPHA
    @material.AlphaMode3d::Add => MESH_PIPELINE_KEY_BLEND_PREMULTIPLIED_ALPHA
    @material.AlphaMode3d::Blend => MESH_PIPELINE_KEY_BLEND_ALPHA
    @material.AlphaMode3d::Multiply => MESH_PIPELINE_KEY_BLEND_MULTIPLY
    @material.AlphaMode3d::Mask(_) => MESH_PIPELINE_KEY_MAY_DISCARD
    @material.AlphaMode3d::AlphaToCoverage =>
      if msaa_samples <= 1 {
        MESH_PIPELINE_KEY_MAY_DISCARD
      } else {
        MESH_PIPELINE_KEY_BLEND_ALPHA_TO_COVERAGE
      }
    _ => 0UL
  }
}

///|
fn mesh_pipeline_key_msaa_bits(msaa_samples : Int) -> UInt64 {
  let log2_samples = if msaa_samples <= 1 {
    0UL
  } else if msaa_samples <= 2 {
    1UL
  } else if msaa_samples <= 4 {
    2UL
  } else if msaa_samples <= 8 {
    3UL
  } else if msaa_samples <= 16 {
    4UL
  } else if msaa_samples <= 32 {
    5UL
  } else if msaa_samples <= 64 {
    6UL
  } else {
    7UL
  }
  (log2_samples & MESH_PIPELINE_KEY_MSAA_MASK_BITS) <<
  MESH_PIPELINE_KEY_MSAA_SHIFT_BITS
}

///|
fn mesh_pipeline_key_tonemapping_bits(tonemapping : Tonemapping) -> UInt64 {
  match tonemapping {
    None => 0UL << MESH_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS
    Reinhard => 1UL << MESH_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS
    ReinhardLuminance => 2UL << MESH_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS
    AcesFitted => 3UL << MESH_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS
    AgX => 4UL << MESH_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS
    SomewhatBoringDisplayTransform =>
      5UL << MESH_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS
    TonyMcMapface => 6UL << MESH_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS
    BlenderFilmic => 7UL << MESH_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS
    PbrNeutral => 8UL << MESH_PIPELINE_KEY_TONEMAP_METHOD_SHIFT_BITS
  }
}

///|
fn mesh_pipeline_key_shadow_filter_method_bits(
  filter_method : ShadowFilteringMethod,
) -> UInt64 {
  match filter_method {
    Hardware2x2 => 0UL << MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_SHIFT_BITS
    Gaussian => 1UL << MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_SHIFT_BITS
    Temporal => 2UL << MESH_PIPELINE_KEY_SHADOW_FILTER_METHOD_SHIFT_BITS
  }
}

///|
fn mesh_pipeline_key_projection_bits(projection : Projection) -> UInt64 {
  match projection {
    Custom(_) => 0UL << MESH_PIPELINE_KEY_VIEW_PROJECTION_SHIFT_BITS
    Perspective(_) => 1UL << MESH_PIPELINE_KEY_VIEW_PROJECTION_SHIFT_BITS
    Orthographic(_) => 2UL << MESH_PIPELINE_KEY_VIEW_PROJECTION_SHIFT_BITS
  }
}

///|
fn material_mesh_pipeline_key_for_render_mesh(
  properties : @material.MaterialProperties,
  render_mesh : @render_mesh.RenderMesh,
  view_key_bits? : UInt64 = 0UL,
  msaa_samples? : Int = 1,
  has_previous_skin? : Bool = false,
  has_previous_morph? : Bool = false,
  visibility_range_dither? : Bool = false,
  lightmapped? : Bool = false,
  lightmap_bicubic_sampling? : Bool = false,
) -> @material.ErasedMeshPipelineKey {
  let mut bits = view_key_bits |
    properties.mesh_pipeline_key_bits.bits() |
    render_mesh.key_bits().bits() |
    alpha_mode_pipeline_key(properties.alpha_mode, msaa_samples~)
  if lightmapped {
    bits = bits | MESH_PIPELINE_KEY_LIGHTMAPPED
  }
  if lightmap_bicubic_sampling {
    bits = bits | MESH_PIPELINE_KEY_LIGHTMAP_BICUBIC_SAMPLING
  }
  if has_previous_skin {
    bits = bits | MESH_PIPELINE_KEY_HAS_PREVIOUS_SKIN
  }
  if has_previous_morph {
    bits = bits | MESH_PIPELINE_KEY_HAS_PREVIOUS_MORPH
  }
  if visibility_range_dither {
    bits = bits | MESH_PIPELINE_KEY_VISIBILITY_RANGE_DITHER
  }
  @material.ErasedMeshPipelineKey::new(bits, "MeshPipelineKey")
}

///|
fn material_pipeline_key_for_standard_material_render_mesh(
  properties : @material.MaterialProperties,
  render_mesh : @render_mesh.RenderMesh,
  view_key_bits? : UInt64 = 0UL,
  msaa_samples? : Int = 1,
  has_previous_skin? : Bool = false,
  has_previous_morph? : Bool = false,
  visibility_range_dither? : Bool = false,
  lightmapped? : Bool = false,
  lightmap_bicubic_sampling? : Bool = false,
) -> @material.ErasedMaterialPipelineKey {
  @material.ErasedMaterialPipelineKey::new(
    material_mesh_pipeline_key_for_render_mesh(
      properties,
      render_mesh,
      view_key_bits~,
      msaa_samples~,
      has_previous_skin~,
      has_previous_morph~,
      visibility_range_dither~,
      lightmapped~,
      lightmap_bicubic_sampling~,
    ),
    properties.material_key,
    "StandardMaterial",
  )
}

///|
pub fn render3d_material_properties_for_standard_material(
  material : StandardMaterial,
  extension : ExtendedMaterialMetadata3d?,
  default_opaque_renderer_method : OpaqueRendererMethod,
  prepass_enabled : Bool,
) -> @material.MaterialProperties {
  let mut effective_material = material
  if extension is Some(metadata) {
    if metadata.alpha_mode_override is Some(alpha_mode_override) {
      effective_material = effective_material.with_alpha_mode(
        alpha_mode_override,
      )
    }
    if metadata.opaque_render_method_override
      is Some(opaque_render_method_override) {
      effective_material = effective_material.with_opaque_render_method(
        opaque_render_method_override,
      )
    }
  }
  let render_method = standard_material_opaque_render_method(
    effective_material, default_opaque_renderer_method,
  )
  let reads_view_transmission_texture = standard_material_reads_view_transmission_texture(
    effective_material,
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
  let standard_material_key = standard_material_key_from_material(
    effective_material,
  )
  let mut properties = @material.MaterialProperties::MaterialProperties()
    .with_render_method(render_method)
    .with_alpha_mode(effective_material.alpha_mode)
    .with_mesh_pipeline_key_bits(
      @material.ErasedMeshPipelineKey::new(
        mesh_pipeline_key_bits, "MeshPipelineKey",
      ),
    )
    .with_depth_bias(effective_material.depth_bias)
    .with_reads_view_transmission_texture(reads_view_transmission_texture)
    .with_render_phase_type(
      standard_material_render_phase_type(effective_material),
    )
    .with_material_layout(
      Some(
        match extension {
          Some(metadata) if metadata.extension_tag == 1 =>
            forward_decal_material_bind_group_layout_descriptor()
          _ => standard_material_bind_group_layout_descriptor()
        },
      ),
    )
    .with_material_key(
      @material.ErasedMaterialKey::new(
        standard_material_key.bits(),
        "StandardMaterialKey",
      ),
    )
    .with_base_specialize(Some(pbr_material_base_specialize))
    .with_prepass_specialize(Some(pbr_material_prepass_specialize))
    .with_user_specialize(
      match extension {
        Some(metadata) => metadata.user_specialize
        None => None
      },
    )
    .with_shadows_enabled(shadows_enabled)
    .with_prepass_enabled(prepass_enabled)
    .add_shader(
      @material.PREPASS_FRAGMENT_SHADER_LABEL,
      PBR_MESH_PREPASS_FRAGMENT_SHADER_PATH,
    )
    .add_shader(
      @material.DEFERRED_FRAGMENT_SHADER_LABEL,
      PBR_MESH_FRAGMENT_SHADER_PATH,
    )
    .add_shader(
      @material.MESHLET_FRAGMENT_SHADER_LABEL,
      PBR_MESH_FRAGMENT_SHADER_PATH,
    )
    .add_shader(
      @material.MESHLET_PREPASS_FRAGMENT_SHADER_LABEL,
      PBR_MESH_PREPASS_FRAGMENT_SHADER_PATH,
    )
    .add_shader(
      @material.MESHLET_DEFERRED_FRAGMENT_SHADER_LABEL,
      PBR_MESH_FRAGMENT_SHADER_PATH,
    )
  if extension is Some(metadata) {
    if metadata.vertex_shader_path is Some(shader_path) {
      properties = properties.add_shader(
        @material.MATERIAL_VERTEX_SHADER_LABEL,
        shader_path,
      )
    }
    if metadata.fragment_shader_path is Some(shader_path) {
      properties = properties.add_shader(
        @material.MATERIAL_FRAGMENT_SHADER_LABEL,
        shader_path,
      )
    }
    if metadata.prepass_vertex_shader_path is Some(shader_path) {
      properties = properties.add_shader(
        @material.PREPASS_VERTEX_SHADER_LABEL,
        shader_path,
      )
    }
    if metadata.prepass_fragment_shader_path is Some(shader_path) {
      properties = properties.add_shader(
        @material.PREPASS_FRAGMENT_SHADER_LABEL,
        shader_path,
      )
    }
    if metadata.deferred_vertex_shader_path is Some(shader_path) {
      properties = properties.add_shader(
        @material.DEFERRED_VERTEX_SHADER_LABEL,
        shader_path,
      )
    }
    if metadata.deferred_fragment_shader_path is Some(shader_path) {
      properties = properties.add_shader(
        @material.DEFERRED_FRAGMENT_SHADER_LABEL,
        shader_path,
      )
    }
    if metadata.meshlet_fragment_shader_path is Some(shader_path) {
      properties = properties.add_shader(
        @material.MESHLET_FRAGMENT_SHADER_LABEL,
        shader_path,
      )
    }
    if metadata.meshlet_prepass_fragment_shader_path is Some(shader_path) {
      properties = properties.add_shader(
        @material.MESHLET_PREPASS_FRAGMENT_SHADER_LABEL,
        shader_path,
      )
    }
    if metadata.meshlet_deferred_fragment_shader_path is Some(shader_path) {
      properties = properties.add_shader(
        @material.MESHLET_DEFERRED_FRAGMENT_SHADER_LABEL,
        shader_path,
      )
    }
  }
  properties
}

///|
fn render3d_material_default_opaque_renderer_method(
  world : @ecs.World,
) -> OpaqueRendererMethod {
  match world.get_resource(ecs_key_default_opaque_renderer_method) {
    Some(default_method) => default_method.renderer_method()
    None => OpaqueRendererMethod::Forward
  }
}
