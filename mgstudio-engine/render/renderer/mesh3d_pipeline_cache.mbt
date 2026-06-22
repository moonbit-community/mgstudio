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
const MESH3D_PIPELINE_BLEND_OPAQUE : Int = 0

///|
const MESH3D_PIPELINE_BLEND_ALPHA : Int = 1

///|
const MESH3D_PIPELINE_BLEND_PREMULTIPLIED_ALPHA : Int = 2

///|
const MESH3D_PIPELINE_BLEND_MULTIPLY : Int = 3

///|
const MESH3D_DEFAULT_MATERIAL_PIPELINE_ID : UInt64 = 0xffffffffffffffffUL

///|
pub(all) enum RenderPipelineCacheState {
  RenderPipelineOk(@wgpu.RenderPipeline)
  RenderPipelineErr(String)
}

///|
struct Mesh3dPipelineCacheEntry {
  color_format : UInt
  msaa_sample_count : Int
  topology : UInt
  material_pipeline_id : UInt64
  cull_mode : Int
  blend_kind : Int
  skinned : Bool
  lightmapped : Bool
  forward_decal : Bool
  tonemap_in_shader : Bool
  tonemapping_mode : Int
  deband_dither_enabled : Bool
  shadow_filter_method : Int
  state : RenderPipelineCacheState
}

///|
fn mesh3d_pipeline_get(
  backend : GpuBackend,
  color_format : UInt,
  msaa_sample_count : Int,
  topology : UInt,
  material_pipeline_id : UInt64,
  cull_mode : Int,
  blend_kind : Int,
  skinned : Bool,
  forward_decal : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
  lightmapped? : Bool = false,
) -> @wgpu.RenderPipeline? {
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  for entry in backend.mesh3d_pipeline_cache {
    if entry.color_format == color_format &&
      entry.msaa_sample_count == msaa_sample_count &&
      entry.topology == topology &&
      entry.material_pipeline_id == material_pipeline_id &&
      entry.cull_mode == safe_cull_mode &&
      entry.blend_kind == blend_kind &&
      entry.skinned == skinned &&
      entry.lightmapped == lightmapped &&
      entry.forward_decal == forward_decal &&
      entry.tonemap_in_shader == tonemap_in_shader &&
      entry.tonemapping_mode == tonemapping_mode &&
      entry.deband_dither_enabled == deband_dither_enabled &&
      entry.shadow_filter_method == shadow_filter_method {
      match entry.state {
        RenderPipelineOk(pipeline) => {
          @app.timeline_trace_emit_counter_int(
            "render_3d_pipeline_cache_hits", 1,
          )
          return Some(pipeline)
        }
        RenderPipelineErr(message) => {
          ignore(message)
          @app.timeline_trace_emit_counter_int(
            "render_3d_pipeline_cache_failed_hits", 1,
          )
          return None
        }
      }
    }
  }
  @app.timeline_trace_emit_counter_int("render_3d_pipeline_cache_misses", 1)
  None
}

///|
fn mesh3d_pipeline_failed(
  backend : GpuBackend,
  color_format : UInt,
  msaa_sample_count : Int,
  topology : UInt,
  material_pipeline_id : UInt64,
  cull_mode : Int,
  blend_kind : Int,
  skinned : Bool,
  forward_decal : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
  lightmapped? : Bool = false,
) -> Bool {
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  for entry in backend.mesh3d_pipeline_cache {
    if entry.color_format == color_format &&
      entry.msaa_sample_count == msaa_sample_count &&
      entry.topology == topology &&
      entry.material_pipeline_id == material_pipeline_id &&
      entry.cull_mode == safe_cull_mode &&
      entry.blend_kind == blend_kind &&
      entry.skinned == skinned &&
      entry.lightmapped == lightmapped &&
      entry.forward_decal == forward_decal &&
      entry.tonemap_in_shader == tonemap_in_shader &&
      entry.tonemapping_mode == tonemapping_mode &&
      entry.deband_dither_enabled == deband_dither_enabled &&
      entry.shadow_filter_method == shadow_filter_method {
      match entry.state {
        RenderPipelineOk(_) => return false
        RenderPipelineErr(message) => {
          ignore(message)
          return true
        }
      }
    }
  }
  false
}

///|
fn mesh3d_pipeline_set(
  backend : GpuBackend,
  color_format : UInt,
  msaa_sample_count : Int,
  topology : UInt,
  material_pipeline_id : UInt64,
  cull_mode : Int,
  blend_kind : Int,
  skinned : Bool,
  forward_decal : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
  pipeline : @wgpu.RenderPipeline,
  lightmapped? : Bool = false,
) -> Unit {
  backend.mesh3d_pipeline_cache.push({
    color_format,
    msaa_sample_count,
    topology,
    material_pipeline_id,
    cull_mode: mesh3d_cull_mode_sanitize(cull_mode),
    blend_kind,
    skinned,
    lightmapped,
    forward_decal,
    tonemap_in_shader,
    tonemapping_mode,
    deband_dither_enabled,
    shadow_filter_method,
    state: RenderPipelineOk(pipeline),
  })
  @app.timeline_trace_emit_counter_int("render_3d_pipeline_cache_inserts", 1)
}

///|
fn mesh3d_pipeline_set_failed(
  backend : GpuBackend,
  color_format : UInt,
  msaa_sample_count : Int,
  topology : UInt,
  material_pipeline_id : UInt64,
  cull_mode : Int,
  blend_kind : Int,
  skinned : Bool,
  forward_decal : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
  message : String,
  lightmapped? : Bool = false,
) -> Unit {
  if mesh3d_pipeline_get(
      backend, color_format, msaa_sample_count, topology, material_pipeline_id, cull_mode,
      blend_kind, skinned, forward_decal, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
      shadow_filter_method, lightmapped~,
    )
    is Some(_) {
    return
  }
  if mesh3d_pipeline_failed(
      backend, color_format, msaa_sample_count, topology, material_pipeline_id, cull_mode,
      blend_kind, skinned, forward_decal, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
      shadow_filter_method, lightmapped~,
    ) {
    return
  }
  backend.mesh3d_pipeline_cache.push({
    color_format,
    msaa_sample_count,
    topology,
    material_pipeline_id,
    cull_mode: mesh3d_cull_mode_sanitize(cull_mode),
    blend_kind,
    skinned,
    lightmapped,
    forward_decal,
    tonemap_in_shader,
    tonemapping_mode,
    deband_dither_enabled,
    shadow_filter_method,
    state: RenderPipelineErr(message),
  })
  @app.timeline_trace_emit_counter_int(
    "render_3d_pipeline_cache_failed_inserts", 1,
  )
}

///|
fn mesh3d_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  for entry in backend.mesh3d_pipeline_cache {
    match entry.state {
      RenderPipelineOk(pipeline) => pipeline.release()
      RenderPipelineErr(message) => ignore(message)
    }
  }
  backend.mesh3d_pipeline_cache.clear()
}

///|
fn mesh3d_custom_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  for cache_entry in backend.mesh3d_custom_pipeline_cache.iter() {
    let (_key, state) = cache_entry
    match state {
      RenderPipelineOk(pipeline) => pipeline.release()
      RenderPipelineErr(message) => ignore(message)
    }
  }
  backend.mesh3d_custom_pipeline_cache.clear()
}

///|
struct Mesh3dVolumetricFogPipelineCacheEntry {
  pipeline_id : Int
  color_format : UInt
  msaa_sample_count : Int
  has_density_texture : Bool
  atmosphere : Bool
  view_layout_key_bits : UInt
  vertex_stride_bytes : UInt64
  pipeline_layout : @wgpu.PipelineLayout?
  state : RenderPipelineCacheState
}

///|
fn Mesh3dVolumetricFogPipelineCacheEntry::matches(
  self : Mesh3dVolumetricFogPipelineCacheEntry,
  color_format : UInt,
  msaa_sample_count : Int,
  has_density_texture : Bool,
  atmosphere : Bool,
  view_layout_key_bits : UInt,
  vertex_stride_bytes : UInt64,
) -> Bool {
  self.color_format == color_format &&
  self.msaa_sample_count == msaa_sample_count &&
  self.has_density_texture == has_density_texture &&
  self.atmosphere == atmosphere &&
  self.view_layout_key_bits == view_layout_key_bits &&
  self.vertex_stride_bytes == vertex_stride_bytes
}

///|
fn mesh3d_volumetric_fog_pipeline_available_id_get(
  backend : GpuBackend,
  color_format : UInt,
  msaa_sample_count : Int,
  has_density_texture : Bool,
  atmosphere : Bool,
  view_layout_key_bits : UInt,
  vertex_stride_bytes : UInt64,
) -> Int? {
  for entry in backend.mesh3d_volumetric_fog_pipeline_cache {
    if entry.matches(
        color_format, msaa_sample_count, has_density_texture, atmosphere, view_layout_key_bits,
        vertex_stride_bytes,
      ) {
      match entry.state {
        RenderPipelineOk(_) => {
          @app.timeline_trace_emit_counter_int(
            "render_3d_volumetric_fog_pipeline_cache_hits", 1,
          )
          return Some(entry.pipeline_id)
        }
        RenderPipelineErr(message) => {
          ignore(message)
          @app.timeline_trace_emit_counter_int(
            "render_3d_volumetric_fog_pipeline_cache_failed_hits", 1,
          )
          return None
        }
      }
    }
  }
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_pipeline_cache_misses", 1,
  )
  None
}

///|
fn mesh3d_volumetric_fog_pipeline_id_get(
  backend : GpuBackend,
  color_format : UInt,
  msaa_sample_count : Int,
  has_density_texture : Bool,
  atmosphere : Bool,
  view_layout_key_bits : UInt,
  vertex_stride_bytes : UInt64,
) -> Int? {
  for entry in backend.mesh3d_volumetric_fog_pipeline_cache {
    if entry.matches(
        color_format, msaa_sample_count, has_density_texture, atmosphere, view_layout_key_bits,
        vertex_stride_bytes,
      ) {
      return Some(entry.pipeline_id)
    }
  }
  None
}

///|
fn mesh3d_volumetric_fog_pipeline_get_by_id(
  backend : GpuBackend,
  pipeline_id : Int,
) -> @wgpu.RenderPipeline? {
  for entry in backend.mesh3d_volumetric_fog_pipeline_cache {
    if entry.pipeline_id == pipeline_id {
      match entry.state {
        RenderPipelineOk(pipeline) => return Some(pipeline)
        RenderPipelineErr(message) => {
          ignore(message)
          return None
        }
      }
    }
  }
  None
}

///|
fn mesh3d_volumetric_fog_pipeline_failed(
  backend : GpuBackend,
  color_format : UInt,
  msaa_sample_count : Int,
  has_density_texture : Bool,
  atmosphere : Bool,
  view_layout_key_bits : UInt,
  vertex_stride_bytes : UInt64,
) -> Bool {
  for entry in backend.mesh3d_volumetric_fog_pipeline_cache {
    if entry.matches(
        color_format, msaa_sample_count, has_density_texture, atmosphere, view_layout_key_bits,
        vertex_stride_bytes,
      ) {
      match entry.state {
        RenderPipelineOk(_) => return false
        RenderPipelineErr(message) => {
          ignore(message)
          return true
        }
      }
    }
  }
  false
}

///|
fn mesh3d_volumetric_fog_pipeline_set(
  backend : GpuBackend,
  color_format : UInt,
  msaa_sample_count : Int,
  has_density_texture : Bool,
  atmosphere : Bool,
  view_layout_key_bits : UInt,
  vertex_stride_bytes : UInt64,
  pipeline_layout : @wgpu.PipelineLayout,
  pipeline : @wgpu.RenderPipeline,
) -> Int {
  let pipeline_id = alloc_id(backend)
  backend.mesh3d_volumetric_fog_pipeline_cache.push({
    pipeline_id,
    color_format,
    msaa_sample_count,
    has_density_texture,
    atmosphere,
    view_layout_key_bits,
    vertex_stride_bytes,
    pipeline_layout: Some(pipeline_layout),
    state: RenderPipelineOk(pipeline),
  })
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_pipeline_cache_inserts", 1,
  )
  pipeline_id
}

///|
fn mesh3d_volumetric_fog_pipeline_set_failed(
  backend : GpuBackend,
  color_format : UInt,
  msaa_sample_count : Int,
  has_density_texture : Bool,
  atmosphere : Bool,
  view_layout_key_bits : UInt,
  vertex_stride_bytes : UInt64,
  message : String,
) -> Int {
  if mesh3d_volumetric_fog_pipeline_available_id_get(
      backend, color_format, msaa_sample_count, has_density_texture, atmosphere,
      view_layout_key_bits, vertex_stride_bytes,
    )
    is Some(pipeline_id) {
    return pipeline_id
  }
  if mesh3d_volumetric_fog_pipeline_id_get(
      backend, color_format, msaa_sample_count, has_density_texture, atmosphere,
      view_layout_key_bits, vertex_stride_bytes,
    )
    is Some(pipeline_id) {
    return pipeline_id
  }
  let pipeline_id = alloc_id(backend)
  backend.mesh3d_volumetric_fog_pipeline_cache.push({
    pipeline_id,
    color_format,
    msaa_sample_count,
    has_density_texture,
    atmosphere,
    view_layout_key_bits,
    vertex_stride_bytes,
    pipeline_layout: None,
    state: RenderPipelineErr(message),
  })
  @app.timeline_trace_emit_counter_int(
    "render_3d_volumetric_fog_pipeline_cache_failed_inserts", 1,
  )
  pipeline_id
}

///|
fn mesh3d_volumetric_fog_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  for entry in backend.mesh3d_volumetric_fog_pipeline_cache {
    match entry.state {
      RenderPipelineOk(pipeline) => pipeline.release()
      RenderPipelineErr(message) => ignore(message)
    }
    match entry.pipeline_layout {
      Some(layout) => layout.release()
      None => ()
    }
  }
  backend.mesh3d_volumetric_fog_pipeline_cache.clear()
}

///|
struct Mesh3dShadowPipelineCacheEntry {
  topology : UInt
  material_pipeline_id : UInt64
  cull_mode : Int
  material_path : Bool
  skinned : Bool
  directional_light : Bool
  pipeline : @wgpu.RenderPipeline
}

///|
struct Mesh3dMotionVectorPipelineCacheEntry {
  topology : UInt
  material_pipeline_id : UInt64
  msaa_sample_count : Int
  cull_mode : Int
  skinned : Bool
  has_previous_skin : Bool
  morphed : Bool
  has_previous_morph : Bool
  mesh_bind_group_layout_descriptor : @render_resource.BindGroupLayoutDescriptor
  mesh_bind_group_layout : @wgpu.BindGroupLayout
  pipeline : @wgpu.RenderPipeline
}

///|
fn mesh3d_shadow_pipeline_get(
  backend : GpuBackend,
  topology : UInt,
  material_pipeline_id : UInt64,
  cull_mode : Int,
  material_path : Bool,
  skinned : Bool,
  directional_light : Bool,
) -> @wgpu.RenderPipeline? {
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  for entry in backend.mesh3d_shadow_pipeline_cache {
    if entry.topology == topology &&
      entry.material_pipeline_id == material_pipeline_id &&
      entry.cull_mode == safe_cull_mode &&
      entry.material_path == material_path &&
      entry.skinned == skinned &&
      entry.directional_light == directional_light {
      @app.timeline_trace_emit_counter_int(
        "render_3d_shadow_pipeline_cache_hits", 1,
      )
      return Some(entry.pipeline)
    }
  }
  @app.timeline_trace_emit_counter_int(
    "render_3d_shadow_pipeline_cache_misses", 1,
  )
  None
}

///|
fn mesh3d_shadow_pipeline_set(
  backend : GpuBackend,
  topology : UInt,
  material_pipeline_id : UInt64,
  cull_mode : Int,
  material_path : Bool,
  skinned : Bool,
  directional_light : Bool,
  pipeline : @wgpu.RenderPipeline,
) -> Unit {
  backend.mesh3d_shadow_pipeline_cache.push({
    topology,
    material_pipeline_id,
    cull_mode: mesh3d_cull_mode_sanitize(cull_mode),
    material_path,
    skinned,
    directional_light,
    pipeline,
  })
  @app.timeline_trace_emit_counter_int(
    "render_3d_shadow_pipeline_cache_inserts", 1,
  )
}

///|
fn mesh3d_motion_vector_pipeline_get(
  backend : GpuBackend,
  topology : UInt,
  material_pipeline_id : UInt64,
  msaa_sample_count : Int,
  cull_mode : Int,
  skinned : Bool,
  has_previous_skin : Bool,
  morphed : Bool,
  has_previous_morph : Bool,
) -> Mesh3dMotionVectorPipelineCacheEntry? {
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  for entry in backend.mesh3d_motion_vector_pipeline_cache {
    if entry.topology == topology &&
      entry.material_pipeline_id == material_pipeline_id &&
      entry.msaa_sample_count == msaa_sample_count &&
      entry.cull_mode == safe_cull_mode &&
      entry.skinned == skinned &&
      entry.has_previous_skin == has_previous_skin &&
      entry.morphed == morphed &&
      entry.has_previous_morph == has_previous_morph {
      @app.timeline_trace_emit_counter_int(
        "render_3d_motion_vector_pipeline_cache_hits", 1,
      )
      return Some(entry)
    }
  }
  @app.timeline_trace_emit_counter_int(
    "render_3d_motion_vector_pipeline_cache_misses", 1,
  )
  None
}

///|
fn mesh3d_motion_vector_pipeline_set(
  backend : GpuBackend,
  entry : Mesh3dMotionVectorPipelineCacheEntry,
) -> Unit {
  backend.mesh3d_motion_vector_pipeline_cache.push(entry)
  @app.timeline_trace_emit_counter_int(
    "render_3d_motion_vector_pipeline_cache_inserts", 1,
  )
}
