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
  debug_inspect(manager.cull_queue_rightmost_slot(), content="3")
}

///|
test "pbr/meshlet: per-view bind groups are tracked by entity" {
  let manager = ResourceManager::new(4)
  let view_a = @core.Entity::new(0, 1)
  let view_b = @core.Entity::new(0, 2)
  ignore(prepare_meshlet_view_resources_for_view(manager, view_a, 5))
  ignore(
    prepare_meshlet_view_resources_for_view(
      manager,
      view_b,
      7,
      max_bvh_depth=3,
      view_width=1280,
      view_height=720,
    ),
  )
  debug_inspect(manager.prepared_view_resource_count(), content="2")
  debug_inspect(manager.prepared_not_shadow_view_count(), content="2")
  debug_inspect(manager.prepared_shadow_view_count(), content="0")
  debug_inspect(manager.prepared_material_depth_view_count(), content="2")
  debug_inspect(manager.prepared_max_bvh_depth(), content="3")
  manager.clear_stale_prepared_view_resources([view_a])
  debug_inspect(manager.prepared_view_resources(view_b) is None, content="true")
  let view_b_resources = manager.prepared_view_resources(view_b)
  let view_b_summary = match view_b_resources {
    Some(resources) =>
      (
        resources.scene_instance_count(),
        resources.rightmost_slot(),
        resources.max_bvh_depth(),
        resources.view_size(),
        resources.not_shadow_view(),
      )
    None => (-1, -1, -1, (-1, -1), false)
  }
  debug_inspect(view_b_summary, content="(7, 3, 3, (1280, 720), true)")
  ignore(prepare_meshlet_view_bind_groups_for_view(manager, view_a, 8))
  ignore(prepare_meshlet_view_bind_groups_for_view(manager, view_b, 4))
  debug_inspect(manager.prepared_view_bind_group_count(), content="2")
  manager.clear_stale_prepared_view_bind_groups([view_b])
  debug_inspect(
    manager.prepared_view_bind_groups(view_a) is None,
    content="true",
  )
  let view_b_bind_groups = manager.prepared_view_bind_groups(view_b)
  let bind_group_count = match view_b_bind_groups {
    Some(bind_groups) => bind_groups.bind_group_count
    None => -1
  }
  debug_inspect(bind_group_count, content="4")
}

///|
test "pbr/meshlet: resource manager separates camera and shadow view resources" {
  let manager = ResourceManager::new(16)
  let camera_view = @core.Entity::new(0, 10)
  let shadow_view = @core.Entity::new(0, 11)
  ignore(
    prepare_meshlet_view_resources_for_view(
      manager,
      camera_view,
      8,
      max_bvh_depth=2,
      not_shadow_view=true,
    ),
  )
  ignore(
    prepare_meshlet_view_resources_for_view(
      manager,
      shadow_view,
      8,
      max_bvh_depth=5,
      not_shadow_view=false,
    ),
  )
  debug_inspect(manager.prepared_view_resource_count(), content="2")
  debug_inspect(manager.prepared_not_shadow_view_count(), content="1")
  debug_inspect(manager.prepared_shadow_view_count(), content="1")
  debug_inspect(manager.prepared_material_depth_view_count(), content="1")
  debug_inspect(manager.prepared_max_bvh_depth(), content="5")
}
