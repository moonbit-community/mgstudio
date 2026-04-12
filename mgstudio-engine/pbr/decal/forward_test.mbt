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
test "pbr decal forward: uniform inverse depth fade factor" {
  let uniform = pbr_forward_decal_material_ext_uniform(2.0F)
  inspect(uniform.inv_depth_fade_factor, content="0.5")
}

///|
test "pbr decal forward: specialized label prefix" {
  inspect(
    pbr_forward_decal_specialized_label("standard"),
    content="forward_decal_standard",
  )
}
