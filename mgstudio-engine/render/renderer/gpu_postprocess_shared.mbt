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
fn load_wgsl_asset_source_required(
  backend : GpuBackend,
  rel : String,
) -> String raise GpuBackendError {
  let base = backend.assets_base.trim().to_string()
  if base == "" {
    fatal("wgpu: assets_base is empty; cannot load shader: \{rel}")
  }
  let normalized_rel = normalize_shader_rel_path(rel)
  let full_path = @path.Path::join(base, normalized_rel).normalize().to_string()
  @fs.read_file_to_string(full_path) catch {
    err =>
      fatal(
        "wgpu: failed to read shader asset \{normalized_rel}: \{err.to_string()}",
      )
  }
}

///|
fn preprocess_manual_wgsl_source(
  backend : GpuBackend,
  source : String,
  define_keys : Array[String],
  value_define_pairs : Array[(String, Int)],
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  for key in define_keys {
    defines.set(key, true)
  }
  let value_defines = default_wgsl_value_defines()
  for pair in value_define_pairs {
    let (key, value) = pair
    value_defines.set(key, value)
  }
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(backend.assets_base)
  preprocess_wgsl_source(
    backend.assets_base,
    source,
    defines,
    value_defines,
    visited,
    modules,
  )
}

///|
fn replace_shader_substring_all(
  source : String,
  from : String,
  to : String,
) -> String {
  if from == "" {
    return source
  }
  let mut out = ""
  let mut first = true
  for piece in source.split(from) {
    if first {
      first = false
    } else {
      out = out + to
    }
    out = out + piece.to_string()
  }
  out
}

///|
fn load_fullscreen_postprocess_wgsl_with_defines_required(
  backend : GpuBackend,
  rel : String,
  define_keys : Array[String],
) -> String raise GpuBackendError {
  let fullscreen_source = load_wgsl_asset_source_required(
    backend, "shaders/bevy_core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl",
  )
  let main_source = load_wgsl_asset_source_required(backend, rel)
  let merged_source = merge_fullscreen_postprocess_source(
    main_source, fullscreen_source,
  )
  preprocess_manual_wgsl_source(backend, merged_source, define_keys, [])
}

///|
fn fullscreen_vertex_shader_function_source(source : String) -> String {
  let marker = "@vertex"
  let parts : Array[String] = []
  for piece in source.split(marker) {
    parts.push(piece.to_string())
  }
  if parts.length() < 2 {
    return source
  }
  let mut suffix = ""
  for i in 1..<parts.length() {
    if i > 1 {
      suffix = suffix + marker
    }
    suffix = suffix + parts[i]
  }
  marker + suffix
}

///|
fn merge_fullscreen_postprocess_source(
  main_source : String,
  fullscreen_source : String,
) -> String {
  if main_source.contains("fn fullscreen_vertex_shader(") {
    return main_source
  }
  let imports_fullscreen_vertex_output = main_source.contains(
      "#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput",
    ) ||
    main_source.contains("fullscreen_vertex_shader::FullscreenVertexOutput")
  if main_source.contains("struct FullscreenVertexOutput") ||
    imports_fullscreen_vertex_output {
    return "\{main_source}\n\{fullscreen_vertex_shader_function_source(fullscreen_source)}"
  }
  "\{fullscreen_source}\n\{main_source}"
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
