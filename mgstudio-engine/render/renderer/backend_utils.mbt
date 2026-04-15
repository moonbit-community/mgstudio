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
const PI : Float = 3.141592653589793F

///|
const MESH3D_FORWARD_SHADER_PATH : String = "shaders/mesh3d_forward.wgsl"

///|
fn cosf(x : Float) -> Float {
  Float::from_double(@coremath.cos(x.to_double()))
}

///|
fn sinf(x : Float) -> Float {
  Float::from_double(@coremath.sin(x.to_double()))
}

///|
fn atan2f(y : Float, x : Float) -> Float {
  Float::from_double(@coremath.atan2(y.to_double(), x.to_double()))
}

///|
fn quat_to_z_rotation(x : Float, y : Float, z : Float, w : Float) -> Float {
  let siny_cosp = 2.0F * (w * z + x * y)
  let cosy_cosp = 1.0F - 2.0F * (y * y + z * z)
  atan2f(siny_cosp, cosy_cosp)
}

///|
pub(all) suberror GpuBackendError {
  Fatal(String)
} derive(Debug)

///|
fn[T] fatal(message : String) -> T raise GpuBackendError {
  raise GpuBackendError::Fatal(message)
}

///|
const IMAGE_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE : Int = 0

///|
const IMAGE_SAMPLER_ADDRESS_MODE_REPEAT : Int = 1

///|
const IMAGE_SAMPLER_ADDRESS_MODE_MIRROR_REPEAT : Int = 2

///|
const IMAGE_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER : Int = 3

///|
const IMAGE_SAMPLER_FILTER_MODE_NEAREST : Int = 0

///|
const IMAGE_SAMPLER_FILTER_MODE_LINEAR : Int = 1

///|
const IMAGE_SAMPLER_COMPARE_UNDEFINED : Int = -1

///|
const IMAGE_SAMPLER_COMPARE_NEVER : Int = 0

///|
const IMAGE_SAMPLER_COMPARE_LESS : Int = 1

///|
const IMAGE_SAMPLER_COMPARE_EQUAL : Int = 2

///|
const IMAGE_SAMPLER_COMPARE_LESS_EQUAL : Int = 3

///|
const IMAGE_SAMPLER_COMPARE_GREATER : Int = 4

///|
const IMAGE_SAMPLER_COMPARE_NOT_EQUAL : Int = 5

///|
const IMAGE_SAMPLER_COMPARE_GREATER_EQUAL : Int = 6

///|
const IMAGE_SAMPLER_COMPARE_ALWAYS : Int = 7

///|
const IMAGE_SAMPLER_BORDER_COLOR_UNDEFINED : Int = -1

///|
const IMAGE_SAMPLER_BORDER_COLOR_TRANSPARENT_BLACK : Int = 0

///|
const IMAGE_SAMPLER_BORDER_COLOR_OPAQUE_BLACK : Int = 1

///|
const IMAGE_SAMPLER_BORDER_COLOR_OPAQUE_WHITE : Int = 2

///|
const IMAGE_SAMPLER_BORDER_COLOR_ZERO : Int = 3

///|
fn ss(raw : UInt64) -> @wgpu.ShaderStage {
  @wgpu.ShaderStage::from_u64(raw)
}

///|
fn bu(raw : UInt64) -> @wgpu.BufferUsage {
  @wgpu.BufferUsage::from_u64(raw)
}

///|
fn tf(raw : UInt) -> @wgpu.TextureFormat {
  @wgpu.TextureFormat::from_u32(raw)
}

///|
priv struct TextureBlockInfo {
  block_width : Int
  block_height : Int
  block_bytes : Int
}

///|
fn texture_block_info(format_raw : UInt) -> TextureBlockInfo? {
  if format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM ||
    format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB {
    return Some(TextureBlockInfo::{
      block_width: 1,
      block_height: 1,
      block_bytes: 4,
    })
  }
  if format_raw == @wgpu.TEXTURE_FORMAT_RGB9_E5_UFLOAT {
    return Some(TextureBlockInfo::{
      block_width: 1,
      block_height: 1,
      block_bytes: 4,
    })
  }
  if format_raw == @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT {
    return Some(TextureBlockInfo::{
      block_width: 1,
      block_height: 1,
      block_bytes: 8,
    })
  }
  if format_raw == @wgpu.TEXTURE_FORMAT_BC7_RGBA_UNORM ||
    format_raw == @wgpu.TEXTURE_FORMAT_BC7_RGBA_UNORM_SRGB {
    return Some(TextureBlockInfo::{
      block_width: 4,
      block_height: 4,
      block_bytes: 16,
    })
  }
  if format_raw == @wgpu.TEXTURE_FORMAT_ETC2_RGBA8_UNORM ||
    format_raw == @wgpu.TEXTURE_FORMAT_ETC2_RGBA8_UNORM_SRGB {
    return Some(TextureBlockInfo::{
      block_width: 4,
      block_height: 4,
      block_bytes: 16,
    })
  }
  if format_raw == @wgpu.TEXTURE_FORMAT_ETC2_RGB8_UNORM ||
    format_raw == @wgpu.TEXTURE_FORMAT_ETC2_RGB8_UNORM_SRGB ||
    format_raw == @wgpu.TEXTURE_FORMAT_ETC2_RGB8_A1_UNORM ||
    format_raw == @wgpu.TEXTURE_FORMAT_ETC2_RGB8_A1_UNORM_SRGB {
    return Some(TextureBlockInfo::{
      block_width: 4,
      block_height: 4,
      block_bytes: 8,
    })
  }
  if format_raw == @wgpu.TEXTURE_FORMAT_ASTC4X4_UNORM ||
    format_raw == @wgpu.TEXTURE_FORMAT_ASTC4X4_UNORM_SRGB {
    return Some(TextureBlockInfo::{
      block_width: 4,
      block_height: 4,
      block_bytes: 16,
    })
  }
  None
}

///|
fn texture_layout_for_level(
  info : TextureBlockInfo,
  width : Int,
  height : Int,
) -> (Int, Int, Int)? {
  let w = if width <= 0 { 1 } else { width }
  let h = if height <= 0 { 1 } else { height }
  let blocks_w = (w + info.block_width - 1) / info.block_width
  let blocks_h = (h + info.block_height - 1) / info.block_height
  if blocks_w <= 0 || blocks_h <= 0 {
    return None
  }
  let bytes_per_row = blocks_w * info.block_bytes
  if bytes_per_row <= 0 {
    return None
  }
  let total = bytes_per_row * blocks_h
  if total <= 0 {
    return None
  }
  Some((bytes_per_row, blocks_h, total))
}

///|
fn alloc_id(backend : GpuBackend) -> Int {
  let id = backend.next_id
  backend.next_id = id + 1
  id
}

///|
fn texture_view_aspect_for_format(format_raw : UInt) -> UInt {
  if format_raw == @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT {
    @wgpu.TEXTURE_ASPECT_DEPTH_ONLY
  } else {
    @wgpu.TEXTURE_ASPECT_ALL
  }
}

///|
fn f32_bits(x : Float) -> UInt {
  x.reinterpret_as_uint()
}

///|
fn image_sampler_address_mode_wgpu_raw(raw : Int) -> UInt raise GpuBackendError {
  match raw {
    IMAGE_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE => @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE
    IMAGE_SAMPLER_ADDRESS_MODE_REPEAT => @wgpu.ADDRESS_MODE_REPEAT
    IMAGE_SAMPLER_ADDRESS_MODE_MIRROR_REPEAT => @wgpu.ADDRESS_MODE_MIRROR_REPEAT
    IMAGE_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER =>
      fatal(
        "wgpu: ImageAddressMode::ClampToBorder is blocked because Milky2018/wgpu_mbt does not expose ADDRESS_MODE_CLAMP_TO_BORDER or sampler border-color creation",
      )
    _ => fatal("wgpu: unsupported image sampler address mode raw=\{raw}")
  }
}

///|
fn image_sampler_filter_mode_wgpu_raw(raw : Int) -> UInt raise GpuBackendError {
  match raw {
    IMAGE_SAMPLER_FILTER_MODE_NEAREST => @wgpu.FILTER_MODE_NEAREST
    IMAGE_SAMPLER_FILTER_MODE_LINEAR => @wgpu.FILTER_MODE_LINEAR
    _ => fatal("wgpu: unsupported image sampler filter mode raw=\{raw}")
  }
}

///|
fn image_sampler_mipmap_filter_mode_wgpu_raw(
  raw : Int,
) -> UInt raise GpuBackendError {
  match raw {
    IMAGE_SAMPLER_FILTER_MODE_NEAREST => @wgpu.MIPMAP_FILTER_MODE_NEAREST
    IMAGE_SAMPLER_FILTER_MODE_LINEAR => @wgpu.MIPMAP_FILTER_MODE_LINEAR
    _ => fatal("wgpu: unsupported image sampler mipmap filter mode raw=\{raw}")
  }
}

///|
fn image_sampler_compare_function_wgpu_raw(
  raw : Int,
) -> UInt raise GpuBackendError {
  match raw {
    IMAGE_SAMPLER_COMPARE_UNDEFINED => @wgpu.COMPARE_FUNCTION_UNDEFINED
    IMAGE_SAMPLER_COMPARE_NEVER => @wgpu.COMPARE_FUNCTION_NEVER
    IMAGE_SAMPLER_COMPARE_LESS => @wgpu.COMPARE_FUNCTION_LESS
    IMAGE_SAMPLER_COMPARE_EQUAL => @wgpu.COMPARE_FUNCTION_EQUAL
    IMAGE_SAMPLER_COMPARE_LESS_EQUAL => @wgpu.COMPARE_FUNCTION_LESS_EQUAL
    IMAGE_SAMPLER_COMPARE_GREATER => @wgpu.COMPARE_FUNCTION_GREATER
    IMAGE_SAMPLER_COMPARE_NOT_EQUAL => @wgpu.COMPARE_FUNCTION_NOT_EQUAL
    IMAGE_SAMPLER_COMPARE_GREATER_EQUAL => @wgpu.COMPARE_FUNCTION_GREATER_EQUAL
    IMAGE_SAMPLER_COMPARE_ALWAYS => @wgpu.COMPARE_FUNCTION_ALWAYS
    _ => fatal("wgpu: unsupported image sampler compare function raw=\{raw}")
  }
}

///|
fn image_sampler_border_color_validate(raw : Int) -> Unit raise GpuBackendError {
  match raw {
    IMAGE_SAMPLER_BORDER_COLOR_UNDEFINED => ()
    IMAGE_SAMPLER_BORDER_COLOR_TRANSPARENT_BLACK
    | IMAGE_SAMPLER_BORDER_COLOR_OPAQUE_BLACK
    | IMAGE_SAMPLER_BORDER_COLOR_OPAQUE_WHITE
    | IMAGE_SAMPLER_BORDER_COLOR_ZERO =>
      fatal(
        "wgpu: ImageSamplerBorderColor is blocked because Milky2018/wgpu_mbt does not expose sampler border-color creation",
      )
    _ => fatal("wgpu: unsupported image sampler border color raw=\{raw}")
  }
}

///|
fn image_sampler_cache_key(
  address_mode_u : Int,
  address_mode_v : Int,
  address_mode_w : Int,
  mag_filter : Int,
  min_filter : Int,
  mipmap_filter : Int,
  lod_min_clamp : Float,
  lod_max_clamp : Float,
  compare : Int,
  anisotropy_clamp : Int,
  border_color : Int,
) -> String {
  "\{address_mode_u}|\{address_mode_v}|\{address_mode_w}|\{mag_filter}|\{min_filter}|\{mipmap_filter}|\{f32_bits(lod_min_clamp)}|\{f32_bits(lod_max_clamp)}|\{compare}|\{anisotropy_clamp}|\{border_color}"
}

///|
fn gpu_sampler_get_or_create(
  backend : GpuBackend,
  address_mode_u : Int,
  address_mode_v : Int,
  address_mode_w : Int,
  mag_filter : Int,
  min_filter : Int,
  mipmap_filter : Int,
  lod_min_clamp : Float,
  lod_max_clamp : Float,
  compare : Int,
  anisotropy_clamp : Int,
  border_color : Int,
) -> @wgpu.Sampler raise GpuBackendError {
  if anisotropy_clamp < 1 {
    fatal(
      "wgpu: ImageSamplerDescriptor.anisotropy_clamp must be >= 1, got \{anisotropy_clamp}",
    )
  }
  image_sampler_border_color_validate(border_color)
  let key = image_sampler_cache_key(
    address_mode_u, address_mode_v, address_mode_w, mag_filter, min_filter, mipmap_filter,
    lod_min_clamp, lod_max_clamp, compare, anisotropy_clamp, border_color,
  )
  match backend.sampler_cache.get(key) {
    Some(sampler) => sampler
    None => {
      let sampler = backend.device.create_sampler_u32(
        image_sampler_address_mode_wgpu_raw(address_mode_u),
        image_sampler_address_mode_wgpu_raw(address_mode_v),
        image_sampler_address_mode_wgpu_raw(address_mode_w),
        image_sampler_filter_mode_wgpu_raw(mag_filter),
        image_sampler_filter_mode_wgpu_raw(min_filter),
        image_sampler_mipmap_filter_mode_wgpu_raw(mipmap_filter),
        lod_min_clamp_f32=lod_min_clamp,
        lod_max_clamp_f32=lod_max_clamp,
        compare_u32=image_sampler_compare_function_wgpu_raw(compare),
        max_anisotropy_u32=anisotropy_clamp.reinterpret_as_uint(),
      )
      backend.sampler_cache.set(key, sampler)
      sampler
    }
  }
}
