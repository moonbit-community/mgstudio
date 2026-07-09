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
// Bevy source: `bevy/crates/bevy_pbr/src/atmosphere/resources.rs`.

///|
pub type AtmosphereMode = @light.AtmosphereMode

///|
pub type AtmosphereSettings = @light.AtmosphereSettings

///|
pub type Atmosphere = @light.Atmosphere

///|
pub struct GpuAtmosphereSettings {
  transmittance_lut_size : @math.UVec2
  multiscattering_lut_size : @math.UVec2
  sky_view_lut_size : @math.UVec2
  aerial_view_lut_size : (@math.UVec2, Int)
  transmittance_lut_samples : Int
  multiscattering_lut_dirs : Int
  multiscattering_lut_samples : Int
  sky_view_lut_samples : Int
  aerial_view_lut_samples : Int
  aerial_view_lut_max_distance : Float
  sky_max_samples : Int
  rendering_method : Int
}

///|
pub struct GpuAtmosphere {
  ground_albedo : @math.Vec3
  inner_radius : Float
  outer_radius : Float
  world_to_atmosphere : @math.Affine3
}

///|
pub struct AtmosphereTransform {
  world_from_atmosphere : @math.Mat4
  atmosphere_from_world : @math.Mat4
}

///|
pub let ecs_key_gpu_atmosphere_settings : @ecs.ComponentKey[
  GpuAtmosphereSettings,
] = @ecs.register_component(debug_name="mgstudio_pbr::GpuAtmosphereSettings")

///|
pub impl @ecs.Component for GpuAtmosphereSettings with fn component() {
  ecs_key_gpu_atmosphere_settings
}

///|
pub let ecs_key_gpu_atmosphere : @ecs.ComponentKey[GpuAtmosphere] = @ecs.register_component(
  debug_name="mgstudio_pbr::GpuAtmosphere",
)

///|
pub impl @ecs.Component for GpuAtmosphere with fn component() {
  ecs_key_gpu_atmosphere
}

///|
fn pbr_atmosphere_u32le_pack(words : Array[UInt]) -> Bytes {
  Bytes::makei(words.length() * 4, i => {
    let word = words[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
fn pbr_atmosphere_f32_bits(value : Float) -> UInt {
  value.reinterpret_as_uint()
}

///|
fn pbr_atmosphere_push_mat4_words(
  words : Array[UInt],
  matrix : @math.Mat4,
) -> Unit {
  let columns = [
    matrix.x_axis(),
    matrix.y_axis(),
    matrix.z_axis(),
    matrix.w_axis(),
  ]
  for column in columns {
    words.push(pbr_atmosphere_f32_bits(column.x))
    words.push(pbr_atmosphere_f32_bits(column.y))
    words.push(pbr_atmosphere_f32_bits(column.z))
    words.push(pbr_atmosphere_f32_bits(column.w))
  }
}

///|
pub fn GpuAtmosphere::GpuAtmosphere() -> GpuAtmosphere {
  GpuAtmosphere::{
    ground_albedo: @math.Vec3::zero(),
    inner_radius: 0.0F,
    outer_radius: 0.0F,
    world_to_atmosphere: @math.Affine3::identity(),
  }
}

///|
pub fn GpuAtmosphere::as_uniform_bytes(self : GpuAtmosphere) -> Bytes {
  pbr_atmosphere_u32le_pack([
    pbr_atmosphere_f32_bits(self.ground_albedo.x),
    pbr_atmosphere_f32_bits(self.ground_albedo.y),
    pbr_atmosphere_f32_bits(self.ground_albedo.z),
    pbr_atmosphere_f32_bits(self.inner_radius),
    pbr_atmosphere_f32_bits(self.outer_radius),
    0U,
    0U,
    0U,
    pbr_atmosphere_f32_bits(self.world_to_atmosphere.matrix3.x_axis.x),
    pbr_atmosphere_f32_bits(self.world_to_atmosphere.matrix3.x_axis.y),
    pbr_atmosphere_f32_bits(self.world_to_atmosphere.matrix3.x_axis.z),
    pbr_atmosphere_f32_bits(0.0F),
    pbr_atmosphere_f32_bits(self.world_to_atmosphere.matrix3.y_axis.x),
    pbr_atmosphere_f32_bits(self.world_to_atmosphere.matrix3.y_axis.y),
    pbr_atmosphere_f32_bits(self.world_to_atmosphere.matrix3.y_axis.z),
    pbr_atmosphere_f32_bits(0.0F),
    pbr_atmosphere_f32_bits(self.world_to_atmosphere.matrix3.z_axis.x),
    pbr_atmosphere_f32_bits(self.world_to_atmosphere.matrix3.z_axis.y),
    pbr_atmosphere_f32_bits(self.world_to_atmosphere.matrix3.z_axis.z),
    pbr_atmosphere_f32_bits(0.0F),
    pbr_atmosphere_f32_bits(self.world_to_atmosphere.translation.x),
    pbr_atmosphere_f32_bits(self.world_to_atmosphere.translation.y),
    pbr_atmosphere_f32_bits(self.world_to_atmosphere.translation.z),
    pbr_atmosphere_f32_bits(1.0F),
  ])
}

///|
pub fn pbr_gpu_atmosphere(
  atmosphere : Atmosphere,
  world_to_atmosphere : @math.Affine3,
) -> GpuAtmosphere {
  pbr_gpu_atmosphere_from_extracted(
    atmosphere.inner_radius,
    atmosphere.outer_radius,
    atmosphere.ground_albedo,
    world_to_atmosphere,
  )
}

///|
pub fn pbr_gpu_atmosphere_from_extracted(
  inner_radius : Float,
  outer_radius : Float,
  ground_albedo : @math.Vec3,
  world_to_atmosphere : @math.Affine3,
) -> GpuAtmosphere {
  GpuAtmosphere::{
    ground_albedo,
    inner_radius,
    outer_radius,
    world_to_atmosphere,
  }
}

///|
pub fn pbr_atmosphere_prepare_transform(
  camera_world : @math.Vec3,
  world_to_atmosphere : @math.Affine3,
) -> AtmosphereTransform {
  let cam_pos = world_to_atmosphere.transform_point3(camera_world)
  let atmo_y = if cam_pos.length_squared() > 0.0F {
    cam_pos.normalize()
  } else {
    @math.Vec3::new(0.0F, 1.0F, 0.0F)
  }
  let world_ref = @math.Vec3::new(0.0F, 0.0F, -1.0F)
  let ref_horizontal = world_ref.sub(atmo_y.mul_scalar(atmo_y.dot(world_ref)))
  let atmo_z = ref_horizontal.normalize()
  let atmo_x = atmo_y.cross(atmo_z).normalize()
  let world_from_atmosphere = @math.Mat4::from_affine3(
    @math.Affine3::from_mat3_translation(
      @math.Mat3::from_cols(atmo_x, atmo_y, atmo_z),
      camera_world,
    ),
  )
  AtmosphereTransform::{
    world_from_atmosphere,
    atmosphere_from_world: world_from_atmosphere.transpose(),
  }
}

///|
pub fn AtmosphereTransform::as_uniform_bytes(
  self : AtmosphereTransform,
) -> Bytes {
  let words : Array[UInt] = []
  pbr_atmosphere_push_mat4_words(words, self.world_from_atmosphere)
  pbr_atmosphere_push_mat4_words(words, self.atmosphere_from_world)
  pbr_atmosphere_u32le_pack(words)
}

///|
pub fn GpuAtmosphereSettings::GpuAtmosphereSettings() -> GpuAtmosphereSettings {
  GpuAtmosphereSettings::{
    transmittance_lut_size: @math.UVec2::new(256, 128),
    multiscattering_lut_size: @math.UVec2::new(32, 32),
    sky_view_lut_size: @math.UVec2::new(400, 200),
    aerial_view_lut_size: (@math.UVec2::new(32, 32), 32),
    transmittance_lut_samples: 40,
    multiscattering_lut_dirs: 64,
    multiscattering_lut_samples: 20,
    sky_view_lut_samples: 16,
    aerial_view_lut_samples: 10,
    aerial_view_lut_max_distance: 32_000.0F,
    sky_max_samples: 16,
    rendering_method: 0,
  }
}

///|
fn pbr_atmosphere_mode_to_u32(rendering_method : Int) -> UInt {
  if rendering_method <= 0 {
    0U
  } else {
    rendering_method.reinterpret_as_uint()
  }
}

///|
pub fn GpuAtmosphereSettings::as_uniform_bytes(
  self : GpuAtmosphereSettings,
  textures : AtmosphereTextures,
) -> Bytes {
  pbr_atmosphere_u32le_pack([
    textures.transmittance_lut.width.reinterpret_as_uint(),
    textures.transmittance_lut.height.reinterpret_as_uint(),
    textures.multiscattering_lut.width.reinterpret_as_uint(),
    textures.multiscattering_lut.height.reinterpret_as_uint(),
    textures.sky_view_lut.width.reinterpret_as_uint(),
    textures.sky_view_lut.height.reinterpret_as_uint(),
    0U,
    0U,
    textures.aerial_view_lut.width.reinterpret_as_uint(),
    textures.aerial_view_lut.height.reinterpret_as_uint(),
    textures.aerial_view_lut.depth_or_array_layers.reinterpret_as_uint(),
    self.transmittance_lut_samples.reinterpret_as_uint(),
    self.multiscattering_lut_dirs.reinterpret_as_uint(),
    self.multiscattering_lut_samples.reinterpret_as_uint(),
    self.sky_view_lut_samples.reinterpret_as_uint(),
    self.aerial_view_lut_samples.reinterpret_as_uint(),
    pbr_atmosphere_f32_bits(self.aerial_view_lut_max_distance),
    self.sky_max_samples.reinterpret_as_uint(),
    pbr_atmosphere_mode_to_u32(self.rendering_method),
    0U,
  ])
}

///|
pub(all) enum AtmosphereTextureDimension {
  D2
  D3
} derive(Eq, Debug)

///|
pub(all) enum AtmosphereTextureFormat {
  Rgba16Float
} derive(Eq, Debug)

///|
pub struct AtmosphereTextureDescriptor {
  width : Int
  height : Int
  depth_or_array_layers : Int
  dimension : AtmosphereTextureDimension
  format : AtmosphereTextureFormat
  storage_binding : Bool
  texture_binding : Bool
}

///|
pub fn AtmosphereTextureDescriptor::new(
  width : Int,
  height : Int,
  depth_or_array_layers : Int,
  dimension : AtmosphereTextureDimension,
) -> AtmosphereTextureDescriptor {
  AtmosphereTextureDescriptor::{
    width: if width <= 0 {
      1
    } else {
      width
    },
    height: if height <= 0 {
      1
    } else {
      height
    },
    depth_or_array_layers: if depth_or_array_layers <= 0 {
      1
    } else {
      depth_or_array_layers
    },
    dimension,
    format: AtmosphereTextureFormat::Rgba16Float,
    storage_binding: true,
    texture_binding: true,
  }
}

///|
pub struct AtmosphereTextures {
  transmittance_lut : AtmosphereTextureDescriptor
  multiscattering_lut : AtmosphereTextureDescriptor
  sky_view_lut : AtmosphereTextureDescriptor
  aerial_view_lut : AtmosphereTextureDescriptor
}

///|
pub fn AtmosphereTextures::from_settings(
  settings : GpuAtmosphereSettings,
) -> AtmosphereTextures {
  AtmosphereTextures::{
    transmittance_lut: AtmosphereTextureDescriptor::new(
      settings.transmittance_lut_size.x,
      settings.transmittance_lut_size.y,
      1,
      AtmosphereTextureDimension::D2,
    ),
    multiscattering_lut: AtmosphereTextureDescriptor::new(
      settings.multiscattering_lut_size.x,
      settings.multiscattering_lut_size.y,
      1,
      AtmosphereTextureDimension::D2,
    ),
    sky_view_lut: AtmosphereTextureDescriptor::new(
      settings.sky_view_lut_size.x,
      settings.sky_view_lut_size.y,
      1,
      AtmosphereTextureDimension::D2,
    ),
    aerial_view_lut: AtmosphereTextureDescriptor::new(
      settings.aerial_view_lut_size.0.x,
      settings.aerial_view_lut_size.0.y,
      settings.aerial_view_lut_size.1,
      AtmosphereTextureDimension::D3,
    ),
  }
}

///|
pub fn pbr_gpu_atmosphere_settings(
  settings : AtmosphereSettings,
) -> GpuAtmosphereSettings {
  GpuAtmosphereSettings::{
    transmittance_lut_size: settings.transmittance_lut_size,
    multiscattering_lut_size: settings.multiscattering_lut_size,
    sky_view_lut_size: settings.sky_view_lut_size,
    aerial_view_lut_size: settings.aerial_view_lut_size,
    transmittance_lut_samples: settings.transmittance_lut_samples,
    multiscattering_lut_dirs: settings.multiscattering_lut_dirs,
    multiscattering_lut_samples: settings.multiscattering_lut_samples,
    sky_view_lut_samples: settings.sky_view_lut_samples,
    aerial_view_lut_samples: settings.aerial_view_lut_samples,
    aerial_view_lut_max_distance: settings.aerial_view_lut_max_distance,
    sky_max_samples: settings.sky_max_samples,
    rendering_method: pbr_atmosphere_mode_to_int(settings.rendering_method),
  }
}

///|
fn pbr_atmosphere_mode_to_int(mode : AtmosphereMode) -> Int {
  match mode {
    LookupTexture => 0
    Raymarched => 1
  }
}

///|
pub fn pbr_atmosphere_settings_default() -> AtmosphereSettings {
  AtmosphereSettings()
}

///|
pub fn pbr_atmosphere_settings_with_sky_max_samples(
  settings : AtmosphereSettings,
  sky_max_samples : Int,
) -> AtmosphereSettings {
  settings.with_sky_max_samples(sky_max_samples)
}

///|
pub fn pbr_atmosphere_settings_with_rendering_method(
  settings : AtmosphereSettings,
  rendering_method : AtmosphereMode,
) -> AtmosphereSettings {
  settings.with_rendering_method(rendering_method)
}
