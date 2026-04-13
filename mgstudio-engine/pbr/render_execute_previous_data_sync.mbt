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
fn render3d_sync_previous_view_data(
  source_world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
  prepared_camera_queues : Array[Render3dPreparedCameraQueue?],
) -> Unit {
  let camera_count = if cameras.length() < prepared_camera_queues.length() {
    cameras.length()
  } else {
    prepared_camera_queues.length()
  }
  for camera_index in 0..<camera_count {
    match prepared_camera_queues[camera_index] {
      Some(prepared_queue) => {
        let extracted_camera = cameras[camera_index]
        let clip_from_world = @pbr_render.render3d_pass_projection_clip_from_world(
          prepared_queue.camera_pass_projection,
          extracted_camera.payload.transform,
        )
        try! source_world.set_by_key(
          extracted_camera.entity.main_entity,
          ecs_key_previous_view_data,
          @pbr_prepass.PreviousViewData::new(
            extracted_camera.payload.transform,
            clip_from_world,
          ),
        )
      }
      None => ()
    }
  }
}

///|
fn render3d_sync_previous_global_transforms_for_all_meshes(
  world : @ecs.World,
  source_world : @ecs.World,
) -> Unit {
  let world_transform_cache_ref = @pbr_render.render3d_world_transform_cache_ref(
    world,
  )
  let mesh_sync_query : @ecs.Query[
    (
      @ecs.Comp[Mesh3d],
      @ecs.Comp[@transform.Transform],
    ),
    @ecs.All,
  ] = @ecs.query(source_world)
  try! mesh_sync_query.view(fn(entity, data) {
    let (_mesh3d_comp, local_transform_comp) = data
    let world_transform = @pbr_render.render3d_entity_world_transform_from_components(
      source_world,
      entity,
      local_transform_comp.value(),
      world_transform_cache_ref,
    )
    try! source_world.set_by_key(
      entity,
      ecs_key_previous_global_transform,
      @pbr_prepass.PreviousGlobalTransform::new(world_transform),
    )
  })
}

///|
fn render3d_sync_previous_frame_components(
  world : @ecs.World,
  source_world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
  prepared_camera_queues : Array[Render3dPreparedCameraQueue?],
) -> Unit {
  render3d_sync_previous_view_data(
    source_world,
    cameras,
    prepared_camera_queues,
  )
  render3d_sync_previous_global_transforms_for_all_meshes(world, source_world)
}
