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
pub fn GpuBackend::create_surface(self : GpuBackend, window : Int) -> Unit {
  if self.surface is Some(_) {
    return
  }
  let surface = self.instance.create_surface_metal_layer()
  @windowing.attach_surface_metal_layer(window, surface)
  self.surface = Some(surface)
}

///|
pub fn GpuBackend::configure_surface(
  self : GpuBackend,
  width : Int,
  height : Int,
) -> Unit {
  guard self.surface is Some(surface) else { return }
  self.configured_width = width
  self.configured_height = height
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  // Surface textures cannot be used as sampled textures (`texture_binding`).
  // Requesting RESOURCE usage triggers a wgpu-native validation error.
  let usage_bits = @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_COPY_SRC
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  self.surface_format = Some(
    surface.configure_default(self.adapter, self.device, w, h, usage),
  )
  let fmt_u32 = match self.surface_format {
    Some(f) => f.to_u32()
    None => 0U
  }
  @debug.debug("wgpu: surface_format_u32=" + fmt_u32.to_string())
}

///|
/// Ensure the surface is configured for the latest window size.
///
/// This is a bring-up convenience: the guest does not yet have a resize event
/// path, so the host keeps the surface in sync.
pub fn GpuBackend::ensure_surface_configured(
  self : GpuBackend,
  width : Int,
  height : Int,
) -> Unit {
  if self.surface is None {
    return
  }
  if width == self.configured_width && height == self.configured_height {
    return
  }
  self.configure_surface(width, height)
}

///|
pub fn GpuBackend::begin_frame(self : GpuBackend) -> Unit {
  guard self.surface is Some(surface) else { return }
  if self.frame_count == 4294967295U {
    self.frame_count = 0U
  } else {
    self.frame_count = self.frame_count + 1U
  }
  self.mesh_uniform_slot_used = 0
  self.mesh3d_uniform_slot_used = 0
  let st = surface.get_current_texture()
  let tex = st.take_texture()
  let view = tex.create_view()
  view.set_label("mgstudio_surface_view")
  let encoder = self.device.create_command_encoder()
  self.frame = Some(GpuFrameState::{
    surface_tex: st,
    surface_texture: tex,
    surface_view: view,
    encoder,
    pass: None,
  })
  prepare_surface_capture_frame(self) catch {
    _ => {
      self.surface_capture_active = false
      active_surface_screenshot_capture_ids_ref.val.clear()
    }
  }
}

///|
pub fn GpuBackend::end_frame(self : GpuBackend) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  if frame.pass is Some(pass) {
    flush_ui_shadow_batches(self)
    flush_ui_slice_batches(self)
    flush_ui_batches(self)
    flush_sprite_batches(self)
    pass.end()
    pass.release()
    frame.pass = None
  }
  screenshot_encode_active_surface_captures(self, frame)
  screenshot_present_surface_capture(self)
  screenshot_encode_pending_texture_captures(self, frame)
  let cmd = frame.encoder.finish()
  self.queue.submit_one(cmd)
  screenshot_collect_completed_captures(self)
  cmd.release()
  guard self.surface is Some(surface) else {
    frame.encoder.release()
    frame.surface_texture.release()
    frame.surface_view.release()
    frame.surface_tex.release()
    self.surface_capture_active = false
    active_surface_screenshot_capture_ids_ref.val.clear()
    self.frame = None
    self.pass_state = None
    return
  }
  surface.present() |> ignore
  self.instance.process_events()
  frame.encoder.release()
  frame.surface_texture.release()
  frame.surface_view.release()
  frame.surface_tex.release()
  self.surface_capture_active = false
  active_surface_screenshot_capture_ids_ref.val.clear()
  self.frame = None
  self.pass_state = None
}
