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
test "pbr atmosphere: gpu settings copy Bevy atmosphere settings fields" {
  let source = AtmosphereSettings::AtmosphereSettings()
    .with_transmittance_lut_size(@math.UVec2::new(64, 16))
    .with_multiscattering_lut_size(@math.UVec2::new(8, 4))
    .with_sky_view_lut_size(@math.UVec2::new(32, 12))
    .with_aerial_view_lut_size((@math.UVec2::new(6, 5), 4))
    .with_transmittance_lut_samples(3)
    .with_multiscattering_lut_dirs(7)
    .with_multiscattering_lut_samples(9)
    .with_sky_view_lut_samples(11)
    .with_aerial_view_lut_samples(13)
    .with_aerial_view_lut_max_distance(17.0F)
    .with_sky_max_samples(0)
    .with_rendering_method(AtmosphereMode::Raymarched)
  let settings = pbr_gpu_atmosphere_settings(source)
  inspect(settings.transmittance_lut_size.x, content="64")
  inspect(settings.transmittance_lut_size.y, content="16")
  inspect(settings.multiscattering_lut_size.x, content="8")
  inspect(settings.multiscattering_lut_size.y, content="4")
  inspect(settings.sky_view_lut_size.x, content="32")
  inspect(settings.sky_view_lut_size.y, content="12")
  inspect(settings.aerial_view_lut_size.0.x, content="6")
  inspect(settings.aerial_view_lut_size.0.y, content="5")
  inspect(settings.aerial_view_lut_size.1, content="4")
  inspect(settings.transmittance_lut_samples, content="3")
  inspect(settings.multiscattering_lut_dirs, content="7")
  inspect(settings.multiscattering_lut_samples, content="9")
  inspect(settings.sky_view_lut_samples, content="11")
  inspect(settings.aerial_view_lut_samples, content="13")
  inspect(settings.aerial_view_lut_max_distance, content="17")
  inspect(settings.sky_max_samples, content="0")
  inspect(
    match settings.rendering_method {
      AtmosphereMode::Raymarched => true
      _ => false
    },
    content="true",
  )
}

///|
test "pbr atmosphere: texture descriptors mirror bevy LUT resource shape" {
  let textures = AtmosphereTextures::from_settings(GpuAtmosphereSettings())
  inspect(textures.transmittance_lut.width, content="256")
  inspect(textures.transmittance_lut.height, content="128")
  inspect(textures.transmittance_lut.depth_or_array_layers, content="1")
  inspect(
    textures.transmittance_lut.dimension == AtmosphereTextureDimension::D2,
    content="true",
  )
  inspect(textures.multiscattering_lut.width, content="32")
  inspect(textures.multiscattering_lut.height, content="32")
  inspect(textures.sky_view_lut.width, content="400")
  inspect(textures.sky_view_lut.height, content="200")
  inspect(textures.aerial_view_lut.width, content="32")
  inspect(textures.aerial_view_lut.height, content="32")
  inspect(textures.aerial_view_lut.depth_or_array_layers, content="32")
  inspect(
    textures.aerial_view_lut.dimension == AtmosphereTextureDimension::D3,
    content="true",
  )
  inspect(
    textures.transmittance_lut.format == AtmosphereTextureFormat::Rgba16Float,
    content="true",
  )
  inspect(textures.transmittance_lut.storage_binding, content="true")
  inspect(textures.transmittance_lut.texture_binding, content="true")
}

///|
fn atmosphere_resource_test_approx_eq(lhs : Float, rhs : Float) -> Bool {
  (lhs - rhs).abs() < 0.000001F
}

///|
test "pbr atmosphere: gpu atmosphere maps source component radii and albedo" {
  let atmosphere = Atmosphere::earth(@light.ScatteringMedium::earthlike())
    .with_radii(10.0F, 20.0F)
    .with_ground_albedo(@math.Vec3::new(0.1F, 0.2F, 0.3F))
  let gpu = pbr_gpu_atmosphere(atmosphere, @math.Affine3::identity())
  inspect(
    atmosphere_resource_test_approx_eq(gpu.inner_radius, 10.0F),
    content="true",
  )
  inspect(
    atmosphere_resource_test_approx_eq(gpu.outer_radius, 20.0F),
    content="true",
  )
  inspect(
    atmosphere_resource_test_approx_eq(gpu.ground_albedo.x, 0.1F),
    content="true",
  )
  inspect(
    atmosphere_resource_test_approx_eq(gpu.ground_albedo.y, 0.2F),
    content="true",
  )
  inspect(
    atmosphere_resource_test_approx_eq(gpu.ground_albedo.z, 0.3F),
    content="true",
  )
}
