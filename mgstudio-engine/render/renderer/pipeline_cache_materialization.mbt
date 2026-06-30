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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/pipeline_cache.rs`.

///|
fn pipeline_cache_shader_bool_defines(
  shader_defs : Array[@render_resource.ShaderDefVal],
) -> @hashmap.HashMap[String, Bool] {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  for shader_def in shader_defs {
    match shader_def {
      Flag(name) => defines.set(name, true)
      Bool(name, value) => defines.set(name, value)
      Int(_, _) | UInt(_, _) | String(_, _) => ()
    }
  }
  defines
}

///|
fn pipeline_cache_shader_value_defines(
  shader_defs : Array[@render_resource.ShaderDefVal],
) -> @hashmap.HashMap[String, @wgsl_common.ShaderDefValue] {
  let value_defines = default_wgsl_value_defines()
  for shader_def in shader_defs {
    match shader_def {
      Int(name, value) =>
        value_defines.set(name, @wgsl_common.ShaderDefValue::Int(value))
      UInt(name, value) =>
        value_defines.set(name, @wgsl_common.ShaderDefValue::UInt(value))
      String(name, value) =>
        value_defines.set(name, @wgsl_common.ShaderDefValue::Raw(value))
      Bool(_, _) | Flag(_) => ()
    }
  }
  value_defines
}

///|
fn create_bind_group_layout_from_render_resource_descriptor(
  backend : GpuBackend,
  descriptor : @render_resource.BindGroupLayoutDescriptor,
  label_prefix : String,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let entries = descriptor.entries()
  if entries.length() == 0 {
    return backend.device.create_bind_group_layout_empty()
  }
  let builder = @wgpu.BindGroupLayoutBuilder::new(
    max_entries=mesh3d_bind_group_layout_descriptor_capacity(descriptor),
  )
  for entry in entries {
    if !mesh3d_add_render_resource_layout_entry(builder, entry) {
      builder.free()
      fatal(
        "wgpu: unsupported bind group layout descriptor entry in " +
        descriptor.label(),
      )
    }
  }
  builder.finish(backend.device, label="\{label_prefix}_\{descriptor.label()}")
}

///|
fn GpuBackend::create_pipeline_cache_compute_layout(
  self : GpuBackend,
  descriptor : @render_resource.ComputePipelineDescriptor,
) -> @wgpu.PipelineLayout raise GpuBackendError {
  let bind_group_layouts : Array[@wgpu.BindGroupLayout] = []
  let layout_descriptors = descriptor.layout()
  for index in 0..<layout_descriptors.length() {
    let layout_descriptor = layout_descriptors[index]
    let layout = create_bind_group_layout_from_render_resource_descriptor(
      self,
      layout_descriptor,
      "mgstudio_pipeline_cache_compute_bgl_\{index}",
    )
    bind_group_layouts.push(layout)
  }
  let layout = if descriptor.immediate_size > 0U {
    self.device.create_pipeline_layout_with_immediates(bind_group_layouts, [
      (ss(@wgpu.SHADER_STAGE_COMPUTE), 0U, descriptor.immediate_size),
    ])
  } else {
    self.device.create_pipeline_layout_many(bind_group_layouts)
  }
  match descriptor.label() {
    Some(label) => layout.set_label("\{label} layout")
    None => layout.set_label("mgstudio_pipeline_cache_compute_layout")
  }
  layout
}

///|
fn GpuBackend::create_pipeline_cache_compute_pipeline(
  self : GpuBackend,
  descriptor : @render_resource.ComputePipelineDescriptor,
) -> @render_resource.ComputePipeline raise GpuBackendError {
  let shader_path = match descriptor.shader() {
    Some(path) => path
    None =>
      raise GpuBackendError::ShaderNotReady(
        "compute pipeline shader path is not configured",
      )
  }
  let shader_defs = descriptor.shader_defs()
  let source = load_wgsl_preprocessed(
    self.assets_base,
    shader_path,
    pipeline_cache_shader_bool_defines(shader_defs),
    pipeline_cache_shader_value_defines(shader_defs),
  )
  let shader = self.device.create_shader_module_wgsl(source)
  let layout = self.create_pipeline_cache_compute_layout(descriptor) catch {
    err => {
      shader.release()
      raise err
    }
  }
  let entry = descriptor.entry_point().unwrap_or("main")
  let pipeline = self.device.create_compute_pipeline_with_layout_entry(
    layout, shader, entry,
  ) catch {
    err => {
      shader.release()
      fatal(
        "wgpu: failed to create pipeline-cache compute pipeline \{shader_path}:\{entry}: \{err.message()}",
      )
    }
  }
  match descriptor.label() {
    Some(label) => pipeline.set_label(label)
    None => pipeline.set_label("mgstudio_pipeline_cache_compute_pipeline")
  }
  shader.release()
  @render_resource.ComputePipeline::from_wgpu(pipeline)
}

///|
fn GpuBackend::create_pipeline_cache_render_layout(
  self : GpuBackend,
  descriptor : @render_resource.RenderPipelineDescriptor,
) -> @wgpu.PipelineLayout? raise GpuBackendError {
  let layout_descriptors = descriptor.layout()
  if layout_descriptors.length() == 0 && descriptor.immediate_size == 0U {
    return None
  }
  let bind_group_layouts : Array[@wgpu.BindGroupLayout] = []
  for index in 0..<layout_descriptors.length() {
    let layout_descriptor = layout_descriptors[index]
    let layout = create_bind_group_layout_from_render_resource_descriptor(
      self,
      layout_descriptor,
      "mgstudio_pipeline_cache_render_bgl_\{index}",
    )
    bind_group_layouts.push(layout)
  }
  let layout = if descriptor.immediate_size > 0U {
    self.device.create_pipeline_layout_with_immediates(bind_group_layouts, [
      (
        ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT),
        0U,
        descriptor.immediate_size,
      ),
    ])
  } else {
    self.device.create_pipeline_layout_many(bind_group_layouts)
  }
  match descriptor.label() {
    Some(label) => layout.set_label("\{label} layout")
    None => layout.set_label("mgstudio_pipeline_cache_render_layout")
  }
  Some(layout)
}

///|
fn pipeline_cache_apply_vertex_buffer_layout(
  builder : @wgpu.RenderPipelineDescBuilder,
  vertex_buffer_layout : @mesh.VertexBufferLayout,
  first : Bool,
) -> Unit raise @wgpu.RenderPipelineDescError {
  if first {
    builder.set_vertex_buffer_layout(
      vertex_buffer_layout.array_stride.to_uint64(),
      mesh_vertex_step_mode_to_wgpu(vertex_buffer_layout.step_mode),
    )
  } else {
    ignore(
      builder.add_vertex_buffer_layout(
        vertex_buffer_layout.array_stride.to_uint64(),
        mesh_vertex_step_mode_to_wgpu(vertex_buffer_layout.step_mode),
      ),
    )
  }
  for attribute in vertex_buffer_layout.attributes {
    builder.add_vertex_attribute(
      mesh_vertex_format_to_wgpu(attribute.format),
      attribute.offset.to_uint64(),
      attribute.shader_location.reinterpret_as_uint(),
    )
  }
}

///|
fn pipeline_cache_apply_vertex_buffer_layouts(
  builder : @wgpu.RenderPipelineDescBuilder,
  vertex_buffer_layouts : Array[@mesh.VertexBufferLayout],
) -> Unit raise @wgpu.RenderPipelineDescError {
  for index in 0..<vertex_buffer_layouts.length() {
    pipeline_cache_apply_vertex_buffer_layout(
      builder,
      vertex_buffer_layouts[index],
      index == 0,
    )
  }
}

///|
fn pipeline_cache_apply_fragment_targets(
  builder : @wgpu.RenderPipelineDescBuilder,
  fragment : @render_resource.FragmentState?,
) -> Unit raise @wgpu.RenderPipelineDescError {
  match fragment {
    None => builder.clear_fragment()
    Some(fragment_state) => {
      let targets = fragment_state.targets()
      builder.set_color_target_count(targets.length().reinterpret_as_uint())
      for index in 0..<targets.length() {
        let index_u = index.reinterpret_as_uint()
        match targets[index] {
          Some(target) => {
            builder.set_color_target_format_at(index_u, tf(target.format()))
            builder.set_color_target_write_mask_at(index_u, target.write_mask())
          }
          None => builder.set_color_target_unused_at(index_u)
        }
      }
    }
  }
}

///|
fn pipeline_cache_apply_blend_state(
  builder : @wgpu.RenderPipelineDescBuilder,
  fragment : @render_resource.FragmentState?,
) -> Unit raise @wgpu.RenderPipelineDescError {
  let blend = match fragment {
    Some(fragment_state) => {
      let targets = fragment_state.targets()
      if targets.length() > 0 {
        match targets[0] {
          Some(target) => target.blend()
          None => None
        }
      } else {
        None
      }
    }
    None => None
  }
  match blend {
    Some(state) => {
      let color = state.color()
      let alpha = state.alpha()
      builder.set_blend_components(
        color.src_factor(),
        color.dst_factor(),
        color.operation(),
        alpha.src_factor(),
        alpha.dst_factor(),
        alpha.operation(),
      )
    }
    None => builder.disable_blend()
  }
}

///|
fn pipeline_cache_apply_primitive_state(
  builder : @wgpu.RenderPipelineDescBuilder,
  primitive : @render_resource.PrimitiveState,
) -> Unit raise GpuBackendError {
  if primitive.front_face != @wgpu.FRONT_FACE_CCW {
    fatal("wgpu: render pipeline cache cannot yet express non-CCW front_face")
  }
  try {
    builder.set_topology_u32(primitive.topology)
    match primitive.strip_index_format {
      Some(format) => builder.set_strip_index_format_u32(format)
      None => ()
    }
    match primitive.cull_mode {
      Some(cull_mode) => builder.set_cull_mode_u32(cull_mode)
      None => builder.set_cull_mode_u32(@wgpu.CULL_MODE_NONE)
    }
    match primitive.polygon_mode {
      Some(polygon_mode) => builder.set_polygon_mode_u32(polygon_mode)
      None => ()
    }
    if primitive.unclipped_depth {
      builder.set_unclipped_depth(true)
    }
  } catch {
    err =>
      fatal("wgpu: failed to apply render primitive state: \{err.message()}")
  }
}

///|
fn pipeline_cache_apply_depth_stencil_state(
  builder : @wgpu.RenderPipelineDescBuilder,
  depth_stencil : @render_resource.DepthStencilState?,
) -> Unit raise GpuBackendError {
  match depth_stencil {
    None => ()
    Some(depth) =>
      builder.set_depth_stencil(
        tf(depth.format),
        depth_write_enabled=depth.depth_write_enabled,
        depth_compare_u32=depth.depth_compare,
        depth_bias=depth.bias_constant,
        depth_bias_slope_scale=depth.bias_slope_scale,
        depth_bias_clamp=depth.bias_clamp,
      ) catch {
        err =>
          fatal("wgpu: failed to apply render depth state: \{err.message()}")
      }
  }
}

///|
fn pipeline_cache_apply_multisample_state(
  builder : @wgpu.RenderPipelineDescBuilder,
  multisample : @render_resource.MultisampleState,
) -> Unit raise GpuBackendError {
  let mask = if multisample.mask == 0xffffffffffffffffUL {
    0xffffffffU
  } else if multisample.mask > 0xffffffffUL {
    fatal("wgpu: render pipeline cache cannot express 64-bit MSAA mask")
  } else {
    multisample.mask.to_uint()
  }
  builder.set_multisample(
    multisample.count,
    mask_u32=mask,
    alpha_to_coverage_enabled=multisample.alpha_to_coverage_enabled,
  ) catch {
    err =>
      fatal("wgpu: failed to apply render multisample state: \{err.message()}")
  }
}

///|
fn GpuBackend::create_pipeline_cache_render_pipeline(
  self : GpuBackend,
  descriptor : @render_resource.RenderPipelineDescriptor,
) -> @render_resource.RenderPipeline raise GpuBackendError {
  let vertex = descriptor.vertex()
  let vertex_shader_path = match vertex.shader {
    Some(path) => path
    None =>
      raise GpuBackendError::ShaderNotReady(
        "render pipeline vertex shader path is not configured",
      )
  }
  let vertex_source = load_wgsl_preprocessed(
    self.assets_base,
    vertex_shader_path,
    pipeline_cache_shader_bool_defines(vertex.shader_defs),
    pipeline_cache_shader_value_defines(vertex.shader_defs),
  )
  let vertex_shader = self.device.create_shader_module_wgsl(vertex_source)
  let fragment = descriptor.fragment()
  let fragment_shader : @wgpu.ShaderModule? = match fragment {
    Some(fragment_state) =>
      match fragment_state.shader() {
        Some(fragment_shader_path) => {
          let fragment_source = load_wgsl_preprocessed(
            self.assets_base,
            fragment_shader_path,
            pipeline_cache_shader_bool_defines(fragment_state.shader_defs()),
            pipeline_cache_shader_value_defines(fragment_state.shader_defs()),
          )
          Some(self.device.create_shader_module_wgsl(fragment_source))
        }
        None =>
          raise GpuBackendError::ShaderNotReady(
            "render pipeline fragment shader path is not configured",
          )
      }
    None => None
  }
  let layout = self.create_pipeline_cache_render_layout(descriptor) catch {
    err => {
      vertex_shader.release()
      match fragment_shader {
        Some(shader) => shader.release()
        None => ()
      }
      raise err
    }
  }
  let pipeline = try {
    let builder = match layout {
      Some(pipeline_layout) =>
        @wgpu.RenderPipelineDescBuilder::new(
          vertex_shader,
          layout=pipeline_layout,
        )
      None => @wgpu.RenderPipelineDescBuilder::new(vertex_shader)
    }
    let vertex_entry = vertex.entry_point.unwrap_or("vertex")
    let fragment_entry = match fragment {
      Some(fragment_state) => fragment_state.entry_point().unwrap_or("fragment")
      None => "fragment"
    }
    builder.set_entry_points(vertex_entry, fragment_entry)
    match fragment_shader {
      Some(shader) => builder.set_fragment_module(shader)
      None => builder.clear_fragment()
    }
    pipeline_cache_apply_fragment_targets(builder, fragment)
    pipeline_cache_apply_primitive_state(builder, descriptor.primitive)
    pipeline_cache_apply_depth_stencil_state(builder, descriptor.depth_stencil)
    pipeline_cache_apply_multisample_state(builder, descriptor.multisample)
    pipeline_cache_apply_vertex_buffer_layouts(builder, vertex.buffers)
    pipeline_cache_apply_blend_state(builder, fragment)
    builder.create_pipeline(self.device)
  } catch {
    err => {
      vertex_shader.release()
      match fragment_shader {
        Some(shader) => shader.release()
        None => ()
      }
      fatal(
        "wgpu: failed to create pipeline-cache render pipeline \{vertex_shader_path}: \{to_repr(err).to_string()}",
      )
    }
  }
  match descriptor.label() {
    Some(label) => pipeline.set_label(label)
    None => pipeline.set_label("mgstudio_pipeline_cache_render_pipeline")
  }
  vertex_shader.release()
  match fragment_shader {
    Some(shader) => shader.release()
    None => ()
  }
  @render_resource.RenderPipeline::from_wgpu(pipeline)
}

///|
pub fn materialize_pipeline_cache_render_pipeline_descriptor(
  descriptor : @render_resource.RenderPipelineDescriptor,
) -> @render_resource.RenderPipeline? raise GpuBackendError {
  guard ensure_backend() is Some(backend) else { return None }
  Some(backend.create_pipeline_cache_render_pipeline(descriptor))
}

///|
pub fn materialize_pipeline_cache_compute_pipeline_descriptor(
  descriptor : @render_resource.ComputePipelineDescriptor,
) -> @render_resource.ComputePipeline? raise GpuBackendError {
  guard ensure_backend() is Some(backend) else { return None }
  Some(backend.create_pipeline_cache_compute_pipeline(descriptor))
}
