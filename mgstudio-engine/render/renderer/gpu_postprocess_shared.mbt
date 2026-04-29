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
fn clamp_non_negative(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn postprocess_define_keys_map(
  define_keys : Array[String],
) -> @hashmap.HashMap[String, Bool] {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  for key in define_keys {
    defines.set(key, true)
  }
  defines
}

///|
priv struct FullscreenPostprocessWgslSources {
  vertex_source : String
  fragment_source : String
}

///|
fn load_fullscreen_vertex_wgsl_required(
  backend : GpuBackend,
) -> String raise GpuBackendError {
  load_wgsl_from_assets_required(
    backend, "core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl",
  )
}

///|
fn load_postprocess_fragment_wgsl_with_defines_required(
  backend : GpuBackend,
  rel : String,
  define_keys : Array[String],
) -> String raise GpuBackendError {
  load_wgsl_preprocessed(
    backend.assets_base,
    rel,
    postprocess_define_keys_map(define_keys),
    default_wgsl_value_defines(),
    @hashmap.HashMap::new(),
    @hashmap.HashMap::new(),
  )
}

///|
fn load_fullscreen_postprocess_wgsl_modules_with_defines_required(
  backend : GpuBackend,
  rel : String,
  define_keys : Array[String],
) -> FullscreenPostprocessWgslSources raise GpuBackendError {
  FullscreenPostprocessWgslSources::{
    vertex_source: load_fullscreen_vertex_wgsl_required(backend),
    fragment_source: load_postprocess_fragment_wgsl_with_defines_required(
      backend, rel, define_keys,
    ),
  }
}

///|
const POSTPROCESS_BLEND_MODE_NONE : Int = 0

///|
const POSTPROCESS_BLEND_MODE_CONSTANT_ENERGY : Int = 2

///|
const POSTPROCESS_BLEND_MODE_CONSTANT_ADDITIVE : Int = 3

///|
fn postprocess_builder_set_blend_mode(
  builder : @wgpu.RenderPipelineDescBuilder,
  blend_mode : Int,
) -> Unit raise GpuBackendError {
  if blend_mode == POSTPROCESS_BLEND_MODE_NONE {
    return
  }
  let (color_src, color_dst) = if blend_mode ==
    POSTPROCESS_BLEND_MODE_CONSTANT_ENERGY {
    (@wgpu.BLEND_FACTOR_CONSTANT, @wgpu.BLEND_FACTOR_ONE_MINUS_CONSTANT)
  } else if blend_mode == POSTPROCESS_BLEND_MODE_CONSTANT_ADDITIVE {
    (@wgpu.BLEND_FACTOR_CONSTANT, @wgpu.BLEND_FACTOR_ONE)
  } else {
    fatal("wgpu: unsupported postprocess blend mode: \{blend_mode.to_string()}")
  }
  builder.set_blend_components(
    color_src,
    color_dst,
    @wgpu.BLEND_OPERATION_ADD,
    @wgpu.BLEND_FACTOR_ZERO,
    @wgpu.BLEND_FACTOR_ONE,
    @wgpu.BLEND_OPERATION_ADD,
  ) catch {
    err => {
      err |> ignore
      fatal("wgpu: failed to configure postprocess custom blend state")
    }
  }
}

///|
fn create_postprocess_shader_module(
  backend : GpuBackend,
  source : String,
  label : String,
) -> @wgpu.ShaderModule raise GpuBackendError {
  backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let shader = backend.device.create_shader_module_wgsl(source)
  let shader_result = backend.device.pop_error_scope_sync_result(
    backend.instance,
  )
  if shader_result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      shader_result,
      "wgpu: failed to create \{label} shader module",
    )
    shader.release()
    fatal(message)
  }
  shader
}

///|
fn create_postprocess_pipeline_split_modules(
  backend : GpuBackend,
  layout : @wgpu.PipelineLayout,
  vertex_source : String,
  fragment_source : String,
  format : @wgpu.TextureFormat,
  fs_entry : String,
  blend_mode : Int,
  label : String,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  let vertex_sm = create_postprocess_shader_module(
    backend,
    vertex_source,
    "\{label} postprocess vertex",
  )
  let fragment_sm = create_postprocess_shader_module(
    backend,
    fragment_source,
    "\{label} postprocess fragment",
  ) catch {
    err => {
      vertex_sm.release()
      raise err
    }
  }
  let builder = @wgpu.RenderPipelineDescBuilder::new(vertex_sm, layout~) catch {
    err => {
      err |> ignore
      vertex_sm.release()
      fragment_sm.release()
      fatal("wgpu: failed to build postprocess pipeline descriptor")
    }
  }
  try {
    builder.set_entry_points("fullscreen_vertex_shader", fs_entry)
    builder.set_color_target_format(format)
    postprocess_builder_set_blend_mode(builder, blend_mode)
  } catch {
    err => {
      err |> ignore
      vertex_sm.release()
      fragment_sm.release()
      fatal("wgpu: failed to build postprocess pipeline descriptor")
    }
  }
  backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let pipeline = try {
    let desc = builder.finish_descriptor_ptr()
    render_pipeline_descriptor_set_vertex_module(desc, vertex_sm)
    render_pipeline_descriptor_set_fragment_module(desc, fragment_sm)
    let pipeline = backend.device.create_render_pipeline_ptr(desc)
    @wgpu_c.render_pipeline_descriptor_free(desc)
    builder.free()
    pipeline
  } catch {
    err => {
      err |> ignore
      ignore(backend.device.pop_error_scope_sync_result(backend.instance))
      vertex_sm.release()
      fragment_sm.release()
      fatal("wgpu: failed to build postprocess pipeline descriptor")
    }
  }
  let pipeline_result = backend.device.pop_error_scope_sync_result(
    backend.instance,
  )
  if pipeline_result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      pipeline_result,
      "wgpu: failed to create \{label} postprocess pipeline",
    )
    pipeline.release()
    vertex_sm.release()
    fragment_sm.release()
    fatal(message)
  }
  pipeline.set_label(label)
  vertex_sm.release()
  fragment_sm.release()
  pipeline
}
