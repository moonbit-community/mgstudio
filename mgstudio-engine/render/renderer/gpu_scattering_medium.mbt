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
fn scattering_medium_safe_extent(value : Int) -> UInt {
  if value <= 0 {
    1U
  } else {
    value.reinterpret_as_uint()
  }
}

///|
fn scattering_medium_expected_bytes(width : Int, height : Int) -> Int {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  safe_width * safe_height * 16
}

///|
fn scattering_medium_upload_rgba32f_texture(
  backend : GpuBackend,
  width : Int,
  height : Int,
  bytes : Bytes,
  label : String,
) -> (@wgpu.Texture, @wgpu.TextureView) raise GpuBackendError {
  let safe_width = scattering_medium_safe_extent(width)
  let safe_height = scattering_medium_safe_extent(height)
  let format = tf(@wgpu.TEXTURE_FORMAT_RGBA32_FLOAT)
  let texture = backend.device.create_texture_u32(
    safe_width,
    safe_height,
    1U,
    @wgpu.TextureUsage::from_u64(
      @wgpu.TEXTURE_USAGE_TEXTURE_BINDING | @wgpu.TEXTURE_USAGE_COPY_DST,
    ),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    format,
  )
  texture.set_label(label)
  let view = texture.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    @wgpu.TEXTURE_ASPECT_ALL,
    0U,
    1U,
    0U,
    1U,
  )
  view.set_label("\{label}_view")
  scattering_medium_write_rgba32f_texture(
    backend, texture, width, height, bytes, label,
  )
  (texture, view)
}

///|
fn scattering_medium_write_rgba32f_texture(
  backend : GpuBackend,
  texture : @wgpu.Texture,
  width : Int,
  height : Int,
  bytes : Bytes,
  label : String,
) -> Unit raise GpuBackendError {
  let safe_width = scattering_medium_safe_extent(width)
  let safe_height = scattering_medium_safe_extent(height)
  let expected = scattering_medium_expected_bytes(width, height)
  if bytes.length() != expected {
    fatal(
      "wgpu: scattering medium LUT byte size mismatch for \{label}: got \{bytes.length()}, expected \{expected}",
    )
  }
  let source_bytes_per_row = safe_width.reinterpret_as_int() * 16
  let rows = safe_height.reinterpret_as_int()
  let mut upload_bytes_per_row = source_bytes_per_row
  if upload_bytes_per_row % 256 != 0 {
    upload_bytes_per_row = (upload_bytes_per_row / 256 + 1) * 256
  }
  let upload_size = upload_bytes_per_row * rows
  let upload = if upload_bytes_per_row == source_bytes_per_row {
    bytes
  } else {
    Bytes::makei(upload_size, i => {
      let row = i / upload_bytes_per_row
      let col = i % upload_bytes_per_row
      if col < source_bytes_per_row {
        match bytes.get(row * source_bytes_per_row + col) {
          Some(byte) => byte
          None => (0).to_byte()
        }
      } else {
        (0).to_byte()
      }
    })
  }
  let tex_info = @wgpu_c.texel_copy_texture_info_new(
    texture.raw,
    0U,
    0U,
    0U,
    0U,
  )
  defer @wgpu_c.texel_copy_texture_info_free(tex_info)
  let layout = @wgpu_c.texel_copy_buffer_layout_new(
    0UL,
    upload_bytes_per_row.reinterpret_as_uint(),
    safe_height,
  )
  defer @wgpu_c.texel_copy_buffer_layout_free(layout)
  let extent = @wgpu_c.extent3d_new(safe_width, safe_height, 1U)
  defer @wgpu_c.extent3d_free(extent)
  backend.queue.write_texture_ptr(
    tex_info,
    upload,
    layout,
    extent,
    data_size=upload_size.to_uint64(),
  )
}

///|
fn scattering_medium_resource_shape_matches(
  resources : GpuScatteringMediumResources,
  density_width : Int,
  density_height : Int,
  scattering_width : Int,
  scattering_height : Int,
) -> Bool {
  resources.density_width == density_width &&
  resources.density_height == density_height &&
  resources.scattering_width == scattering_width &&
  resources.scattering_height == scattering_height
}

///|
fn GpuScatteringMediumResources::release(
  self : GpuScatteringMediumResources,
) -> Unit {
  self.sampler.release()
  self.scattering_view.release()
  self.density_view.release()
  self.scattering_texture.release()
  self.density_texture.release()
}

///|
fn scattering_medium_resources_keepalive(
  resources : GpuScatteringMediumResources,
) -> Unit {
  ignore(resources.density_texture)
  ignore(resources.density_view)
  ignore(resources.scattering_texture)
  ignore(resources.scattering_view)
  ignore(resources.sampler)
  ignore(resources.density_bytes)
  ignore(resources.scattering_bytes)
  ignore(resources.revision)
}

///|
fn GpuBackend::mesh3d_prepare_scattering_medium_resources(
  self : GpuBackend,
  density_width~ : Int,
  density_height~ : Int,
  density_bytes~ : Bytes,
  scattering_width~ : Int,
  scattering_height~ : Int,
  scattering_bytes~ : Bytes,
) -> Unit raise GpuBackendError {
  let safe_density_width = if density_width <= 0 { 1 } else { density_width }
  let safe_density_height = if density_height <= 0 { 1 } else { density_height }
  let safe_scattering_width = if scattering_width <= 0 {
    1
  } else {
    scattering_width
  }
  let safe_scattering_height = if scattering_height <= 0 {
    1
  } else {
    scattering_height
  }
  let needs_recreate = match self.mesh3d_scattering_medium_resources {
    Some(resources) => {
      scattering_medium_resources_keepalive(resources)
      !scattering_medium_resource_shape_matches(
        resources, safe_density_width, safe_density_height, safe_scattering_width,
        safe_scattering_height,
      )
    }
    None => true
  }
  if !needs_recreate &&
    self.mesh3d_scattering_medium_resources is Some(resources) {
    let needs_density_upload = resources.density_bytes != density_bytes
    let needs_scattering_upload = resources.scattering_bytes != scattering_bytes
    if !needs_density_upload && !needs_scattering_upload {
      return
    }
    if needs_density_upload {
      scattering_medium_write_rgba32f_texture(
        self,
        resources.density_texture,
        safe_density_width,
        safe_density_height,
        density_bytes,
        "mgstudio_scattering_medium_density_lut",
      )
    }
    if needs_scattering_upload {
      scattering_medium_write_rgba32f_texture(
        self,
        resources.scattering_texture,
        safe_scattering_width,
        safe_scattering_height,
        scattering_bytes,
        "mgstudio_scattering_medium_scattering_lut",
      )
    }
    self.mesh3d_scattering_medium_resource_revision += 1
    self.mesh3d_scattering_medium_resources = Some(GpuScatteringMediumResources::{
      ..resources,
      density_bytes,
      scattering_bytes,
      revision: self.mesh3d_scattering_medium_resource_revision,
    })
    return
  }
  if !needs_recreate {
    return
  }
  let (density_texture, density_view) = scattering_medium_upload_rgba32f_texture(
    self, safe_density_width, safe_density_height, density_bytes, "mgstudio_scattering_medium_density_lut",
  )
  let (scattering_texture, scattering_view) = scattering_medium_upload_rgba32f_texture(
    self, safe_scattering_width, safe_scattering_height, scattering_bytes, "mgstudio_scattering_medium_scattering_lut",
  )
  let sampler = self.device.create_sampler_linear_clamp()
  sampler.set_label("mgstudio_scattering_medium_sampler")
  let next_revision = self.mesh3d_scattering_medium_resource_revision + 1
  let replacement = GpuScatteringMediumResources::{
    density_texture,
    density_view,
    scattering_texture,
    scattering_view,
    sampler,
    density_bytes,
    scattering_bytes,
    density_width: safe_density_width,
    density_height: safe_density_height,
    scattering_width: safe_scattering_width,
    scattering_height: safe_scattering_height,
    revision: next_revision,
  }
  let previous = self.mesh3d_scattering_medium_resources
  self.mesh3d_scattering_medium_resources = Some(replacement)
  self.mesh3d_scattering_medium_resource_revision = next_revision
  if previous is Some(resources) {
    resources.release()
  }
}

///|
pub fn prepare_mesh3d_scattering_medium_resources(
  density_width~ : Int,
  density_height~ : Int,
  density_bytes~ : Bytes,
  scattering_width~ : Int,
  scattering_height~ : Int,
  scattering_bytes~ : Bytes,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.mesh3d_prepare_scattering_medium_resources(
      density_width~,
      density_height~,
      density_bytes~,
      scattering_width~,
      scattering_height~,
      scattering_bytes~,
    ) catch {
      err =>
        debug_runtime_error("prepare_mesh3d_scattering_medium_resources", err)
    }
  }
}
