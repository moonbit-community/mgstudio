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
test "pbr atmosphere: gpu settings runtime override clamps invalid values" {
  let settings = pbr_gpu_atmosphere_settings_with_runtime(
    -1.0F,
    0,
    AtmosphereMode::LookupTexture,
  )
  inspect(settings.scene_units_to_m, content="1")
  inspect(settings.sky_max_samples, content="16")
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
  let atmosphere = Atmosphere::earthlike(@light.ScatteringMedium::earthlike())
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
