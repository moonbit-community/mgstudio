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
fn motion_blur_debug_enabled() -> Bool {
  match @sys.get_env_var("MGSTUDIO_MOTION_BLUR_DEBUG") {
    Some(flag) => flag.trim().to_owned() == "1"
    _ => false
  }
}

///|
fn motion_blur_debug_log(message : String) -> Unit {
  if motion_blur_debug_enabled() {
    println("[motion_blur] \{message}")
  }
}

///|
const MOTION_BLUR_UNIFORM_BUFFER_SIZE : UInt64 = 16UL

///|
const MOTION_BLUR_GLOBALS_BUFFER_SIZE : UInt64 = 16UL

///|
fn ensure_motion_blur_globals_buffer(backend : GpuBackend) -> Unit {
  let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
  if backend.motion_blur_globals_buf is None {
    backend.motion_blur_globals_buf = Some(
      backend.device.create_buffer(size=MOTION_BLUR_GLOBALS_BUFFER_SIZE, usage~),
    )
  }
}

///|
pub fn GpuBackend::prepare_motion_blur(
  self : GpuBackend,
  velocity_texture_id : Int,
) -> Unit {
  guard self.frame is Some(frame) else {
    motion_blur_debug_log("prepare skip: no frame")
    return
  }
  guard frame.pass is Some(_) else {
    motion_blur_debug_log("prepare skip: no active render pass")
    return
  }
  if velocity_texture_id < 0 {
    motion_blur_debug_log(
      "prepare skip: invalid velocity texture id=\{velocity_texture_id}",
    )
    return
  }
  guard find_texture(self, velocity_texture_id) is Some(_) else {
    motion_blur_debug_log(
      "prepare skip: velocity texture not found id=\{velocity_texture_id}",
    )
    return
  }
  ensure_motion_blur_globals_buffer(self)
  guard self.motion_blur_globals_buf is Some(globals_buf) else {
    motion_blur_debug_log("prepare skip: no globals buffer")
    return
  }
  let globals_bytes = u32le_pack([
    f32_bits(0.0F),
    f32_bits(0.0F),
    self.frame_count,
    0U,
  ])
  self.queue.write_buffer(globals_buf, 0UL, globals_bytes)
  motion_blur_debug_log("prepare: velocity=\{velocity_texture_id}")
}

///|
pub fn GpuBackend::draw_motion_blur(
  self : GpuBackend,
  scene_texture_id : Int,
  velocity_texture_id : Int,
  pipeline : @render_resource.RenderPipeline,
  sampler : @render_resource.Sampler,
  settings_buffer : @wgpu.Buffer,
  settings_offset : UInt,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else {
    motion_blur_debug_log("skip: no frame")
    return
  }
  guard frame.pass is Some(pass) else {
    motion_blur_debug_log("skip: no active render pass")
    return
  }
  flush_mesh2d_batches(self)
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard self.motion_blur_globals_buf is Some(globals_buf) else {
    motion_blur_debug_log("skip: no globals buffer")
    return
  }
  if scene_texture_id < 0 || velocity_texture_id < 0 {
    motion_blur_debug_log(
      "skip: invalid texture ids scene=\{scene_texture_id}, velocity=\{velocity_texture_id}",
    )
    return
  }
  guard find_texture(self, scene_texture_id) is Some(scene_texture) else {
    motion_blur_debug_log(
      "skip: scene texture not found id=\{scene_texture_id}",
    )
    return
  }
  guard find_texture(self, velocity_texture_id) is Some(velocity_texture) else {
    motion_blur_debug_log(
      "skip: velocity texture not found id=\{velocity_texture_id}",
    )
    return
  }
  let multisampled = velocity_texture.texture.sample_count_u32() > 1U
  let material_bgl = pipeline.get_bind_group_layout(0U).into_inner()
  guard self.depth_view is Some(depth_view) else {
    motion_blur_debug_log("skip: no depth_view")
    return
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=6UL)
  let ok = builder.add_texture_view(0U, scene_texture.view) &&
    builder.add_texture_view(1U, velocity_texture.view) &&
    builder.add_texture_view(2U, depth_view) &&
    builder.add_sampler(3U, sampler.into_inner()) &&
    builder.add_buffer(
      4U,
      settings_buffer,
      offset=settings_offset.to_uint64(),
      size=MOTION_BLUR_UNIFORM_BUFFER_SIZE,
    ) &&
    builder.add_buffer(5U, globals_buf)
  if !ok {
    builder.free()
    return
  }
  let material_bg = builder.finish(
    self.device,
    material_bgl,
    label="mgstudio_motion_blur_bg",
  )
  motion_blur_debug_log(
    "draw: scene=\{scene_texture_id}, velocity=\{velocity_texture_id}, msaa=\{multisampled}",
  )
  pass.set_pipeline(pipeline.into_inner())
  pass.set_bind_group(0U, material_bg, [])
  pass.draw(3U, 1U, 0U, 0U)
  material_bg.release()
}

///|
pub fn prepare_motion_blur(velocity_texture_id~ : Int) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_motion_blur(velocity_texture_id)
  }
}

///|
pub fn draw_motion_blur(
  scene_texture_id~ : Int,
  velocity_texture_id~ : Int,
  pipeline~ : @render_resource.RenderPipeline,
  sampler~ : @render_resource.Sampler,
  settings_buffer~ : @wgpu.Buffer,
  settings_offset~ : UInt,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_motion_blur(
      scene_texture_id, velocity_texture_id, pipeline, sampler, settings_buffer,
      settings_offset,
    ) catch {
      err => debug_runtime_error("draw_motion_blur", err)
    }
  }
}

///|
