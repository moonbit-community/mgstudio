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
    max_entries=entries.length().to_uint64(),
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
pub fn materialize_pipeline_cache_compute_pipeline_descriptor(
  descriptor : @render_resource.ComputePipelineDescriptor,
) -> @render_resource.ComputePipeline? raise GpuBackendError {
  guard ensure_backend() is Some(backend) else { return None }
  Some(backend.create_pipeline_cache_compute_pipeline(descriptor))
}
