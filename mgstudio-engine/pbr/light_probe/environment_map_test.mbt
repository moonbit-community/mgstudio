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
test "pbr light probe env map: array mode pads entries" {
  let entries = pbr_environment_map_bind_group_entries(
    [EnvironmentMapIds()],
    true,
    4,
  )
  let counts = pbr_environment_map_bind_group_entries_counts(entries)
  debug_inspect(counts, content="(4, 4)")
}

///|
test "pbr light probe env map: texture id entries select single mode" {
  let entries = pbr_environment_map_texture_id_entries(
    [11, 12],
    [21, 22],
    false,
    4,
  )
  let (diffuse_ids, specular_ids) = pbr_environment_map_texture_id_entries_ids(
    entries,
  )
  debug_inspect(diffuse_ids, content="[11]")
  debug_inspect(specular_ids, content="[21]")
}

///|
test "pbr light probe env map: texture id entries pad binding arrays" {
  let entries = pbr_environment_map_texture_id_entries([11, 12], [21], true, 4)
  let (diffuse_ids, specular_ids) = pbr_environment_map_texture_id_entries_ids(
    entries,
  )
  debug_inspect(diffuse_ids, content="[11, 12, -1, -1]")
  debug_inspect(specular_ids, content="[21, -1, -1, -1]")
}
