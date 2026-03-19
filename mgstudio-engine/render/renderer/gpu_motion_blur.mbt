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
    Some(flag) => flag.trim().to_string() == "1"
    _ => false
  }
}

///|
fn motion_blur_debug_log(message : String) -> Unit {
  if motion_blur_debug_enabled() {
    println("[motion_blur] " + message)
  }
}

///|
fn ensure_motion_blur_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.motion_blur_settings_buf is None {
    let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
    backend.motion_blur_settings_buf = Some(
      backend.device.create_buffer(size=16UL, usage~),
    )
  }
  if backend.motion_blur_globals_buf is None {
    let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
    backend.motion_blur_globals_buf = Some(
      backend.device.create_buffer(size=16UL, usage~),
    )
  }
  if backend.motion_blur_pipeline is Some(_) {
    return
  }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/bevy_post_process/motion_blur/motion_blur.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_render_pipeline_color_format_entries(
    sm,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    vs_entry="fullscreen_vertex_shader",
    fs_entry="fragment",
    alpha_blend=false,
    depth=false,
  )
  pipeline.set_label("mgstudio_motion_blur_rgba8")
  backend.motion_blur_bgl = Some(pipeline.get_bind_group_layout(0U))
  backend.motion_blur_pipeline = Some(pipeline)
  sm.release()
}

///|
fn ensure_motion_blur_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  ensure_motion_blur_pipeline_rgba8(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.motion_blur_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.motion_blur_pipeline_surface is Some(_) {
    return
  }
  if backend.motion_blur_pipeline_surface is Some(old) {
    old.release()
  }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/bevy_post_process/motion_blur/motion_blur.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_render_pipeline_color_format_entries(
    sm,
    format,
    vs_entry="fullscreen_vertex_shader",
    fs_entry="fragment",
    alpha_blend=false,
    depth=false,
  )
  pipeline.set_label("mgstudio_motion_blur_surface")
  backend.motion_blur_pipeline_surface = Some(pipeline)
  backend.motion_blur_pipeline_surface_format = Some(format)
  sm.release()
}

///|
fn motion_blur_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_motion_blur_pipeline_surface(backend, format)
      return backend.motion_blur_pipeline_surface
    }
    _ => ()
  }
  ensure_motion_blur_pipeline_rgba8(backend)
  backend.motion_blur_pipeline
}

///|
pub fn GpuBackend::draw_motion_blur(
  self : GpuBackend,
  scene_texture_id : Int,
  velocity_texture_id : Int,
  shutter_angle : Float,
  samples : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else {
    motion_blur_debug_log("skip: no frame")
    return
  }
  guard frame.pass is Some(pass) else {
    motion_blur_debug_log("skip: no active render pass")
    return
  }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard motion_blur_pipeline_for_current_pass(self) is Some(pipeline) else {
    motion_blur_debug_log("skip: no pipeline")
    return
  }
  guard self.motion_blur_settings_buf is Some(settings_buf) else {
    motion_blur_debug_log("skip: no settings buffer")
    return
  }
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
  guard self.depth_view is Some(depth_view) else {
    motion_blur_debug_log("skip: no depth_view")
    return
  }
  let clamped_samples = if samples < 0 {
    0
  } else if samples > 64 {
    64
  } else {
    samples
  }
  let settings_bytes = u32le_pack([
    f32_bits(shutter_angle),
    clamped_samples.reinterpret_as_uint(),
    0U,
    0U,
  ])
  self.queue.write_buffer(settings_buf, 0UL, settings_bytes)
  let globals_bytes = u32le_pack([
    f32_bits(0.0F),
    f32_bits(0.0F),
    self.frame_count,
    0U,
  ])
  self.queue.write_buffer(globals_buf, 0UL, globals_bytes)

  let material_bgl = pipeline.get_bind_group_layout(0U)
  let builder = @wgpu.BindGroupBuilder::new(max_entries=6UL)
  let ok = builder.add_texture_view(0U, scene_texture.view) &&
    builder.add_texture_view(1U, velocity_texture.view) &&
    builder.add_texture_view(2U, depth_view) &&
    builder.add_sampler(3U, scene_texture.sampler) &&
    builder.add_buffer(4U, settings_buf) &&
    builder.add_buffer(5U, globals_buf)
  if !ok {
    builder.free()
    material_bgl.release()
    return
  }
  let material_bg = builder.finish(
    self.device,
    material_bgl,
    label="mgstudio_motion_blur_bg",
  )
  motion_blur_debug_log(
    "draw: scene=\{scene_texture_id}, velocity=\{velocity_texture_id}, samples=\{clamped_samples}",
  )
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, material_bg, [])
  pass.draw(3U, 1U, 0U, 0U)
  material_bg.release()
  material_bgl.release()
}

///|

///|
