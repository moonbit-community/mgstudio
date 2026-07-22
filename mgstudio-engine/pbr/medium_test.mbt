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
test "pbr medium: default sampler is linear clamp" {
  inspect(
    ScatteringMediumSampler::ScatteringMediumSampler().is_linear_clamp(),
    content="true",
  )
}

///|
fn medium_approx_eq(a : Float, b : Float) -> Bool {
  (a - b).abs() < 0.000001F
}

///|
test "pbr medium: gpu medium LUT lengths follow source medium" {
  let gpu_medium = GpuScatteringMedium::new(
    ScatteringMedium::earth(8, 4),
    ScatteringMediumSampler(),
  )
  inspect(gpu_medium.density_lut_len(), content="16")
  inspect(gpu_medium.scattering_lut_len(), content="32")
  inspect(gpu_medium.density_lut_rgba32f_bytes().length(), content="256")
  inspect(gpu_medium.scattering_lut_rgba32f_bytes().length(), content="512")
}

///|
test "pbr medium: gpu medium LUT samples source terms" {
  let medium = ScatteringMedium::new(1, 1, [
    @light.ScatteringTerm::new(
      @math.Vec3::new(2.0F, 3.0F, 4.0F),
      @math.Vec3::new(5.0F, 6.0F, 7.0F),
      @light.Falloff::linear(),
      @light.PhaseFunction::isotropic(),
    ),
  ])
  let gpu_medium = GpuScatteringMedium::new(medium, ScatteringMediumSampler())
  let density = gpu_medium.density_lut()
  let scattering = gpu_medium.scattering_lut()
  inspect(medium_approx_eq(density[0].x, 1.0F), content="true")
  inspect(medium_approx_eq(density[0].y, 1.5F), content="true")
  inspect(medium_approx_eq(density[0].z, 2.0F), content="true")
  inspect(medium_approx_eq(density[1].x, 2.5F), content="true")
  inspect(medium_approx_eq(density[1].y, 3.0F), content="true")
  inspect(medium_approx_eq(density[1].z, 3.5F), content="true")
  let isotropic_at_half_falloff = 0.5F * 0.25F / @math.pi()
  inspect(
    medium_approx_eq(scattering[0].x, 5.0F * isotropic_at_half_falloff),
    content="true",
  )
  inspect(
    medium_approx_eq(scattering[0].y, 6.0F * isotropic_at_half_falloff),
    content="true",
  )
  inspect(
    medium_approx_eq(scattering[0].z, 7.0F * isotropic_at_half_falloff),
    content="true",
  )
}

///|
test "pbr medium: chromatic phase curve contributes per-channel scattering" {
  let phase = @light.SampledVec3Curve::new(-1.0F, 1.0F, [
    @math.Vec3::new(1.0F, 2.0F, 3.0F),
    @math.Vec3::new(1.0F, 2.0F, 3.0F),
  ])
  let medium = ScatteringMedium::new(1, 1, [
    @light.ScatteringTerm::new(
      @math.Vec3::zero(),
      @math.Vec3::new(2.0F, 3.0F, 4.0F),
      @light.Falloff::linear(),
      @light.PhaseFunction::from_chromatic_curve(phase),
    ),
  ])
  let gpu_medium = GpuScatteringMedium::new(medium, ScatteringMediumSampler())
  let scattering = gpu_medium.scattering_lut()
  inspect(medium_approx_eq(scattering[0].x, 1.0F), content="true")
  inspect(medium_approx_eq(scattering[0].y, 3.0F), content="true")
  inspect(medium_approx_eq(scattering[0].z, 6.0F), content="true")
}
