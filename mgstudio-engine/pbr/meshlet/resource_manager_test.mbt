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
test "pbr/meshlet: resource manager keeps per-view depth pyramids" {
  let manager = ResourceManager::new(8)
  debug_inspect(manager.cluster_buffer_slots(), content="8")
  debug_inspect(manager.cull_queue_rightmost_slot(), content="7")

  manager.set_previous_depth_pyramid(100, 200)
  manager.set_previous_depth_pyramid(101, 201)
  debug_inspect(manager.previous_depth_pyramid(100), content="Some(200)")

  manager.clear_stale_previous_depth_pyramids([101])
  debug_inspect(manager.previous_depth_pyramid(100), content="None")
  debug_inspect(manager.previous_depth_pyramid(101), content="Some(201)")
}

///|
test "pbr/meshlet: per-frame prepare updates counters" {
  let manager = ResourceManager::new(4)
  prepare_meshlet_per_frame_resources(manager, 32)
  debug_inspect(manager.frame_index(), content="1")
  debug_inspect(manager.meshlet_buffer_count(), content="32")
}
