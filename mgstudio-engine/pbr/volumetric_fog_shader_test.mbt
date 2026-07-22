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
fn render3d_volumetric_fog_test_value_defines() -> @hashmap.HashMap[
  String,
  @wgsl_common.ShaderDefValue,
] {
  let value_defines = @shader_compile.default_shader_value_defines()
  value_defines.remove("PER_OBJECT_BUFFER_BATCH_SIZE")
  value_defines.set("MAX_DIRECTIONAL_LIGHTS", UInt(10U))
  value_defines.set("MAX_CASCADES_PER_LIGHT", UInt(4U))
  value_defines.set("MAX_RECT_LIGHTS", UInt(8U))
  value_defines
}

///|
fn render3d_volumetric_fog_test_shader_defs() -> @hashmap.HashMap[String, Bool] {
  let defines : @hashmap.HashMap[String, Bool] = HashMap([])
  defines.set("SHADOW_FILTER_METHOD_HARDWARE_2X2", true)
  defines.set("DENSITY_TEXTURE", true)
  defines
}

///|
fn register_volumetric_fog_shader_test_sources() -> Unit {
  @shader_compile.clear_registered_shader_sources()
  @render.register_embedded_wgsl_sources()
  @fullscreen_vertex_shader_source.register_embedded_wgsl_sources()
  @pbr_atmosphere.register_embedded_wgsl_sources()
  @pbr_prepass.register_embedded_wgsl_sources()
  @pbr_render.register_embedded_wgsl_sources()
  @pbr_volumetric_fog.register_embedded_wgsl_sources()
}

///|
test "pbr volumetric fog: registered wgsl import paths mirror Bevy closure anchors" {
  register_volumetric_fog_shader_test_sources()
  let import_paths = @shader_compile.copy_registered_shader_import_module_paths()
  debug_inspect(
    import_paths.get("bevy_core_pipeline::fullscreen_vertex_shader"),
    content="Some(\"core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::atmosphere::functions"),
    content="Some(\"pbr/atmosphere/functions.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::atmosphere::bruneton_functions"),
    content="Some(\"pbr/atmosphere/bruneton_functions.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::mesh_functions"),
    content="Some(\"pbr/render/mesh_functions.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::mesh_view_bindings"),
    content="Some(\"pbr/render/mesh_view_bindings.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::mesh_view_types"),
    content="Some(\"pbr/render/mesh_view_types.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::shadow_sampling"),
    content="Some(\"pbr/render/shadow_sampling.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::shadows"),
    content="Some(\"pbr/render/shadows.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::utils"),
    content="Some(\"pbr/render/utils.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::view_transformations"),
    content="Some(\"pbr/render/view_transformations.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::clustered_forward"),
    content="Some(\"pbr/render/clustered_forward.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::lighting"),
    content="Some(\"pbr/render/pbr_lighting.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_render::maths"),
    content="Some(\"render/maths.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_render::color_operations"),
    content="Some(\"render/color_operations.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_render::globals"),
    content="Some(\"render/globals.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_render::view"),
    content="Some(\"render/view/view.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::atmosphere::types"),
    content="Some(\"pbr/atmosphere/types.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::mesh_bindings"),
    content="Some(\"pbr/render/mesh_bindings.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::mesh_types"),
    content="Some(\"pbr/render/mesh_types.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::prepass_bindings"),
    content="Some(\"pbr/prepass/prepass_bindings.wgsl\")",
  )
  debug_inspect(
    import_paths.get("bevy_pbr::rgb9e5"),
    content="Some(\"pbr/render/rgb9e5.wgsl\")",
  )
}

///|
test "pbr volumetric fog: composed runtime wgsl keeps Bevy directional shadow import closure" {
  register_volumetric_fog_shader_test_sources()

  let composed = @shader_compile.load_preprocessed_wgsl(
    "",
    @pbr_volumetric_fog.VOLUMETRIC_FOG_SHADER_PATH,
    render3d_volumetric_fog_test_shader_defs(),
    render3d_volumetric_fog_test_value_defines(),
  ) catch {
    err => abort(err.message())
  }

  debug_inspect(
    @pbr_volumetric_fog.VOLUMETRIC_FOG_SHADER_PATH,
    content="\"pbr/volumetric_fog/volumetric_fog.wgsl\"",
  )
  debug_inspect(composed.contains("#import"), content="false")
  debug_inspect(composed.contains("bevy_pbr::"), content="false")
  debug_inspect(composed.contains("bevy_render::"), content="false")
  debug_inspect(composed.contains("fn fragment("), content="true")
  debug_inspect(composed.contains("struct VolumetricFog"), content="true")
  debug_inspect(
    composed.contains("struct FullscreenVertexOutput"),
    content="false",
  )
  debug_inspect(
    composed.contains("fn calculate_visible_sun_ratio"),
    content="false",
  )
  debug_inspect(composed.contains("fn clamp_to_surface"), content="false")
  debug_inspect(
    composed.contains("fn transmittance_lut_r_mu_to_uv"),
    content="false",
  )
  debug_inspect(composed.contains("fn get_world_from_local"), content="false")
  debug_inspect(
    composed.contains("fn mesh_position_local_to_clip"),
    content="false",
  )
  debug_inspect(composed.contains("var<uniform> globals"), content="true")
  debug_inspect(composed.contains("var<uniform> lights"), content="true")
  debug_inspect(composed.contains("var<uniform> view"), content="true")
  debug_inspect(
    composed.contains("DIRECTIONAL_LIGHT_FLAGS_VOLUMETRIC_BIT"),
    content="true",
  )
  debug_inspect(
    composed.contains("POINT_LIGHT_FLAGS_SHADOWS_ENABLED_BIT"),
    content="true",
  )
  debug_inspect(composed.contains("SPOT_SHADOW_TEXEL_SIZE"), content="true")
  debug_inspect(composed.contains("directional_light_count"), content="true")
  debug_inspect(composed.contains("directional_lights"), content="true")
  debug_inspect(composed.contains("light_index"), content="true")
  debug_inspect(
    composed.contains("fn sample_shadow_map_hardware"),
    content="true",
  )
  debug_inspect(composed.contains("fn get_cascade_index"), content="true")
  debug_inspect(
    composed.contains("fn world_to_directional_light_local"),
    content="true",
  )
  debug_inspect(composed.contains("num_cascades"), content="true")
  debug_inspect(composed.contains("far_bound"), content="true")
  debug_inspect(composed.contains("clip_from_world"), content="true")
  debug_inspect(composed.contains("struct Lights"), content="true")
  debug_inspect(composed.contains("struct DirectionalLight"), content="true")
  debug_inspect(composed.contains("fn getDistanceAttenuation"), content="true")
  debug_inspect(
    composed.contains("fn interleaved_gradient_noise"),
    content="true",
  )
  debug_inspect(composed.contains("fn depth_ndc_to_view_z"), content="true")
  debug_inspect(composed.contains("fn frag_coord_to_ndc"), content="true")
  debug_inspect(composed.contains("fn position_ndc_to_view"), content="true")
  debug_inspect(composed.contains("fn position_ndc_to_world"), content="true")
  debug_inspect(composed.contains("fn position_view_to_world"), content="true")
  debug_inspect(composed.contains("fn fragment_cluster_index"), content="true")
  debug_inspect(composed.contains("textureSampleCompareLevel"), content="true")
  debug_inspect(composed.contains("depth_texture_base_index"), content="true")
  debug_inspect(composed.contains("array_index"), content="true")
  debug_inspect(composed.contains("cascade_index"), content="true")
}
