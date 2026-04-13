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
