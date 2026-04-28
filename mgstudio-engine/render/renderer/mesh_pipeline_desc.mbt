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
fn mesh_pipeline_desc_builder_set_blend_kind(
  builder : @wgpu_c.RenderPipelineDescBuilderObj,
  blend_kind : Int,
) -> UInt {
  if blend_kind == MESH3D_PIPELINE_BLEND_OPAQUE {
    return @wgpu_c.render_pipeline_desc_builder_disable_blend(builder)
  }
  if blend_kind == MESH3D_PIPELINE_BLEND_PREMULTIPLIED_ALPHA {
    return @wgpu_c.render_pipeline_desc_builder_set_blend_components(
      builder,
      @wgpu.BLEND_FACTOR_ONE,
      @wgpu.BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
      @wgpu.BLEND_OPERATION_ADD,
      @wgpu.BLEND_FACTOR_ONE,
      @wgpu.BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
      @wgpu.BLEND_OPERATION_ADD,
    )
  }
  if blend_kind == MESH3D_PIPELINE_BLEND_MULTIPLY {
    return @wgpu_c.render_pipeline_desc_builder_set_blend_components(
      builder,
      @wgpu.BLEND_FACTOR_DST,
      @wgpu.BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
      @wgpu.BLEND_OPERATION_ADD,
      @wgpu.BLEND_FACTOR_ONE,
      @wgpu.BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
      @wgpu.BLEND_OPERATION_ADD,
    )
  }
  @wgpu_c.render_pipeline_desc_builder_enable_alpha_blend(builder)
}

///|
fn mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
  layout : @wgpu.PipelineLayout,
  shader : @wgpu.ShaderModule,
  format : UInt,
  with_depth? : Bool = false,
  depth_write_enabled? : Bool = true,
  position3d? : Bool = false,
  alpha_blend? : Bool = true,
  blend_kind? : Int = MESH3D_PIPELINE_BLEND_ALPHA,
  topology? : UInt = @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
  cull_mode? : UInt = @wgpu.CULL_MODE_NONE,
  depth_compare_u32? : UInt = @wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
  vertex_entry? : String = "vs_main",
  fragment_entry? : String = "fs_main",
) -> @wgpu_c.WGPURenderPipelineDescriptorPtr raise GpuBackendError {
  let builder = @wgpu_c.render_pipeline_desc_builder_new(
    layout.raw_handle(),
    shader.raw_handle(),
  )
  let vertex_entry_bytes = @embedded_asset.asset_text_to_bytes(vertex_entry)
  let fragment_entry_bytes = @embedded_asset.asset_text_to_bytes(fragment_entry)
  let set_entry_points_err = @wgpu_c.render_pipeline_desc_builder_set_entry_points_utf8(
    builder,
    vertex_entry_bytes,
    vertex_entry_bytes.length().to_uint64(),
    fragment_entry_bytes,
    fragment_entry_bytes.length().to_uint64(),
  )
  let set_format_err = @wgpu_c.render_pipeline_desc_builder_set_color_target_format(
    builder, format,
  )
  let set_blend_err = if alpha_blend {
    mesh_pipeline_desc_builder_set_blend_kind(builder, blend_kind)
  } else {
    mesh_pipeline_desc_builder_set_blend_kind(
      builder,
      MESH3D_PIPELINE_BLEND_OPAQUE,
    )
  }
  let vertex_stride = if position3d { MESH3D_VERTEX_STRIDE_BYTES } else { 32UL }
  let pos_format = if position3d {
    @wgpu.VERTEX_FORMAT_FLOAT32X3
  } else {
    @wgpu.VERTEX_FORMAT_FLOAT32X2
  }
  let normal_offset = 12UL
  let uv_offset = if position3d { 24UL } else { 8UL }
  let color_offset = if position3d { 32UL } else { 16UL }
  let joints_offset = 48UL
  let weights_offset = 64UL
  let set_vertex_layout_err = @wgpu_c.render_pipeline_desc_builder_set_vertex_buffer_layout(
    builder,
    vertex_stride,
    @wgpu.VERTEX_STEP_MODE_VERTEX,
  )
  let pos_err = @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
    builder, pos_format, 0UL, 0U,
  )
  let normal_err = if position3d {
    @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
      builder,
      @wgpu.VERTEX_FORMAT_FLOAT32X3,
      normal_offset,
      1U,
    )
  } else {
    0U
  }
  let uv_location = if position3d { 2U } else { 1U }
  let color_location = if position3d { 5U } else { 2U }
  let uv_err = @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
    builder,
    @wgpu.VERTEX_FORMAT_FLOAT32X2,
    uv_offset,
    uv_location,
  )
  let color_err = @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
    builder,
    @wgpu.VERTEX_FORMAT_FLOAT32X4,
    color_offset,
    color_location,
  )
  let joints_err = if position3d {
    @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
      builder,
      @wgpu.VERTEX_FORMAT_UINT32X4,
      joints_offset,
      6U,
    )
  } else {
    0U
  }
  let weights_err = if position3d {
    @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
      builder,
      @wgpu.VERTEX_FORMAT_FLOAT32X4,
      weights_offset,
      7U,
    )
  } else {
    0U
  }
  if set_entry_points_err != 0U ||
    set_format_err != 0U ||
    set_blend_err != 0U ||
    set_vertex_layout_err != 0U ||
    pos_err != 0U ||
    normal_err != 0U ||
    uv_err != 0U ||
    color_err != 0U ||
    joints_err != 0U ||
    weights_err != 0U {
    @wgpu_c.render_pipeline_desc_builder_free(builder)
    fatal(
      "wgpu: failed to configure mesh vertex attributes for runtime mesh pipeline",
    )
  }
  let set_topology_err = @wgpu_c.render_pipeline_desc_builder_set_topology(
    builder, topology,
  )
  cull_mode |> ignore
  if set_topology_err != 0U {
    @wgpu_c.render_pipeline_desc_builder_free(builder)
    fatal("wgpu: failed to configure mesh pipeline primitive state")
  }
  if with_depth {
    let set_depth_err = @wgpu_c.render_pipeline_desc_builder_set_depth_stencil(
      builder,
      @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
      depth_write_enabled,
      depth_compare_u32,
    )
    if set_depth_err != 0U {
      @wgpu_c.render_pipeline_desc_builder_free(builder)
      fatal("wgpu: failed to configure mesh pipeline depth-stencil state")
    }
  }
  let desc = @wgpu_c.render_pipeline_desc_builder_finish(builder)
  if @wgpu_c.render_pipeline_descriptor_ptr_is_null(desc) {
    let last_error = @wgpu_c.render_pipeline_desc_builder_last_error_u32(
      builder,
    )
    let last_error_args = @wgpu_c.render_pipeline_desc_builder_last_error_args_u64(
      builder,
    )
    @wgpu_c.render_pipeline_desc_builder_free(builder)
    fatal(
      "wgpu: mesh pipeline descriptor builder finish failed (error=\{last_error.reinterpret_as_int()}, args=\{last_error_args.to_int()})",
    )
  }
  render_pipeline_descriptor_set_cull_mode(desc, cull_mode)
  desc
}
