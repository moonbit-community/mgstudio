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
fn render3d_light_probe_wbtest_state(
  irradiance_volume_texture_ids : Array[Int],
) -> Render3dLightProbeState {
  {
    uniform_bytes: Bytes::from_array([]),
    uniform_offset: 0U,
    diffuse_texture_ids: [],
    specular_texture_ids: [],
    irradiance_volume_texture_ids,
  }
}

///|
test "pbr light probes: padded irradiance slots do not enable the pipeline key" {
  debug_inspect(
    render3d_light_probe_state_has_irradiance_volume(
      render3d_light_probe_wbtest_state([-1, -1, -1]),
    ),
    content="false",
  )
  debug_inspect(
    render3d_light_probe_state_has_irradiance_volume(
      render3d_light_probe_wbtest_state([-1, 35, -1]),
    ),
    content="true",
  )
}
