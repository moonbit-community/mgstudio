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
test "pbr medium: gpu medium LUT lengths follow config" {
  let config = ScatteringMediumLutConfig::ScatteringMediumLutConfig()
    .with_falloff_resolution(8)
    .with_phase_resolution(4)
  let runtime = ScatteringMediumRuntime::ScatteringMediumRuntime().with_lut_config(
    config,
  )
  let gpu_medium = GpuScatteringMedium::new(
    runtime,
    ScatteringMediumSampler::ScatteringMediumSampler(),
  )
  inspect(gpu_medium.density_lut_len(), content="16")
  inspect(gpu_medium.scattering_lut_len(), content="32")
  inspect(gpu_medium.density_lut_rgba32f_bytes().length(), content="256")
  inspect(gpu_medium.scattering_lut_rgba32f_bytes().length(), content="512")
}

///|
test "pbr medium: source density multiplier reaches GPU LUT" {
  let medium = ScatteringMedium::earthlike().with_density_multiplier(2.0F)
  let runtime = ScatteringMediumRuntime::from_medium(medium).with_lut_config(
    ScatteringMediumLutConfig::ScatteringMediumLutConfig()
    .with_falloff_resolution(1)
    .with_phase_resolution(1),
  )
  let gpu_medium = GpuScatteringMedium::new(
    runtime,
    ScatteringMediumSampler::ScatteringMediumSampler(),
  )
  inspect(gpu_medium.density_lut()[0].x, content="1")
  inspect(gpu_medium.scattering_lut()[0].x, content="0.5")
}
