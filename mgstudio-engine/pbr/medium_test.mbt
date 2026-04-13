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
  inspect(ScatteringMediumSampler::default().is_linear_clamp(), content="true")
}

///|
test "pbr medium: gpu medium LUT lengths follow config" {
  let config = ScatteringMediumLutConfig::default()
    .with_falloff_resolution(8)
    .with_phase_resolution(4)
  let runtime = ScatteringMediumRuntime::default().with_lut_config(config)
  let gpu_medium = GpuScatteringMedium::new(
    runtime,
    ScatteringMediumSampler::default(),
  )
  inspect(gpu_medium.density_lut_len(), content="16")
  inspect(gpu_medium.scattering_lut_len(), content="32")
}
