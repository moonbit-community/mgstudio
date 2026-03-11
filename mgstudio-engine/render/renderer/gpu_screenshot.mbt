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
/// Screenshot capture and readback utilities split from gpu.mbt for module boundary alignment.
priv struct PendingScreenshotCapture {
  id : Int
  width : Int
  height : Int
  format_raw : UInt
  texture : @wgpu.Texture
}

///|
priv struct InflightScreenshotCapture {
  id : Int
  width : Int
  height : Int
  format_raw : UInt
  buffer : @wgpu.Buffer
  byte_len : UInt64
}

///|
pub struct ScreenshotCaptureResult {
  id : Int
  width : Int
  height : Int
  pixels : Bytes
}

///|
fn ensure_surface_capture_texture(
  backend : GpuBackend,
  width : Int,
  height : Int,
  format_raw : UInt,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(backend)
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  if backend.surface_capture_texture_id >= 0 {
    if find_texture(backend, backend.surface_capture_texture_id)
      is Some(existing) {
      if existing.width == safe_width &&
        existing.height == safe_height &&
        existing.format_raw == format_raw {
        return existing.id
      }
    }
  }
  let texture_id = if backend.surface_capture_texture_id >= 0 {
    backend.surface_capture_texture_id
  } else {
    let allocated_id = alloc_id(backend)
    backend.surface_capture_texture_id = allocated_id
    allocated_id
  }
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_SRC |
    @wgpu.TEXTURE_USAGE_COPY_DST,
  )
  let texture = backend.device.create_texture_u32(
    safe_width.reinterpret_as_uint(),
    safe_height.reinterpret_as_uint(),
    1U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(format_raw),
  )
  let view = texture.create_view()
  let sampler = backend.device.create_sampler_linear_clamp()
  let bind_group = backend.device.create_bind_group_sampler_texture_2d(
    backend.sprite_bgl_tex.unwrap(),
    sampler,
    view,
  )
  replace_texture_info(backend, GpuTextureInfo::{
    id: texture_id,
    width: safe_width,
    height: safe_height,
    mip_level_count: 1,
    base_mip_level: 0,
    format_raw,
    texture,
    view,
    sample_view: None,
    layer_views: [],
    sampler,
    bind_group,
  })
  mesh3d_material_cache_clear(backend)
  texture_id
}

///|
fn surface_capture_texture_info(backend : GpuBackend) -> GpuTextureInfo? {
  if backend.surface_capture_texture_id < 0 {
    None
  } else {
    find_texture(backend, backend.surface_capture_texture_id)
  }
}

///|
fn prepare_surface_capture_frame(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  backend.surface_capture_active = false
  active_surface_screenshot_capture_ids_ref.val.clear()
  if pending_surface_screenshot_capture_ids_ref.val.length() == 0 {
    return
  }
  guard backend.surface_format is Some(surface_format) else { return }
  let width = if backend.configured_width <= 0 {
    1
  } else {
    backend.configured_width
  }
  let height = if backend.configured_height <= 0 {
    1
  } else {
    backend.configured_height
  }
  if ensure_surface_capture_texture(backend, width, height, surface_format.raw) <=
    0 {
    return
  }
  active_surface_screenshot_capture_ids_ref.val = pending_surface_screenshot_capture_ids_ref.val
  pending_surface_screenshot_capture_ids_ref.val = []
  backend.surface_capture_active = true
}

///|
let next_screenshot_capture_id_ref : Ref[Int] = Ref::new(1)

///|
let pending_screenshot_captures_ref : Ref[Array[PendingScreenshotCapture]] = Ref::new([],
)

///|
let pending_surface_screenshot_capture_ids_ref : Ref[Array[Int]] = Ref::new([])

///|
let active_surface_screenshot_capture_ids_ref : Ref[Array[Int]] = Ref::new([])

///|
let inflight_screenshot_captures_ref : Ref[Array[InflightScreenshotCapture]] = Ref::new([],
)

///|
let completed_screenshot_captures_ref : Ref[Array[ScreenshotCaptureResult]] = Ref::new([],
)

///|
fn next_screenshot_capture_id() -> Int {
  let id = next_screenshot_capture_id_ref.val
  next_screenshot_capture_id_ref.val = next_screenshot_capture_id_ref.val + 1
  id
}

///|
fn screenshot_capture_bytes_per_pixel(format_raw : UInt) -> Int? {
  if format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM ||
    format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB ||
    format_raw == @wgpu.TEXTURE_FORMAT_BGRA8_UNORM ||
    format_raw == @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB {
    return Some(4)
  }
  None
}

///|
fn screenshot_capture_row_bytes(width : Int, bytes_per_pixel : Int) -> Int {
  let unpadded = width * bytes_per_pixel
  let remainder = unpadded % 256
  if remainder == 0 {
    unpadded
  } else {
    unpadded + (256 - remainder)
  }
}

///|
fn screenshot_capture_pixels_rgba8(
  format_raw : UInt,
  width : Int,
  height : Int,
  bytes : Bytes,
) -> Bytes? {
  let compact_len = width * height * 4
  let row_bytes = screenshot_capture_row_bytes(width, 4)
  let expected_len = row_bytes * height
  if bytes.length() != compact_len && bytes.length() != expected_len {
    return None
  }
  if bytes.length() == compact_len &&
    (
      format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM ||
      format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB
    ) {
    return Some(bytes)
  }
  if format_raw != @wgpu.TEXTURE_FORMAT_BGRA8_UNORM &&
    format_raw != @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB &&
    format_raw != @wgpu.TEXTURE_FORMAT_RGBA8_UNORM &&
    format_raw != @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB {
    return None
  }
  let out : Array[Byte] = []
  for y in 0..<height {
    let row_start = y * row_bytes
    for x in 0..<width {
      let base = row_start + x * 4
      if format_raw == @wgpu.TEXTURE_FORMAT_BGRA8_UNORM ||
        format_raw == @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB {
        out.push(bytes[base + 2])
        out.push(bytes[base + 1])
        out.push(bytes[base])
        out.push(bytes[base + 3])
      } else {
        out.push(bytes[base])
        out.push(bytes[base + 1])
        out.push(bytes[base + 2])
        out.push(bytes[base + 3])
      }
    }
  }
  Some(Bytes::from_array(out))
}

///|
fn screenshot_enqueue_texture_capture(
  backend : GpuBackend,
  texture : @wgpu.Texture,
  width : Int,
  height : Int,
  format_raw : UInt,
) -> Int {
  guard screenshot_capture_bytes_per_pixel(format_raw) is Some(_) else {
    return 0
  }
  guard backend.frame is Some(_) else { return 0 }
  let capture_id = next_screenshot_capture_id()
  pending_screenshot_captures_ref.val.push(PendingScreenshotCapture::{
    id: capture_id,
    width,
    height,
    format_raw,
    texture,
  })
  capture_id
}

///|
fn screenshot_read_texture_sync(
  backend : GpuBackend,
  texture : @wgpu.Texture,
  width : Int,
  height : Int,
  format_raw : UInt,
) -> ScreenshotCaptureResult? {
  guard screenshot_capture_bytes_per_pixel(format_raw) is Some(bytes_per_pixel) else {
    return None
  }
  let byte_len = (screenshot_capture_row_bytes(width, bytes_per_pixel) * height).to_uint64()
  let usage = @wgpu.BufferUsage::from_u64(
    @wgpu.BUFFER_USAGE_MAP_READ | @wgpu.BUFFER_USAGE_COPY_DST,
  )
  let buffer = backend.device.create_buffer(size=byte_len, usage~)
  let encoder = backend.device.create_command_encoder()
  encoder.copy_texture_to_buffer_bytes_per_pixel(
    texture,
    buffer,
    width.reinterpret_as_uint(),
    height.reinterpret_as_uint(),
    bytes_per_pixel.reinterpret_as_uint(),
  )
  let cmd = encoder.finish()
  backend.queue.submit_one(cmd)
  let bytes = buffer.readback(backend.instance, 0UL, byte_len)
  guard screenshot_capture_pixels_rgba8(format_raw, width, height, bytes)
    is Some(pixels) else {
    buffer.release()
    cmd.release()
    encoder.release()
    return None
  }
  buffer.release()
  cmd.release()
  encoder.release()
  Some(ScreenshotCaptureResult::{ id: 0, width, height, pixels })
}

///|
fn screenshot_enqueue_copy_to_buffer(
  backend : GpuBackend,
  frame : GpuFrameState,
  capture_id : Int,
  texture : @wgpu.Texture,
  width : Int,
  height : Int,
  format_raw : UInt,
) -> Unit {
  guard screenshot_capture_bytes_per_pixel(format_raw) is Some(bytes_per_pixel) else {
    return
  }
  let byte_len = (screenshot_capture_row_bytes(width, bytes_per_pixel) * height).to_uint64()
  let usage = @wgpu.BufferUsage::from_u64(
    @wgpu.BUFFER_USAGE_MAP_READ | @wgpu.BUFFER_USAGE_COPY_DST,
  )
  let buffer = backend.device.create_buffer(size=byte_len, usage~)
  frame.encoder.copy_texture_to_buffer_bytes_per_pixel(
    texture,
    buffer,
    width.reinterpret_as_uint(),
    height.reinterpret_as_uint(),
    bytes_per_pixel.reinterpret_as_uint(),
  )
  inflight_screenshot_captures_ref.val.push(InflightScreenshotCapture::{
    id: capture_id,
    width,
    height,
    format_raw,
    buffer,
    byte_len,
  })
}

///|
fn screenshot_encode_pending_texture_captures(
  backend : GpuBackend,
  frame : GpuFrameState,
) -> Unit {
  let pending = pending_screenshot_captures_ref.val
  pending_screenshot_captures_ref.val = []
  for capture in pending {
    screenshot_enqueue_copy_to_buffer(
      backend,
      frame,
      capture.id,
      capture.texture,
      capture.width,
      capture.height,
      capture.format_raw,
    )
  }
}

///|
fn screenshot_encode_active_surface_captures(
  backend : GpuBackend,
  frame : GpuFrameState,
) -> Unit {
  if !backend.surface_capture_active {
    return
  }
  guard surface_capture_texture_info(backend) is Some(surface_capture_texture) else {
    return
  }
  let active_capture_ids = active_surface_screenshot_capture_ids_ref.val
  active_surface_screenshot_capture_ids_ref.val = []
  for capture_id in active_capture_ids {
    screenshot_enqueue_copy_to_buffer(
      backend,
      frame,
      capture_id,
      surface_capture_texture.texture,
      surface_capture_texture.width,
      surface_capture_texture.height,
      surface_capture_texture.format_raw,
    )
  }
}

///|
fn screenshot_present_surface_capture(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if !backend.surface_capture_active {
    return
  }
  guard surface_capture_texture_info(backend) is Some(surface_capture_texture) else {
    backend.surface_capture_active = false
    return
  }
  let width = if backend.configured_width <= 0 {
    1
  } else {
    backend.configured_width
  }
  let height = if backend.configured_height <= 0 {
    1
  } else {
    backend.configured_height
  }
  backend.surface_capture_active = false
  backend.begin_pass(
    -1, width, height, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0, 0, width,
    height, 0.0F, 1.0F, 1,
  )
  backend.draw_sprite_uv(
    surface_capture_texture.id,
    0.0F,
    0.0F,
    0.0F,
    Float::from_double(width.to_double()) / 128.0F,
    Float::from_double(height.to_double()) / 128.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
  )
  backend.end_pass()
}

///|
fn screenshot_collect_completed_captures(backend : GpuBackend) -> Unit {
  let inflight = inflight_screenshot_captures_ref.val
  inflight_screenshot_captures_ref.val = []
  for capture in inflight {
    let bytes = capture.buffer.readback(backend.instance, 0UL, capture.byte_len)
    capture.buffer.release()
    if screenshot_capture_pixels_rgba8(
        capture.format_raw,
        capture.width,
        capture.height,
        bytes,
      )
      is Some(pixels) {
      completed_screenshot_captures_ref.val.push(ScreenshotCaptureResult::{
        id: capture.id,
        width: capture.width,
        height: capture.height,
        pixels,
      })
    }
  }
}

///|
pub fn screenshot_capture_surface_request() -> Int {
  guard ensure_backend() is Some(_) else { return 0 }
  let capture_id = next_screenshot_capture_id()
  pending_surface_screenshot_capture_ids_ref.val.push(capture_id)
  capture_id
}

///|
pub fn screenshot_capture_texture_request(texture_id~ : Int) -> Int {
  guard ensure_backend() is Some(backend) else { return 0 }
  guard find_texture(backend, texture_id) is Some(texture) else { return 0 }
  screenshot_enqueue_texture_capture(
    backend,
    texture.texture,
    texture.width,
    texture.height,
    texture.format_raw,
  )
}

///|
pub fn screenshot_take_capture_result(
  capture_id : Int,
) -> ScreenshotCaptureResult? {
  for i in 0..<completed_screenshot_captures_ref.val.length() {
    let capture = completed_screenshot_captures_ref.val[i]
    if capture.id == capture_id {
      completed_screenshot_captures_ref.val.remove(i) |> ignore
      return Some(capture)
    }
  }
  None
}

///|
pub fn screenshot_capture_texture_sync(
  texture_id~ : Int,
) -> ScreenshotCaptureResult? {
  guard ensure_backend() is Some(backend) else { return None }
  guard find_texture(backend, texture_id) is Some(texture) else { return None }
  screenshot_read_texture_sync(
    backend,
    texture.texture,
    texture.width,
    texture.height,
    texture.format_raw,
  )
}
