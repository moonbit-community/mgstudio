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
fn ssao_safe_extent(value : Int) -> UInt {
  if value <= 0 {
    1U
  } else {
    value.reinterpret_as_uint()
  }
}

///|
fn ssao_resource_shape_matches(
  resources : GpuSsaoResources,
  width : Int,
  height : Int,
  depth_format : @wgpu.TextureFormat,
  constant_object_thickness : Float,
) -> Bool {
  resources.width == width &&
  resources.height == height &&
  resources.depth_format == depth_format &&
  resources.constant_object_thickness == constant_object_thickness
}

///|
fn ssao_create_texture_2d(
  backend : GpuBackend,
  width : Int,
  height : Int,
  mip_level_count : UInt,
  format : @wgpu.TextureFormat,
  label : String,
) -> (@wgpu.Texture, @wgpu.TextureView) {
  let texture = backend.device.create_texture_u32(
    ssao_safe_extent(width),
    ssao_safe_extent(height),
    mip_level_count,
    @wgpu.TextureUsage::from_u64(
      @wgpu.TEXTURE_USAGE_STORAGE_BINDING | @wgpu.TEXTURE_USAGE_TEXTURE_BINDING,
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
  (texture, view)
}

///|
fn ssao_create_thickness_buffer(
  backend : GpuBackend,
  constant_object_thickness : Float,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=4UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  buffer.set_label("mgstudio_ssao_thickness_buffer")
  backend.queue.write_buffer(
    buffer,
    0UL,
    f32le_pack([constant_object_thickness]),
  )
  buffer
}

///|
pub fn GpuBackend::prepare_mesh3d_ssao_resources(
  self : GpuBackend,
  width : Int,
  height : Int,
  constant_object_thickness : Float,
) -> Unit {
  let depth_format = tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT)
  if self.mesh3d_ssao_resources is Some(resources) &&
    ssao_resource_shape_matches(
      resources, width, height, depth_format, constant_object_thickness,
    ) {
    return
  }
  let next_revision = self.mesh3d_ssao_resource_revision + 1
  let (preprocessed_depth_texture, preprocessed_depth_view) = ssao_create_texture_2d(
    self, width, height, 5U, depth_format, "mgstudio_ssao_preprocessed_depth_texture",
  )
  let (ssao_noisy_texture, ssao_noisy_view) = ssao_create_texture_2d(
    self, width, height, 1U, depth_format, "mgstudio_ssao_noisy_texture",
  )
  let (
    screen_space_ambient_occlusion_texture,
    screen_space_ambient_occlusion_view,
  ) = ssao_create_texture_2d(
    self, width, height, 1U, depth_format, "mgstudio_ssao_texture",
  )
  let (depth_differences_texture, depth_differences_view) = ssao_create_texture_2d(
    self,
    width,
    height,
    1U,
    tf(@wgpu.TEXTURE_FORMAT_R32_UINT),
    "mgstudio_ssao_depth_differences_texture",
  )
  let thickness_buffer = ssao_create_thickness_buffer(
    self, constant_object_thickness,
  )
  self.mesh3d_ssao_resources = Some(GpuSsaoResources::{
    width,
    height,
    depth_format,
    preprocessed_depth_texture,
    preprocessed_depth_view,
    ssao_noisy_texture,
    ssao_noisy_view,
    screen_space_ambient_occlusion_texture,
    screen_space_ambient_occlusion_view,
    depth_differences_texture,
    depth_differences_view,
    thickness_buffer,
    constant_object_thickness,
    revision: next_revision,
  })
  self.mesh3d_ssao_resource_revision = next_revision
  mesh3d_material_cache_clear(self)
}
