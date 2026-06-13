// Copyright 2026 International Digital Economy Academy
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
const SKYBOX_UNIFORM_BUFFER_SIZE : UInt64 = 80UL

///|
fn skybox_pipeline_cache_get(
  backend : GpuBackend,
  surface_format : @wgpu.TextureFormat,
  samples : Int,
) -> @wgpu.RenderPipeline? {
  for entry in backend.skybox_pipeline_cache {
    if entry.surface_format.raw == surface_format.raw &&
      entry.samples == samples {
      return Some(entry.pipeline)
    }
  }
  None
}

///|
fn skybox_quat_rotation_matrix_words(
  x : Float,
  y : Float,
  z : Float,
  w : Float,
) -> Array[UInt] {
  let len_sq = x * x + y * y + z * z + w * w
  let (qx, qy, qz, qw) = if len_sq <= 1.0e-8F {
    (0.0F, 0.0F, 0.0F, 1.0F)
  } else {
    let inv_len = 1.0F / Float::sqrt(len_sq)
    (x * inv_len, y * inv_len, z * inv_len, w * inv_len)
  }
  let xx = qx * qx
  let yy = qy * qy
  let zz = qz * qz
  let xy = qx * qy
  let xz = qx * qz
  let yz = qy * qz
  let wx = qw * qx
  let wy = qw * qy
  let wz = qw * qz
  [
    f32_bits(1.0F - 2.0F * (yy + zz)),
    f32_bits(2.0F * (xy + wz)),
    f32_bits(2.0F * (xz - wy)),
    f32_bits(0.0F),
    f32_bits(2.0F * (xy - wz)),
    f32_bits(1.0F - 2.0F * (xx + zz)),
    f32_bits(2.0F * (yz + wx)),
    f32_bits(0.0F),
    f32_bits(2.0F * (xz + wy)),
    f32_bits(2.0F * (yz - wx)),
    f32_bits(1.0F - 2.0F * (xx + yy)),
    f32_bits(0.0F),
    f32_bits(0.0F),
    f32_bits(0.0F),
    f32_bits(0.0F),
    f32_bits(1.0F),
  ]
}

///|
fn skybox_uniform_bytes(
  brightness : Float,
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
) -> Bytes {
  let words : Array[UInt] = [f32_bits(brightness), 0U, 0U, 0U]
  for
    word in skybox_quat_rotation_matrix_words(
      rotation_x, rotation_y, rotation_z, rotation_w,
    ) {
    words.push(word)
  }
  u32le_pack(words)
}

///|
fn ensure_skybox_resources(backend : GpuBackend) -> Unit raise GpuBackendError {
  if backend.skybox_bgl is None {
    let vertex_fragment = ss(
      @wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT,
    )
    let fragment = ss(@wgpu.SHADER_STAGE_FRAGMENT)
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=4UL)
    let ok = builder.add_texture(
        0U,
        fragment,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_CUBE,
      ) &&
      builder.add_sampler(1U, fragment, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
      builder.add_buffer(
        2U,
        vertex_fragment,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        3U,
        vertex_fragment,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=SKYBOX_UNIFORM_BUFFER_SIZE,
      )
    if !ok {
      builder.free()
      fatal("wgpu: failed to build skybox bind group layout")
    }
    let bgl = builder.finish(backend.device, label="mgstudio_skybox_bgl")
    let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
    pipeline_layout.set_label("mgstudio_skybox_pipeline_layout")
    backend.skybox_bgl = Some(bgl)
    backend.skybox_pipeline_layout = Some(pipeline_layout)
  }
  if backend.skybox_uniform_buf is None {
    backend.skybox_uniform_buf = Some(
      backend.device.create_buffer(
        size=SKYBOX_UNIFORM_BUFFER_SIZE,
        usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
      ),
    )
  }
}

///|
fn skybox_pipeline_get_or_create(
  backend : GpuBackend,
  surface_format : @wgpu.TextureFormat,
  samples : Int,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let safe_samples = if samples <= 1 { 1 } else { samples }
  if skybox_pipeline_cache_get(backend, surface_format, safe_samples)
    is Some(pipeline) {
    return Some(pipeline)
  }
  ensure_skybox_resources(backend)
  guard backend.skybox_pipeline_layout is Some(layout) else { return None }
  let source = load_wgsl_preprocessed(
    backend.assets_base,
    "core_pipeline/skybox/skybox.wgsl",
    postprocess_define_keys_map([]),
    default_wgsl_value_defines(),
  )
  let shader = create_postprocess_shader_module(
    backend, source, "mgstudio_skybox",
  )
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(shader, layout~)
    builder.set_entry_points("skybox_vertex", "skybox_fragment")
    builder.set_color_target_format(surface_format)
    builder.disable_blend()
    builder.set_multisample(safe_samples.reinterpret_as_uint())
    builder.set_depth_stencil(
      tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
      depth_write_enabled=false,
      depth_compare_u32=@wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
    )
    builder.set_cull_mode_u32(@wgpu.CULL_MODE_NONE)
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      err |> ignore
      shader.release()
      fatal("wgpu: failed to build skybox pipeline")
    }
  }
  pipeline.set_label(
    "mgstudio_skybox_pipeline_\{surface_format.raw.to_string()}_\{safe_samples.to_string()}",
  )
  shader.release()
  backend.skybox_pipeline_cache.push(SkyboxPipelineCacheEntry::{
    surface_format,
    samples: safe_samples,
    pipeline,
  })
  Some(pipeline)
}

///|
fn skybox_prepared_bind_group_find(
  backend : GpuBackend,
  id : Int,
) -> SkyboxPreparedBindGroupEntry? {
  for entry in backend.skybox_prepared_bind_groups {
    if entry.id == id {
      return Some(entry)
    }
  }
  None
}

///|
fn GpuBackend::release_skybox_prepared_bind_group_by_index(
  self : GpuBackend,
  index : Int,
) -> Unit {
  let removed = self.skybox_prepared_bind_groups.remove(index)
  removed.bind_group.release()
  removed.uniform_buffer.release()
}

///|
pub fn GpuBackend::release_skybox_prepared_bind_group(
  self : GpuBackend,
  id : Int,
) -> Bool {
  for i in 0..<self.skybox_prepared_bind_groups.length() {
    if self.skybox_prepared_bind_groups[i].id == id {
      self.release_skybox_prepared_bind_group_by_index(i)
      return true
    }
  }
  false
}

///|
pub fn GpuBackend::prepare_skybox_bind_group(
  self : GpuBackend,
  texture_id : Int,
  brightness : Float,
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
) -> Int? raise GpuBackendError {
  guard texture_id >= 0 else { return None }
  guard find_texture(self, texture_id) is Some(texture) else { return None }
  guard texture.sample_view is Some(cube_view) else { return None }
  ensure_skybox_resources(self)
  ensure_mesh3d_view_binding_buffers(self)
  guard self.skybox_bgl is Some(bind_layout) else { return None }
  guard self.mesh3d_view_buf is Some(view_buf) else { return None }
  let skybox_uniform_buf = self.device.create_buffer(
    size=SKYBOX_UNIFORM_BUFFER_SIZE,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  self.queue.write_buffer(
    skybox_uniform_buf,
    0UL,
    skybox_uniform_bytes(
      brightness, rotation_x, rotation_y, rotation_z, rotation_w,
    ),
  )
  let builder = @wgpu.BindGroupBuilder::new(max_entries=4UL)
  let ok = builder.add_texture_view(0U, cube_view) &&
    builder.add_sampler(1U, texture.sampler) &&
    builder.add_buffer(2U, view_buf, size=MESH3D_VIEW_BUFFER_SIZE) &&
    builder.add_buffer(3U, skybox_uniform_buf, size=SKYBOX_UNIFORM_BUFFER_SIZE)
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    self.device,
    bind_layout,
    label="mgstudio_skybox_bind_group",
  )
  let id = self.skybox_next_prepared_bind_group_id
  self.skybox_next_prepared_bind_group_id = id + 1
  self.skybox_prepared_bind_groups.push(SkyboxPreparedBindGroupEntry::{
    id,
    bind_group,
    uniform_buffer: skybox_uniform_buf,
  })
  Some(id)
}

///|
pub fn GpuBackend::draw_prepared_skybox(
  self : GpuBackend,
  bind_group_id : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(active_pass) else { return }
  guard self.pass_state is Some(pass_state) else { return }
  guard skybox_prepared_bind_group_find(self, bind_group_id) is Some(entry) else {
    return
  }
  let format = match current_pass_color_format(self) {
    Some(format) => format
    None => tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
  }
  let sample_count = if pass_state.msaa_sample_count <= 1 {
    1
  } else {
    pass_state.msaa_sample_count
  }
  guard skybox_pipeline_get_or_create(self, format, sample_count)
    is Some(pipeline) else {
    return
  }
  ensure_mesh3d_view_binding_buffers(self)
  guard self.mesh3d_view_buf is Some(view_buf) else { return }
  self.queue.write_buffer(view_buf, 0UL, mesh3d_view_uniform_bytes(pass_state))
  active_pass.set_pipeline(pipeline)
  active_pass.set_bind_group(0U, entry.bind_group, [])
  active_pass.draw(3U, 1U, 0U, 0U)
}

///|
pub fn prepare_skybox_bind_group(
  texture_id~ : Int,
  brightness~ : Float,
  rotation_x~ : Float,
  rotation_y~ : Float,
  rotation_z~ : Float,
  rotation_w~ : Float,
) -> Int? {
  match ensure_backend() {
    Some(backend) =>
      backend.prepare_skybox_bind_group(
        texture_id, brightness, rotation_x, rotation_y, rotation_z, rotation_w,
      ) catch {
        err => {
          debug_runtime_error("prepare_skybox_bind_group", err)
          None
        }
      }
    None => None
  }
}

///|
pub fn release_skybox_prepared_bind_group(bind_group_id~ : Int) -> Bool {
  match ensure_backend() {
    Some(backend) => backend.release_skybox_prepared_bind_group(bind_group_id)
    None => false
  }
}

///|
pub fn draw_prepared_skybox(bind_group_id~ : Int) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_prepared_skybox(bind_group_id) catch {
      err => debug_runtime_error("draw_prepared_skybox", err)
    }
  }
}
