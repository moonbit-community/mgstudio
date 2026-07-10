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
test "mesh3d: irradiance volume key ignores padded fallback texture ids" {
  debug_inspect(
    mesh3d_irradiance_volume_texture_ids_have_loaded_texture([]),
    content="false",
  )
  debug_inspect(
    mesh3d_irradiance_volume_texture_ids_have_loaded_texture([-1, -1, -1]),
    content="false",
  )
  debug_inspect(
    mesh3d_irradiance_volume_texture_ids_have_loaded_texture([-1, 27, -1]),
    content="true",
  )
}
