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
priv struct PendingSurfaceScreenshotCapture {
  id : Int
  target_id : Int
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
pub struct ScreenshotTextureRef {
  id : Int
  width : Int
  height : Int
}

///|
const PARITY_CAPTURE_OUTPUT_ENV : String = "MGSTUDIO_PARITY_CAPTURE_RGBA8_BLOB"

///|
const PARITY_CAPTURE_DELAY_ENV : String = "MGSTUDIO_PARITY_CAPTURE_DELAY_FRAMES"

///|
const PARITY_CAPTURE_DEFAULT_DELAY_FRAMES : Int = 120

///|
fn screenshot_debug_enabled() -> Bool {
  match @sys.get_env_var("MGSTUDIO_SCREENSHOT_DEBUG") {
    Some(flag) => flag.trim().to_string() == "1"
    _ => false
  }
}

///|
fn screenshot_debug_log(message : String) -> Unit {
  if screenshot_debug_enabled() {
    println("[screenshot] " + message)
  }
}

///|
fn screenshot_env_trimmed(key : String) -> String? {
  match @sys.get_env_var(key) {
    Some(raw) => {
      let trimmed = raw.trim().to_string()
      if trimmed == "" {
        None
      } else {
        Some(trimmed)
      }
    }
    _ => None
  }
}

///|
fn parity_capture_delay_frames_from_env() -> Int {
  match screenshot_env_trimmed(PARITY_CAPTURE_DELAY_ENV) {
    Some(raw) => {
      let parsed = @strconv.parse_int(raw[:], base=10) catch {
        _ => PARITY_CAPTURE_DEFAULT_DELAY_FRAMES
      }
      if parsed < 0 {
        0
      } else {
        parsed
      }
    }
    _ => PARITY_CAPTURE_DEFAULT_DELAY_FRAMES
  }
}

///|
fn parity_capture_load_config() -> Unit {
  if parity_capture_config_loaded_ref.val {
    return
  }
  parity_capture_config_loaded_ref.val = true
  parity_capture_delay_frames_ref.val = parity_capture_delay_frames_from_env()
  parity_capture_blob_path_ref.val = screenshot_env_trimmed(
    PARITY_CAPTURE_OUTPUT_ENV,
  )
  if parity_capture_blob_path_ref.val is Some(path) {
    screenshot_debug_log(
      "parity capture enabled path=\{path}, delay_frames=\{parity_capture_delay_frames_ref.val}",
    )
  }
}

///|
fn parity_capture_push_u32_le(out : Array[Byte], value : UInt) -> Unit {
  out.push((value & 0xFFU).to_byte())
  out.push(((value >> 8) & 0xFFU).to_byte())
  out.push(((value >> 16) & 0xFFU).to_byte())
  out.push(((value >> 24) & 0xFFU).to_byte())
}

///|
fn parity_capture_ensure_parent_dir(path : String) -> Unit {
  let path_value : @path.Path = path
  let parent = path_value.dirname().to_string()
  if parent == "" || parent == "." || parent == path {
    return
  }
  if @fs.path_exists(parent) {
    return
  }
  parity_capture_ensure_parent_dir(parent)
  @fs.create_dir(parent) catch {
    _ => ()
  }
}

///|
fn parity_capture_write_blob(
  path : String,
  capture : ScreenshotCaptureResult,
) -> Bool {
  if capture.width <= 0 || capture.height <= 0 {
    return false
  }
  if capture.pixels.length() != capture.width * capture.height * 4 {
    return false
  }
  let out : Array[Byte] = []
  parity_capture_push_u32_le(out, capture.width.reinterpret_as_uint())
  parity_capture_push_u32_le(out, capture.height.reinterpret_as_uint())
  for i in 0..<capture.pixels.length() {
    out.push(capture.pixels[i])
  }
  parity_capture_ensure_parent_dir(path)
  let mut write_ok = true
  @fs.write_bytes_to_file(path, Bytes::from_array(out)) catch {
    _ => write_ok = false
  }
  write_ok
}

///|
fn parity_capture_maybe_request_surface_capture() -> Unit {
  parity_capture_load_config()
  guard parity_capture_blob_path_ref.val is Some(_) else { return }
  if parity_capture_written_ref.val || parity_capture_request_id_ref.val > 0 {
    return
  }
  if parity_capture_seen_frames_ref.val < parity_capture_delay_frames_ref.val {
    parity_capture_seen_frames_ref.val = parity_capture_seen_frames_ref.val + 1
    return
  }
  let capture_id = next_screenshot_capture_id()
  pending_surface_screenshot_captures_ref.val.push(PendingSurfaceScreenshotCapture::{
    id: capture_id,
    target_id: 0,
  })
  parity_capture_request_id_ref.val = capture_id
  screenshot_debug_log(
    "request parity surface capture id=\{capture_id}, delay_frames=\{parity_capture_delay_frames_ref.val}",
  )
}

///|
fn parity_capture_try_write_completed_capture(
  capture : ScreenshotCaptureResult,
) -> Unit {
  if parity_capture_request_id_ref.val <= 0 ||
    capture.id != parity_capture_request_id_ref.val {
    return
  }
  parity_capture_request_id_ref.val = 0
  guard parity_capture_blob_path_ref.val is Some(path) else { return }
  if parity_capture_write_blob(path, capture) {
    parity_capture_written_ref.val = true
    screenshot_debug_log(
      "wrote parity capture blob id=\{capture.id}, size=\{capture.width}x\{capture.height}, path=\{path}",
    )
  } else {
    screenshot_debug_log(
      "failed parity capture blob id=\{capture.id}, path=\{path}",
    )
  }
}

///|
fn prepare_surface_capture_frame(backend : GpuBackend) -> Unit {
  if backend.surface_capture_active {
    return
  }
  if active_surface_screenshot_capture_ids_ref.val.length() > 0 {
    backend.surface_capture_active = true
    return
  }
  parity_capture_maybe_request_surface_capture()
  if pending_surface_screenshot_captures_ref.val.length() == 0 {
    return
  }
  guard backend.surface_format is Some(_) else { return }
  if backend.configured_width <= 0 || backend.configured_height <= 0 {
    return
  }
  let captures_for_target : Array[Int] = []
  let remaining_captures : Array[PendingSurfaceScreenshotCapture] = []
  for pending_capture in pending_surface_screenshot_captures_ref.val {
    if pending_capture.target_id <= 0 ||
      pending_capture.target_id == backend.active_surface_target_id {
      captures_for_target.push(pending_capture.id)
    } else {
      remaining_captures.push(pending_capture)
    }
  }
  if captures_for_target.length() == 0 {
    return
  }
  active_surface_screenshot_capture_ids_ref.val = captures_for_target
  pending_surface_screenshot_captures_ref.val = remaining_captures
  active_surface_screenshot_capture_target_id_ref.val = backend.active_surface_target_id
  backend.surface_capture_active = true
  screenshot_debug_log(
    "activate surface capture target=\{backend.active_surface_target_id}, ids=\{captures_for_target.length()}",
  )
}

///|
let next_screenshot_capture_id_ref : Ref[Int] = Ref::new(1)

///|
let pending_screenshot_captures_ref : Ref[Array[PendingScreenshotCapture]] = Ref::new([],
)

///|
let pending_surface_screenshot_captures_ref : Ref[
  Array[PendingSurfaceScreenshotCapture],
] = Ref::new([])

///|
let active_surface_screenshot_capture_ids_ref : Ref[Array[Int]] = Ref::new([])

///|
let active_surface_screenshot_capture_target_id_ref : Ref[Int] = Ref::new(0)

///|
let inflight_screenshot_captures_ref : Ref[Array[InflightScreenshotCapture]] = Ref::new([],
)

///|
let completed_screenshot_captures_ref : Ref[Array[ScreenshotCaptureResult]] = Ref::new([],
)

///|
let parity_capture_config_loaded_ref : Ref[Bool] = Ref::new(false)

///|
let parity_capture_blob_path_ref : Ref[String?] = Ref::new(None)

///|
let parity_capture_delay_frames_ref : Ref[Int] = Ref::new(0)

///|
let parity_capture_seen_frames_ref : Ref[Int] = Ref::new(0)

///|
let parity_capture_request_id_ref : Ref[Int] = Ref::new(0)

///|
let parity_capture_written_ref : Ref[Bool] = Ref::new(false)

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
  if active_surface_screenshot_capture_target_id_ref.val !=
    backend.active_surface_target_id {
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
  guard screenshot_capture_bytes_per_pixel(surface_format.raw) is Some(_) else {
    screenshot_debug_log(
      "skip surface capture: unsupported format=\{surface_format.raw.reinterpret_as_int()}",
    )
    return
  }
  let active_capture_ids = active_surface_screenshot_capture_ids_ref.val
  active_surface_screenshot_capture_ids_ref.val = []
  for capture_id in active_capture_ids {
    screenshot_debug_log(
      "enqueue surface capture id=\{capture_id}, size=\{width}x\{height}, format=\{surface_format.raw.reinterpret_as_int()}",
    )
    screenshot_enqueue_copy_to_buffer(
      backend,
      frame,
      capture_id,
      frame.surface_texture,
      width,
      height,
      surface_format.raw,
    )
  }
}

///|
fn screenshot_present_surface_capture(backend : GpuBackend) -> Unit {
  if !backend.surface_capture_active {
    return
  }
  if active_surface_screenshot_capture_target_id_ref.val !=
    backend.active_surface_target_id {
    return
  }
  backend.surface_capture_active = false
  active_surface_screenshot_capture_ids_ref.val.clear()
  active_surface_screenshot_capture_target_id_ref.val = 0
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
      let completed = ScreenshotCaptureResult::{
        id: capture.id,
        width: capture.width,
        height: capture.height,
        pixels,
      }
      completed_screenshot_captures_ref.val.push(completed)
      parity_capture_try_write_completed_capture(completed)
      screenshot_debug_log(
        "complete capture id=\{capture.id}, size=\{capture.width}x\{capture.height}",
      )
    } else {
      screenshot_debug_log(
        "drop capture id=\{capture.id}: decode failed format=\{capture.format_raw.reinterpret_as_int()}, byte_len=\{bytes.length()}",
      )
    }
  }
}

///|
pub fn screenshot_capture_surface_request() -> Int {
  guard ensure_backend() is Some(_) else { return 0 }
  let capture_id = next_screenshot_capture_id()
  pending_surface_screenshot_captures_ref.val.push(PendingSurfaceScreenshotCapture::{
    id: capture_id,
    target_id: 0,
  })
  screenshot_debug_log("request surface capture id=\{capture_id}, target=0")
  capture_id
}

///|
pub fn screenshot_capture_surface_target_request(target_id~ : Int) -> Int {
  guard target_id > 0 else { return 0 }
  guard ensure_backend() is Some(_) else { return 0 }
  let capture_id = next_screenshot_capture_id()
  pending_surface_screenshot_captures_ref.val.push(PendingSurfaceScreenshotCapture::{
    id: capture_id,
    target_id,
  })
  screenshot_debug_log(
    "request surface capture id=\{capture_id}, target=\{target_id}",
  )
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
      screenshot_debug_log("take capture id=\{capture_id}: hit")
      return Some(capture)
    }
  }
  screenshot_debug_log("take capture id=\{capture_id}: miss")
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

///|
pub fn screenshot_resource_id_upper_bound() -> Int {
  guard ensure_backend() is Some(backend) else { return 0 }
  backend.next_id - 1
}

///|
pub fn screenshot_texture_refs() -> Array[ScreenshotTextureRef] {
  guard ensure_backend() is Some(backend) else { return [] }
  let refs : Array[ScreenshotTextureRef] = []
  for texture in backend.textures {
    refs.push(ScreenshotTextureRef::{
      id: texture.id,
      width: texture.width,
      height: texture.height,
    })
  }
  refs
}
