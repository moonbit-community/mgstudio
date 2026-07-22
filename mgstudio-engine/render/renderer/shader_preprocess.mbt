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
fn u16le_pack(xs : Array[Int]) -> Bytes {
  Bytes::makei(xs.length() * 2, i => {
    let v = xs[i / 2]
    let b = if i % 2 == 0 { v & 0xFF } else { (v >> 8) & 0xFF }
    b.to_byte()
  })
}

///|
fn u32le_pack(xs : Array[UInt]) -> Bytes {
  let n = xs.length()
  let bytes = Array::make(n * 4, (0).to_byte())
  for i in 0..<n {
    u32le_write_into(bytes, i * 4, xs[i])
  }
  Bytes::from_array(bytes)
}

///|
fn f32le_pack(xs : Array[Float]) -> Bytes {
  let n = xs.length()
  let bytes = Array::make(n * 4, (0).to_byte())
  for i in 0..<n {
    u32le_write_into(bytes, i * 4, f32_bits(xs[i]))
  }
  Bytes::from_array(bytes)
}

///|
fn bytes_fixed_staging_make(len : Int) -> FixedArray[Byte] {
  if len <= 0 {
    return []
  }
  Bytes::make(len, (0).to_byte()).to_fixedarray()
}

///|
fn u32le_write_into(
  bytes : Array[Byte],
  byte_offset : Int,
  word : UInt,
) -> Unit {
  bytes[byte_offset] = (word & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 1] = ((word >> 8) & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 2] = ((word >> 16) & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 3] = ((word >> 24) & 0xFFU).reinterpret_as_int().to_byte()
}

///|
fn u32le_write_into_fixed(
  bytes : FixedArray[Byte],
  byte_offset : Int,
  word : UInt,
) -> Unit {
  bytes[byte_offset] = (word & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 1] = ((word >> 8) & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 2] = ((word >> 16) & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 3] = ((word >> 24) & 0xFFU).reinterpret_as_int().to_byte()
}

///|
fn f32le_write_into_fixed(
  bytes : FixedArray[Byte],
  byte_offset : Int,
  value : Float,
) -> Unit {
  u32le_write_into_fixed(bytes, byte_offset, f32_bits(value))
}

///|
fn normalize_shader_rel_path(rel : String) -> String {
  @shader_compile.normalize_shader_rel_path(rel)
}

///|
fn ensure_renderer_shader_sources_registered() -> Unit {
  @shader_compile.ensure_startup_shader_sources_once(fn() {
    register_embedded_wgsl_sources()
  })
}

///|
fn[T] raise_shader_compile_error(
  err : @shader_compile.ShaderCompileError,
) -> T raise GpuBackendError {
  match err {
    MissingRegisteredSource(_)
    | MissingPreparedSourceDefs(_)
    | MissingStartupRegisteredSource(_) =>
      raise ShaderNotReady("wgpu: \{err.message()}")
    _ => fatal("wgpu: \{err.message()}")
  }
}

///|
pub fn clear_registered_wgsl_source_registry() -> Unit {
  @shader_compile.clear_registered_shader_sources()
}

///|
pub fn register_wgsl_source(rel_path : String, source : String) -> Unit {
  @shader_compile.register_shader_source(rel_path, source)
}

///|
fn registered_wgsl_source_required(
  rel_path : String,
) -> String raise GpuBackendError {
  ensure_renderer_shader_sources_registered()
  @shader_compile.registered_shader_source_required(rel_path) catch {
    err => raise_shader_compile_error(err)
  }
}

///|
fn default_wgsl_value_defines() -> @hashmap.HashMap[
  String,
  @wgsl_common.ShaderDefValue,
] {
  let value_defines = @shader_compile.default_shader_value_defines()
  value_defines.remove("PER_OBJECT_BUFFER_BATCH_SIZE")
  value_defines.set(
    "MAX_DIRECTIONAL_LIGHTS",
    UInt(MESH3D_MAX_DIRECTIONAL_LIGHTS),
  )
  value_defines.set(
    "MAX_CASCADES_PER_LIGHT",
    UInt(MESH3D_MAX_CASCADES_PER_LIGHT),
  )
  value_defines.set("MAX_RECT_LIGHTS", UInt(MESH3D_MAX_RECT_LIGHTS))
  value_defines.set("AVAILABLE_STORAGE_BUFFER_BINDINGS", UInt(8U))
  value_defines
}

///|
fn wgsl_def_int(value : Int) -> @wgsl_common.ShaderDefValue {
  Int(value)
}

///|
fn mesh2d_pipeline_value_defines() -> @hashmap.HashMap[
  String,
  @wgsl_common.ShaderDefValue,
] {
  let value_defines = default_wgsl_value_defines()
  value_defines.set(
    "PER_OBJECT_BUFFER_BATCH_SIZE",
    wgsl_def_int(MESH2D_PER_OBJECT_BUFFER_BATCH_SIZE),
  )
  value_defines
}

///|
fn preprocess_wgsl_source(
  assets_base : String,
  source : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, @wgsl_common.ShaderDefValue],
) -> String raise GpuBackendError {
  ensure_renderer_shader_sources_registered()
  @shader_compile.ShaderCompileRequest::for_source(
    assets_base, source, defines, value_defines,
  ).compile() catch {
    err => raise_shader_compile_error(err)
  }
}

///|
fn load_wgsl_preprocessed(
  assets_base : String,
  rel : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, @wgsl_common.ShaderDefValue],
) -> String raise GpuBackendError {
  ensure_renderer_shader_sources_registered()
  @shader_compile.ShaderCompileRequest::for_path(
    assets_base, rel, defines, value_defines,
  ).compile() catch {
    err => raise_shader_compile_error(err)
  }
}

///|
fn load_wgsl_from_assets_required(
  backend : GpuBackend,
  rel : String,
) -> String raise GpuBackendError {
  load_wgsl_from_assets_base_required(backend.assets_base, rel)
}

///|
fn load_wgsl_from_assets_base_required(
  assets_base : String,
  rel : String,
) -> String raise GpuBackendError {
  load_wgsl_preprocessed(
    assets_base,
    rel,
    HashMap([]),
    default_wgsl_value_defines(),
  )
}
