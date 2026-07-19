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
/// Surface configuration and per-frame lifecycle.
///
/// Split from gpu.mbt to keep backend subsystems cohesive and closer to Bevy's module layout.

///|
priv struct SurfaceBinding {
  surface_id : NativeGpuSurface
  window : Int
  target_id : Int
  mut needs_initial_present : Bool
}

///|
priv struct FrameBinding {
  surface_id : NativeGpuSurface
  target_id : Int
  mut needs_present : Bool
}

///|
priv struct WindowSurfaceRuntimeState {
  surfaces : Array[SurfaceBinding]
  mut next_surface_id : Int
  mut frames : Array[FrameBinding]
}

///|
fn window_surface_runtime_state_default() -> WindowSurfaceRuntimeState {
  WindowSurfaceRuntimeState::{ surfaces: [], next_surface_id: 1, frames: [] }
}

///|
let window_surface_runtime_state : WindowSurfaceRuntimeState = window_surface_runtime_state_default()

///|
fn next_surface_id() -> NativeGpuSurface {
  let state = window_surface_runtime_state
  let id = state.next_surface_id
  state.next_surface_id = state.next_surface_id + 1
  id
}

///|
fn surface_target_id_from_surface_id(surface_id : NativeGpuSurface) -> Int {
  -surface_id
}

///|
fn find_surface_binding(surface_id : NativeGpuSurface) -> SurfaceBinding? {
  let state = window_surface_runtime_state
  for binding in state.surfaces {
    if binding.surface_id == surface_id {
      return Some(binding)
    }
  }
  None
}

///|
fn remove_surface_runtime_bindings(surface_id : NativeGpuSurface) -> Unit {
  let state = window_surface_runtime_state
  let next_surfaces : Array[SurfaceBinding] = []
  for binding in state.surfaces {
    if binding.surface_id != surface_id {
      next_surfaces.push(binding)
    }
  }
  state.surfaces.clear()
  for binding in next_surfaces {
    state.surfaces.push(binding)
  }
  let next_frames : Array[FrameBinding] = []
  for binding in state.frames {
    if binding.surface_id != surface_id {
      next_frames.push(binding)
    }
  }
  state.frames.clear()
  for binding in next_frames {
    state.frames.push(binding)
  }
}

///|
fn find_surface_binding_by_window(window : Int) -> SurfaceBinding? {
  let state = window_surface_runtime_state
  for binding in state.surfaces {
    if binding.window == window {
      return Some(binding)
    }
  }
  None
}

///|
fn find_surface_binding_by_target_id(target_id : Int) -> SurfaceBinding? {
  let state = window_surface_runtime_state
  for binding in state.surfaces {
    if binding.target_id == target_id {
      return Some(binding)
    }
  }
  None
}

///|
fn record_active_frame(surface_id : NativeGpuSurface, target_id : Int) -> Unit {
  let state = window_surface_runtime_state
  for binding in state.frames {
    if binding.surface_id == surface_id {
      return
    }
  }
  state.frames.push(FrameBinding::{
    surface_id,
    target_id,
    needs_present: false,
  })
}

///|
fn mark_frame_needs_present_for_target(target_id : Int) -> Unit {
  let state = window_surface_runtime_state
  for binding in state.frames {
    if binding.target_id == target_id {
      binding.needs_present = true
    }
  }
}

///|
fn frame_binding_should_present(binding : FrameBinding) -> Bool {
  let needs_initial_present = match
    find_surface_binding_by_target_id(binding.target_id) {
    Some(surface) => surface.needs_initial_present
    None => false
  }
  frame_binding_should_present_state(
    binding.needs_present,
    needs_initial_present,
  )
}

///|
fn frame_binding_should_present_state(
  needs_present : Bool,
  needs_initial_present : Bool,
) -> Bool {
  if needs_present {
    return true
  }
  needs_initial_present
}

///|
fn mark_surface_initial_present_done(target_id : Int) -> Unit {
  match find_surface_binding_by_target_id(target_id) {
    Some(surface) => surface.needs_initial_present = false
    None => ()
  }
}

///|
fn surface_state_index_by_surface_id(
  backend : GpuBackend,
  surface_id : Int,
) -> Int? {
  for i in 0..<backend.surfaces.length() {
    if backend.surfaces[i].surface_id == surface_id {
      return Some(i)
    }
  }
  None
}

///|
fn surface_state_index_by_target_id(
  backend : GpuBackend,
  target_id : Int,
) -> Int? {
  for i in 0..<backend.surfaces.length() {
    if backend.surfaces[i].target_id == target_id {
      return Some(i)
    }
  }
  None
}

///|
fn default_surface_target_id(backend : GpuBackend) -> Int? {
  if backend.surfaces.length() == 0 {
    None
  } else {
    Some(backend.surfaces[0].target_id)
  }
}

///|
fn surface_present_mode_primary(requested_kind : Int) -> UInt {
  match requested_kind {
    SURFACE_PRESENT_MODE_FIFO => @wgpu.PRESENT_MODE_FIFO
    SURFACE_PRESENT_MODE_FIFO_RELAXED => @wgpu.PRESENT_MODE_FIFO_RELAXED
    SURFACE_PRESENT_MODE_IMMEDIATE => @wgpu.PRESENT_MODE_IMMEDIATE
    SURFACE_PRESENT_MODE_MAILBOX => @wgpu.PRESENT_MODE_MAILBOX
    _ => @wgpu.PRESENT_MODE_FIFO
  }
}

///|
fn surface_present_mode_candidates(requested_kind : Int) -> Array[UInt] {
  let candidates : Array[UInt] = []
  match requested_kind {
    SURFACE_PRESENT_MODE_AUTO_VSYNC => {
      candidates.push(@wgpu.PRESENT_MODE_FIFO_RELAXED)
      candidates.push(@wgpu.PRESENT_MODE_FIFO)
    }
    SURFACE_PRESENT_MODE_AUTO_NO_VSYNC => {
      candidates.push(@wgpu.PRESENT_MODE_IMMEDIATE)
      candidates.push(@wgpu.PRESENT_MODE_MAILBOX)
      candidates.push(@wgpu.PRESENT_MODE_FIFO)
    }
    SURFACE_PRESENT_MODE_MAILBOX => {
      candidates.push(@wgpu.PRESENT_MODE_MAILBOX)
      candidates.push(@wgpu.PRESENT_MODE_IMMEDIATE)
      candidates.push(@wgpu.PRESENT_MODE_FIFO)
    }
    _ => {
      let requested = surface_present_mode_primary(requested_kind)
      candidates.push(requested)
      candidates.push(@wgpu.PRESENT_MODE_FIFO)
    }
  }
  candidates
}

///|
fn surface_present_mode_resolve(
  surface : @wgpu.Surface,
  adapter : @wgpu.Adapter,
  requested_kind : Int,
) -> UInt {
  let supported_modes = surface.capabilities_present_modes(adapter)
  let candidates = surface_present_mode_candidates(requested_kind)
  for candidate in candidates {
    for supported in supported_modes {
      if supported == candidate {
        return candidate
      }
    }
  }
  if supported_modes.length() > 0 {
    return supported_modes[0]
  }
  @wgpu.PRESENT_MODE_FIFO
}

///|
fn surface_alpha_mode_resolve(requested_kind : Int) -> UInt {
  match requested_kind {
    SURFACE_COMPOSITE_ALPHA_MODE_OPAQUE => @wgpu.COMPOSITE_ALPHA_MODE_OPAQUE
    SURFACE_COMPOSITE_ALPHA_MODE_PRE_MULTIPLIED =>
      @wgpu.COMPOSITE_ALPHA_MODE_PREMULTIPLIED
    SURFACE_COMPOSITE_ALPHA_MODE_POST_MULTIPLIED =>
      @wgpu.COMPOSITE_ALPHA_MODE_UNPREMULTIPLIED
    SURFACE_COMPOSITE_ALPHA_MODE_INHERIT => @wgpu.COMPOSITE_ALPHA_MODE_INHERIT
    _ => @wgpu.COMPOSITE_ALPHA_MODE_AUTO
  }
}

///|
fn surface_desired_maximum_frame_latency_resolve(requested : Int) -> UInt {
  if requested >= 1 {
    requested.reinterpret_as_uint()
  } else {
    @wgpu.SURFACE_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY
  }
}

///|
fn surface_preferred_format(
  surface : @wgpu.Surface,
  adapter : @wgpu.Adapter,
) -> @wgpu.TextureFormat {
  let formats = surface.capabilities_formats(adapter)
  if formats.length() == 0 {
    return @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_BGRA8_UNORM)
  }
  let mut preferred = formats[0]
  for available in formats {
    let format_raw = available.to_u32()
    if format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB ||
      format_raw == @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB {
      preferred = available
      break
    }
  }
  preferred
}

///|
fn sync_active_surface_state(backend : GpuBackend) -> Unit {
  guard surface_state_index_by_target_id(
      backend,
      backend.active_surface_target_id,
    )
    is Some(index) else {
    backend.surface = None
    backend.surface_format = None
    backend.configured_width = 0
    backend.configured_height = 0
    backend.surface_cleared_this_frame = false
    return
  }
  let state = backend.surfaces[index]
  backend.surface = Some(state.surface)
  backend.surface_format = state.surface_format
  backend.configured_width = state.configured_width
  backend.configured_height = state.configured_height
  backend.surface_cleared_this_frame = state.cleared_this_frame
}

///|
fn store_active_surface_frame(backend : GpuBackend) -> Unit {
  guard backend.frame is Some(frame) else { return }
  guard surface_state_index_by_target_id(
      backend,
      backend.active_surface_target_id,
    )
    is Some(index) else {
    backend.frame = None
    return
  }
  backend.surfaces[index].frame = Some(frame)
  backend.frame = None
}

///|
fn activate_surface_frame_for_target(
  backend : GpuBackend,
  target_id : Int,
) -> Bool {
  let desired_target_id = if target_id < 0 {
    target_id
  } else if backend.active_surface_target_id < 0 {
    match default_surface_target_id(backend) {
      Some(value) => value
      None => return false
    }
  } else {
    backend.active_surface_target_id
  }
  guard desired_target_id < 0 else { return false }

  if backend.active_surface_target_id != desired_target_id {
    store_active_surface_frame(backend)
    backend.active_surface_target_id = desired_target_id
  }
  if backend.frame is None {
    guard surface_state_index_by_target_id(backend, desired_target_id)
      is Some(index) else {
      return false
    }
    if backend.surfaces[index].frame is None {
      let surface_id = backend.surfaces[index].surface_id
      if backend.begin_frame_binding(surface_id) {
        record_active_frame(surface_id, desired_target_id)
      }
    }
    guard backend.surfaces[index].frame is Some(frame) else { return false }
    backend.surfaces[index].frame = None
    backend.frame = Some(frame)
  }
  sync_active_surface_state(backend)
  true
}

///|
fn set_active_surface_cleared_state(
  backend : GpuBackend,
  cleared : Bool,
) -> Unit {
  backend.surface_cleared_this_frame = cleared
  guard surface_state_index_by_target_id(
      backend,
      backend.active_surface_target_id,
    )
    is Some(index) else {
    return
  }
  backend.surfaces[index].cleared_this_frame = cleared
}

///|
fn surface_target_exists(backend : GpuBackend, target_id : Int) -> Bool {
  surface_state_index_by_target_id(backend, target_id) is Some(_)
}

///|
fn surface_target_format(
  backend : GpuBackend,
  target_id : Int,
) -> @wgpu.TextureFormat? {
  guard surface_state_index_by_target_id(backend, target_id) is Some(index) else {
    return None
  }
  backend.surfaces[index].surface_format
}

///|
fn surface_target_size(backend : GpuBackend, target_id : Int) -> (Int, Int)? {
  guard surface_state_index_by_target_id(backend, target_id) is Some(index) else {
    return None
  }
  let state = backend.surfaces[index]
  Some((state.configured_width, state.configured_height))
}

///|
pub(all) enum SurfaceAcquireResult {
  SurfaceAcquired(@wgpu.SurfaceTexture, @wgpu.Texture)
  SurfaceOutdated
  SurfaceOccluded
  SurfaceAcquireFailed(UInt)
}

///|
fn surface_texture_status_is_success(status : UInt) -> Bool {
  status == @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_SUCCESS_OPTIMAL ||
  status == @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_SUCCESS_SUBOPTIMAL
}

///|
fn surface_texture_status_name(status : UInt) -> String {
  if status == @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_SUCCESS_OPTIMAL {
    "SuccessOptimal"
  } else if status ==
    @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_SUCCESS_SUBOPTIMAL {
    "SuccessSuboptimal"
  } else if status == @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_TIMEOUT {
    "Timeout"
  } else if status == @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_OUTDATED {
    "Outdated"
  } else if status == @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_LOST {
    "Lost"
  } else if status == @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_OCCLUDED {
    "Occluded"
  } else if status == @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_DEVICE_LOST {
    "DeviceLost"
  } else if status == @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_ERROR {
    "Error"
  } else {
    "Unknown"
  }
}

///|
fn GpuBackend::configure_surface_state_resolved(
  self : GpuBackend,
  index : Int,
  width : Int,
  height : Int,
  present_mode_u32 : UInt,
  alpha_mode_u32 : UInt,
  desired_maximum_frame_latency_u32 : UInt,
) -> Unit {
  let state = self.surfaces[index]
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  // Surface textures cannot be used as sampled textures (`texture_binding`).
  // Requesting RESOURCE usage triggers a wgpu-native validation error.
  let usage_bits = @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_COPY_SRC
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  let format = match state.surface_format {
    Some(surface_format) => surface_format
    None => surface_preferred_format(state.surface, self.adapter)
  }
  let configured = state.surface.configure_u32(
    self.adapter,
    self.device,
    w,
    h,
    usage,
    format,
    present_mode_u32,
    alpha_mode_u32,
    desired_maximum_frame_latency=desired_maximum_frame_latency_u32,
  )
  let configured_format = if configured {
    format
  } else {
    state.surface.configure_default(
      self.adapter,
      self.device,
      w,
      h,
      usage,
      desired_maximum_frame_latency=desired_maximum_frame_latency_u32,
    )
  }
  self.surfaces[index].configured_width = width
  self.surfaces[index].configured_height = height
  self.surfaces[index].configured_present_mode = present_mode_u32
  self.surfaces[index].configured_alpha_mode = alpha_mode_u32
  self.surfaces[index].configured_desired_maximum_frame_latency = desired_maximum_frame_latency_u32
  self.surfaces[index].surface_format = Some(configured_format)
  if self.active_surface_target_id >= 0 {
    self.active_surface_target_id = state.target_id
  }
  sync_active_surface_state(self)
}

///|
fn GpuBackend::reconfigure_surface_state_with_existing_config(
  self : GpuBackend,
  index : Int,
) -> Unit {
  let state = self.surfaces[index]
  if state.configured_width <= 0 || state.configured_height <= 0 {
    return
  }
  self.configure_surface_state_resolved(
    index,
    state.configured_width,
    state.configured_height,
    state.configured_present_mode,
    state.configured_alpha_mode,
    state.configured_desired_maximum_frame_latency,
  )
}

///|
fn GpuBackend::acquire_surface_texture_once(
  self : GpuBackend,
  index : Int,
) -> SurfaceAcquireResult {
  let st = self.surfaces[index].surface.get_current_texture()
  let status = st.status()
  if surface_texture_status_is_success(status) {
    let tex = st.take_texture_or_raise() catch {
      err => {
        st.release()
        debug("[renderer] begin_frame: \{err.message()}")
        return SurfaceAcquireFailed(status)
      }
    }
    return SurfaceAcquired(st, tex)
  }
  st.release()
  if status == @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_OUTDATED {
    SurfaceOutdated
  } else if status == @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_OCCLUDED {
    SurfaceOccluded
  } else {
    debug(
      "[renderer] begin_frame: wgpuSurfaceGetCurrentTexture failed (status=\{surface_texture_status_name(status)}, u32=\{status.to_string()})",
    )
    SurfaceAcquireFailed(status)
  }
}

///|
pub fn GpuBackend::set_active_surface_target(
  self : GpuBackend,
  target_id : Int,
) -> Unit {
  if target_id >= 0 {
    return
  }
  if !surface_target_exists(self, target_id) {
    return
  }
  if self.active_surface_target_id == target_id {
    return
  }
  store_active_surface_frame(self)
  self.active_surface_target_id = target_id
  sync_active_surface_state(self)
}

///|
pub fn GpuBackend::create_surface_binding(
  self : GpuBackend,
  surface_id : Int,
  target_id : Int,
  window : Int,
) -> Unit {
  if surface_state_index_by_surface_id(self, surface_id) is Some(_) {
    return
  }
  let window_handle = match @windowing.window_handle(window) {
    Some(handle) => handle
    None => abort("wgpu: failed to get window handle")
  }
  let display_handle = match @windowing.display_handle(window) {
    Some(handle) => handle
    None => abort("wgpu: failed to get display handle")
  }
  let surface = self.instance.create_surface_from_window_handles(
    window_handle, display_handle,
  ) catch {
    err => abort("wgpu: failed to create window surface: \{err.message()}")
  }
  self.surfaces.push(GpuSurfaceState::{
    surface_id,
    target_id,
    surface,
    surface_format: None,
    configured_width: 0,
    configured_height: 0,
    configured_present_mode: @wgpu.PRESENT_MODE_UNDEFINED,
    configured_alpha_mode: @wgpu.COMPOSITE_ALPHA_MODE_AUTO,
    configured_desired_maximum_frame_latency: @wgpu.SURFACE_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY,
    frame: None,
    cleared_this_frame: false,
  })
  if self.active_surface_target_id >= 0 {
    self.active_surface_target_id = target_id
  }
  sync_active_surface_state(self)
}

///|
pub fn GpuBackend::create_surface(self : GpuBackend, window : Int) -> Unit {
  self.create_surface_binding(1, -1, window)
}

///|
fn GpuBackend::release_surface_binding(
  self : GpuBackend,
  surface_id : Int,
) -> Unit {
  guard surface_state_index_by_surface_id(self, surface_id) is Some(index) else {
    return
  }
  let target_id = self.surfaces[index].target_id
  self.release_frame_binding(surface_id)
  let removed = self.surfaces.remove(index)
  removed.release()
  if self.active_surface_target_id == target_id {
    self.active_surface_target_id = match default_surface_target_id(self) {
      Some(next_target_id) => next_target_id
      None => -1
    }
    self.frame = None
    self.pass_state = None
  }
  sync_active_surface_state(self)
}

///|
pub fn GpuBackend::configure_surface_binding(
  self : GpuBackend,
  surface_id : Int,
  width : Int,
  height : Int,
  present_mode_kind : Int,
  composite_alpha_mode_kind : Int,
  desired_maximum_frame_latency : Int,
) -> Unit {
  guard surface_state_index_by_surface_id(self, surface_id) is Some(index) else {
    return
  }
  let state = self.surfaces[index]
  let window = match find_surface_binding(surface_id) {
    Some(binding) => binding.window
    None => abort("wgpu: missing host window for surface \{surface_id}")
  }
  let window_handle = match @windowing.window_handle(window) {
    Some(handle) => handle
    None => abort("wgpu: failed to get window handle for surface \{surface_id}")
  }
  state.surface.sync_macos_window_handle(window_handle) catch {
    err =>
      abort(
        "wgpu: failed to synchronize macOS window surface: \{err.message()}",
      )
  }
  let present_mode_u32 = surface_present_mode_resolve(
    state.surface,
    self.adapter,
    present_mode_kind,
  )
  let alpha_mode_u32 = surface_alpha_mode_resolve(composite_alpha_mode_kind)
  let desired_maximum_frame_latency_u32 = surface_desired_maximum_frame_latency_resolve(
    desired_maximum_frame_latency,
  )
  if width == state.configured_width &&
    height == state.configured_height &&
    present_mode_u32 == state.configured_present_mode &&
    alpha_mode_u32 == state.configured_alpha_mode &&
    desired_maximum_frame_latency_u32 ==
    state.configured_desired_maximum_frame_latency {
    return
  }
  self.configure_surface_state_resolved(
    index, width, height, present_mode_u32, alpha_mode_u32, desired_maximum_frame_latency_u32,
  )
}

///|
pub fn GpuBackend::configure_surface(
  self : GpuBackend,
  width : Int,
  height : Int,
  present_mode_kind? : Int = SURFACE_PRESENT_MODE_AUTO_VSYNC,
  composite_alpha_mode_kind? : Int = SURFACE_COMPOSITE_ALPHA_MODE_AUTO,
  desired_maximum_frame_latency? : Int = SURFACE_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY,
) -> Unit {
  let target_id = match default_surface_target_id(self) {
    Some(v) => v
    None => return
  }
  guard surface_state_index_by_target_id(self, target_id) is Some(index) else {
    return
  }
  self.configure_surface_binding(
    self.surfaces[index].surface_id,
    width,
    height,
    present_mode_kind,
    composite_alpha_mode_kind,
    desired_maximum_frame_latency,
  )
}

///|
pub fn GpuBackend::ensure_surface_configured(
  self : GpuBackend,
  width : Int,
  height : Int,
  present_mode_kind? : Int = SURFACE_PRESENT_MODE_AUTO_VSYNC,
  composite_alpha_mode_kind? : Int = SURFACE_COMPOSITE_ALPHA_MODE_AUTO,
  desired_maximum_frame_latency? : Int = SURFACE_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY,
) -> Unit {
  let target_id = match default_surface_target_id(self) {
    Some(v) => v
    None => return
  }
  guard surface_state_index_by_target_id(self, target_id) is Some(index) else {
    return
  }
  let state = self.surfaces[index]
  let present_mode_u32 = surface_present_mode_resolve(
    state.surface,
    self.adapter,
    present_mode_kind,
  )
  let alpha_mode_u32 = surface_alpha_mode_resolve(composite_alpha_mode_kind)
  let desired_maximum_frame_latency_u32 = surface_desired_maximum_frame_latency_resolve(
    desired_maximum_frame_latency,
  )
  if width == state.configured_width && height == state.configured_height {
    if present_mode_u32 == state.configured_present_mode &&
      alpha_mode_u32 == state.configured_alpha_mode &&
      desired_maximum_frame_latency_u32 ==
      state.configured_desired_maximum_frame_latency {
      return
    }
  }
  self.configure_surface_binding(
    state.surface_id,
    width,
    height,
    present_mode_kind,
    composite_alpha_mode_kind,
    desired_maximum_frame_latency,
  )
}

///|
fn GpuBackend::prepare_render_frame(self : GpuBackend) -> Unit {
  mesh3d_pass_uniform_states_clear(self)
  mesh3d_frame_view_bind_group_cache_clear(self)
  self.mesh3d_motion_vector_view_bg_cache.clear()
  self.mesh3d_prepass_attachments_used.clear()
  if self.frame_count == 4294967295U {
    self.frame_count = 0U
  } else {
    self.frame_count = self.frame_count + 1U
  }
  self.mesh2d_instance_used = 0
  self.sprite_flush_count_this_frame = 0
  mesh2d_reset_pending_batch(self)
  self.mesh3d_draw_slot_used = 0
  self.mesh3d_instance_draw_used = 0
  self.mesh3d_prepared_draw_camera_key_hi = -1
  self.mesh3d_prepared_draw_camera_key_lo = -1
  self.mesh3d_prepared_draw_pass_kind = -1
  self.mesh3d_prepared_draw_count = 0
  self.mesh3d_motion_vector_mesh_slot_used = 0
  self.mesh3d_motion_vector_instance_mesh_used = 0
}

///|
pub fn GpuBackend::begin_frame_binding(
  self : GpuBackend,
  surface_id : Int,
) -> Bool {
  guard surface_state_index_by_surface_id(self, surface_id) is Some(index) else {
    return false
  }
  let target_id = self.surfaces[index].target_id
  self.set_active_surface_target(target_id)
  self.surfaces[index].cleared_this_frame = false
  sync_active_surface_state(self)

  let acquired = match self.acquire_surface_texture_once(index) {
    SurfaceAcquired(st, tex) => Some((st, tex))
    SurfaceOutdated => {
      self.reconfigure_surface_state_with_existing_config(index)
      match self.acquire_surface_texture_once(index) {
        SurfaceAcquired(st, tex) => Some((st, tex))
        SurfaceOccluded => None
        SurfaceOutdated => {
          debug(
            "[renderer] begin_frame: could not get swap chain texture after configuring. Cause: Outdated",
          )
          None
        }
        SurfaceAcquireFailed(status) => {
          debug(
            "[renderer] begin_frame: could not get swap chain texture after configuring. Cause: \{surface_texture_status_name(status)}",
          )
          None
        }
      }
    }
    SurfaceOccluded => None
    SurfaceAcquireFailed(_) => None
  }
  guard acquired is Some((st, tex)) else { return false }
  let view = tex.create_view()
  view.set_label("mgstudio_surface_view")
  let encoder = self.device.create_command_encoder()
  self.surfaces[index].frame = Some(GpuFrameState::{
    surface_tex: st,
    surface_texture: tex,
    surface_view: view,
    present_view: None,
    screenshot_capture_texture: None,
    screenshot_capture_format_raw: 0U,
    encoder,
    pass: None,
    transient_buffers: [],
    transient_bind_groups: [],
    transient_texture_views: [],
  })
  prepare_surface_capture_frame(self)
  true
}

///|
pub fn GpuBackend::begin_frame(self : GpuBackend) -> Unit {
  guard default_surface_target_id(self) is Some(target_id) else { return }
  guard surface_state_index_by_target_id(self, target_id) is Some(index) else {
    return
  }
  ignore(self.begin_frame_binding(self.surfaces[index].surface_id))
}

///|
pub fn GpuBackend::prepare_initial_surface_frames(self : GpuBackend) -> Unit {
  let state = window_surface_runtime_state
  for binding in state.surfaces {
    if !binding.needs_initial_present {
      continue
    }
    guard surface_state_index_by_surface_id(self, binding.surface_id)
      is Some(index) else {
      continue
    }
    let surface_state = self.surfaces[index]
    if surface_state.configured_width <= 0 ||
      surface_state.configured_height <= 0 {
      continue
    }
    if self.begin_frame_binding(binding.surface_id) {
      record_active_frame(binding.surface_id, binding.target_id)
    }
  }
}

///|
fn GpuBackend::prepare_frame_submission_binding(
  self : GpuBackend,
  surface_id : Int,
  pending_command_buffers : PendingCommandBuffers,
) -> Unit raise GpuBackendError {
  guard surface_state_index_by_surface_id(self, surface_id) is Some(index) else {
    return
  }
  let target_id = self.surfaces[index].target_id
  if !activate_surface_frame_for_target(self, target_id) {
    return
  }
  guard self.frame is Some(frame) else { return }
  if frame.pass is Some(pass) {
    flush_mesh2d_batches(self)
    flush_ui_shadow_batches(self)
    flush_ui_slice_batches(self)
    flush_ui_batches(self)
    flush_sprite_batches(self)
    render_pass_timing_end_active_pass()
    pass.end()
    pass.release()
    frame.pass = None
  }
  let command_encoding_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "renderer.command_encoding",
  )
  screenshot_encode_active_surface_captures(self, frame)
  screenshot_present_surface_capture(self)
  screenshot_encode_pending_texture_captures(self, frame)
  let cmd = frame.encoder.finish()
  pending_command_buffers.push_one(cmd)
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "renderer.command_encoding",
    command_encoding_trace_start_us,
  )
}

///|
fn GpuBackend::present_frame_binding(
  self : GpuBackend,
  surface_id : Int,
) -> Unit {
  guard surface_state_index_by_surface_id(self, surface_id) is Some(index) else {
    return
  }
  let target_id = self.surfaces[index].target_id
  if !activate_surface_frame_for_target(self, target_id) {
    return
  }
  guard self.frame is Some(frame) else { return }
  screenshot_collect_completed_captures(self)
  let present_wait_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "renderer.present_wait",
  )
  self.surfaces[index].surface.present() |> ignore
  self.instance.process_events()
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "renderer.present_wait",
    present_wait_trace_start_us,
  )
  for bind_group in frame.transient_bind_groups {
    self.frame_retired_bind_groups.push(bind_group)
  }
  frame.transient_bind_groups.clear()
  for buffer in frame.transient_buffers {
    self.frame_retired_buffers.push(buffer)
  }
  frame.transient_buffers.clear()
  for view in frame.transient_texture_views {
    self.frame_retired_texture_views.push(view)
  }
  frame.transient_texture_views.clear()
  frame.encoder.release()
  if frame.present_view is Some(present_view) {
    present_view.release()
  }
  frame.surface_view.release()
  if frame.screenshot_capture_texture is Some(capture_texture) {
    capture_texture.release()
  }
  frame.surface_texture.release()
  frame.surface_tex.release()
  self.surfaces[index].frame = None
  self.surfaces[index].cleared_this_frame = false
  self.frame = None
  self.pass_state = None
  sync_active_surface_state(self)
  render_diagnostics_end_frame()
}

///|
fn GpuBackend::release_frame_binding(
  self : GpuBackend,
  surface_id : Int,
) -> Unit {
  guard surface_state_index_by_surface_id(self, surface_id) is Some(index) else {
    return
  }
  let target_id = self.surfaces[index].target_id
  if self.active_surface_target_id == target_id {
    store_active_surface_frame(self)
  }
  guard self.surfaces[index].frame is Some(frame) else { return }
  for bind_group in frame.transient_bind_groups {
    self.frame_retired_bind_groups.push(bind_group)
  }
  frame.transient_bind_groups.clear()
  for buffer in frame.transient_buffers {
    self.frame_retired_buffers.push(buffer)
  }
  frame.transient_buffers.clear()
  for view in frame.transient_texture_views {
    self.frame_retired_texture_views.push(view)
  }
  frame.transient_texture_views.clear()
  frame.encoder.release()
  if frame.present_view is Some(present_view) {
    present_view.release()
  }
  frame.surface_view.release()
  if frame.screenshot_capture_texture is Some(capture_texture) {
    capture_texture.release()
  }
  frame.surface_texture.release()
  frame.surface_tex.release()
  self.surfaces[index].frame = None
  self.surfaces[index].cleared_this_frame = false
  if self.active_surface_target_id == target_id {
    self.frame = None
    self.pass_state = None
    sync_active_surface_state(self)
  }
}

///|
pub fn GpuBackend::prepare_active_frame_submissions(
  self : GpuBackend,
  pending_command_buffers : PendingCommandBuffers,
) -> Unit raise GpuBackendError {
  let state = window_surface_runtime_state
  for binding in state.frames {
    self.prepare_frame_submission_binding(
      binding.surface_id,
      pending_command_buffers,
    )
  }
}

///|
pub fn GpuBackend::present_active_frames(self : GpuBackend) -> Unit {
  let state = window_surface_runtime_state
  let frames = state.frames
  state.frames = []
  for binding in frames {
    if frame_binding_should_present(binding) {
      self.present_frame_binding(binding.surface_id)
      mark_surface_initial_present_done(binding.target_id)
    } else {
      self.release_frame_binding(binding.surface_id)
    }
  }
}

///|
pub fn GpuBackend::release_frame_retired_resources(self : GpuBackend) -> Unit {
  for bind_group in self.frame_retired_bind_groups {
    bind_group.release()
  }
  self.frame_retired_bind_groups.clear()
  for buffer in self.frame_retired_buffers {
    buffer.release()
  }
  self.frame_retired_buffers.clear()
  for view in self.frame_retired_texture_views {
    view.release()
  }
  self.frame_retired_texture_views.clear()
}

///|
pub fn release_frame_retired_resources() -> Unit {
  guard ensure_backend() is Some(backend) else { return }
  backend.release_frame_retired_resources()
}

///|
pub fn create_surface(window : Int) -> NativeGpuSurface {
  let surface_id = next_surface_id()
  let target_id = surface_target_id_from_surface_id(surface_id)
  let state = window_surface_runtime_state
  state.surfaces.push(SurfaceBinding::{
    surface_id,
    window,
    target_id,
    needs_initial_present: true,
  })
  if ensure_backend() is Some(backend) {
    backend.create_surface_binding(surface_id, target_id, window)
  }
  surface_id
}

///|
pub fn release_surface(surface : NativeGpuSurface) -> Unit {
  if surface <= 0 {
    return
  }
  if render_context_runtime_state.backend is Some(backend) {
    backend.release_surface_binding(surface)
  }
  remove_surface_runtime_bindings(surface)
}

///|
pub fn surface_target_id(surface : NativeGpuSurface) -> Int {
  match find_surface_binding(surface) {
    Some(binding) => binding.target_id
    None => 0
  }
}

///|
pub fn surface_target_id_for_window(window : Int) -> Int {
  match find_surface_binding_by_window(window) {
    Some(binding) => binding.target_id
    None => 0
  }
}

///|
pub fn set_active_surface_target(target_id : Int) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.set_active_surface_target(target_id)
  }
}

///|
pub fn configure_surface(
  device~ : NativeGpuDevice,
  surface~ : NativeGpuSurface,
  width~ : Int,
  height~ : Int,
  present_mode_kind? : Int = SURFACE_PRESENT_MODE_AUTO_VSYNC,
  composite_alpha_mode_kind? : Int = SURFACE_COMPOSITE_ALPHA_MODE_AUTO,
  desired_maximum_frame_latency? : Int = SURFACE_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY,
) -> Unit {
  device |> ignore
  if surface <= 0 {
    return
  }
  if ensure_backend() is Some(backend) {
    backend.configure_surface_binding(
      surface, width, height, present_mode_kind, composite_alpha_mode_kind, desired_maximum_frame_latency,
    )
  }
}

///|
pub fn begin_frame(surface : NativeGpuSurface) -> Bool {
  if surface <= 0 {
    return false
  }
  prepare_render_frame()
  if ensure_backend() is Some(backend) {
    guard backend.begin_frame_binding(surface) else { return false }
    record_active_frame(surface, surface_target_id_from_surface_id(surface))
    return true
  }
  false
}

///|
fn prepare_render_frame() -> Unit {
  render_diagnostics_begin_frame()
  if ensure_backend() is Some(backend) {
    backend.prepare_render_frame()
  }
}

///|
pub fn prepare_initial_surface_frames() -> Unit {
  // Bevy's `prepare_windows` starts the logical render frame before the render
  // graph runs. Host surface acquisition can remain lazy after the initial
  // present, but frame-local GPU allocators must still reset at this boundary.
  prepare_render_frame()
  if ensure_backend() is Some(backend) {
    backend.prepare_initial_surface_frames()
  }
}

///|
pub fn prepare_active_frame_submissions(
  pending_command_buffers : PendingCommandBuffers,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_active_frame_submissions(pending_command_buffers) catch {
      err => debug_runtime_error("prepare_active_frame_submissions", err)
    }
  }
}

///|
pub fn present_active_frames() -> Unit {
  if ensure_backend() is Some(backend) {
    backend.present_active_frames()
  }
}
