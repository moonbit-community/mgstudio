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
fn load_postprocess_wgsl_with_defines_required(
  rel : String,
  define_keys : Array[String],
) -> String raise GpuBackendError {
  let normalized_rel = normalize_shader_rel_path(rel)
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  for key in define_keys {
    defines.set(key, true)
  }
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = copy_registered_wgsl_import_module_paths()
  load_wgsl_preprocessed(
    "", normalized_rel, defines, value_defines, visited, modules,
  )
}

///|
fn load_wgsl_with_defines_required(
  backend : GpuBackend,
  rel : String,
  define_keys : Array[String],
) -> String raise GpuBackendError {
  let base = backend.assets_base.trim().to_string()
  if base == "" {
    fatal("wgpu: assets_base is empty; cannot load shader: " + rel)
  }
  let normalized_rel = normalize_shader_rel_path(rel)
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  for key in define_keys {
    defines.set(key, true)
  }
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(base)
  load_wgsl_preprocessed(
    base, normalized_rel, defines, value_defines, visited, modules,
  )
}

///|
fn load_fullscreen_postprocess_wgsl_with_defines_required(
  rel : String,
  define_keys : Array[String],
) -> String raise GpuBackendError {
  let modules = copy_registered_wgsl_import_module_paths()
  let fullscreen_defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let fullscreen_value_defines = default_wgsl_value_defines()
  let fullscreen_visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let fullscreen_source = load_wgsl_preprocessed(
    "", "shaders/bevy/bevy_core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl",
    fullscreen_defines, fullscreen_value_defines, fullscreen_visited, modules,
  )
  let main_source = load_postprocess_wgsl_with_defines_required(
    rel, define_keys,
  )
  if main_source.contains("fn fullscreen_vertex_shader(") {
    return main_source
  }
  fullscreen_source + "\n" + main_source
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
    fatal("wgpu: unsupported postprocess blend mode: " + blend_mode.to_string())
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
fn create_postprocess_pipeline(
  backend : GpuBackend,
  layout : @wgpu.PipelineLayout,
  source : String,
  format : @wgpu.TextureFormat,
  fs_entry : String,
  blend_mode : Int,
  label : String,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  let sm = backend.device.create_shader_module_wgsl(source)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(sm, layout~)
    builder.set_entry_points("fullscreen_vertex_shader", fs_entry)
    builder.set_color_target_format(format)
    postprocess_builder_set_blend_mode(builder, blend_mode)
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      err |> ignore
      sm.release()
      fatal("wgpu: failed to build postprocess pipeline descriptor")
    }
  }
  pipeline.set_label(label)
  sm.release()
  pipeline
}
