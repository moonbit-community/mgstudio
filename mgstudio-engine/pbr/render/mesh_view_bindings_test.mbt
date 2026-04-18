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
fn has_binding(
  entries : Array[MeshViewBindGroupLayoutEntry],
  binding : Int,
) -> Bool {
  for entry in entries {
    if entry.binding == binding {
      return true
    }
  }
  false
}

///|
test "pbr/render: mesh_view layout base bindings follow bevy slots" {
  let key = mesh_view_layout_key(
    false, false, false, false, false, false, false, false,
  )
  let (main_entries, binding_array_entries) = render3d_mesh_view_layout_entries(
    true, true, key,
  )

  debug_inspect(has_binding(main_entries, 0), content="true")
  debug_inspect(has_binding(main_entries, 2), content="true")
  debug_inspect(has_binding(main_entries, 10), content="true")
  debug_inspect(has_binding(main_entries, 16), content="true")
  debug_inspect(has_binding(main_entries, 19), content="true")
  debug_inspect(has_binding(main_entries, 25), content="true")
  debug_inspect(has_binding(main_entries, 21), content="false")
  debug_inspect(has_binding(main_entries, 27), content="false")
  debug_inspect(has_binding(binding_array_entries, 2), content="true")
  debug_inspect(has_binding(binding_array_entries, 7), content="true")
}

///|
test "pbr/render: mesh_view layout optional bindings gated by key flags" {
  let key = mesh_view_layout_key(true, true, true, true, true, true, true, true)
  let (main_entries, binding_array_entries) = render3d_mesh_view_layout_entries(
    true, true, key,
  )

  debug_inspect(has_binding(main_entries, 21), content="true")
  debug_inspect(has_binding(main_entries, 22), content="true")
  debug_inspect(has_binding(main_entries, 23), content="true")
  debug_inspect(has_binding(main_entries, 24), content="true")
  debug_inspect(has_binding(main_entries, 27), content="true")
  debug_inspect(has_binding(main_entries, 31), content="true")
  debug_inspect(has_binding(main_entries, 32), content="true")
  debug_inspect(has_binding(main_entries, 35), content="true")
  debug_inspect(has_binding(binding_array_entries, 3), content="true")
  debug_inspect(has_binding(binding_array_entries, 5), content="true")
}

///|
test "pbr/render: mesh_view layout disables optional bind arrays when unusable" {
  let key = mesh_view_layout_key(
    false, false, false, false, false, true, false, false,
  )
  let (main_entries, binding_array_entries) = render3d_mesh_view_layout_entries(
    true,
    true,
    key,
    clustered_decals_usable=false,
    irradiance_volumes_usable=false,
    oit_supported=false,
  )

  debug_inspect(has_binding(main_entries, 27), content="false")
  debug_inspect(has_binding(binding_array_entries, 3), content="false")
  debug_inspect(has_binding(binding_array_entries, 5), content="false")
}
