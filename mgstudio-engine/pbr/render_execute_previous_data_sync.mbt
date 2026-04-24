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
fn render3d_entity_global_transform_from_main_world(
  world : @ecs.World,
  entity : @core.Entity,
) -> @transform.GlobalTransform? {
  try! world.get_by_key(entity, @transform.ecs_key_global_transform)
}

///|
fn update_previous_view_data(world : @ecs.World) -> Unit {
  guard standard_material_prepass_enabled(world) else { return }
  world.for_each_component(ecs_key_camera3d, fn(entity, _camera3d) {
    let world_transform = match
      render3d_entity_global_transform_from_main_world(world, entity) {
      Some(value) => value
      None => return
    }
    let projection = match (try! world.get_by_key(entity, ecs_key_projection)) {
      Some(value) => value
      None => Projection::default()
    }
    let view_from_world = @pbr_render.render3d_view_from_world_matrix(
      world_transform.compute_transform(),
    )
    let clip_from_world = projection.get_clip_from_view().mul(view_from_world)
    try! world.set_by_key(
      entity,
      ecs_key_previous_view_data,
      @pbr_prepass.PreviousViewData::new(
        world_transform.compute_transform(), clip_from_world,
      ),
    )
  })
}

///|
fn render3d_has_active_camera(world : @ecs.World) -> Bool {
  let mut active = false
  world.for_each_component(ecs_key_camera3d, fn(entity, _camera3d) {
    let camera = match (try! world.get_by_key(entity, @sprite.ecs_key_camera)) {
      Some(value) => value
      None => @sprite.Camera::default()
    }
    if camera.is_active {
      active = true
    }
  })
  active
}

///|
fn update_mesh_previous_global_transforms(world : @ecs.World) -> Unit {
  guard standard_material_prepass_enabled(world) else { return }
  guard render3d_has_active_camera(world) else { return }
  world.for_each_component(ecs_key_mesh3d, fn(entity, _mesh3d) {
    let world_transform = match
      render3d_entity_global_transform_from_main_world(world, entity) {
      Some(value) => value
      None => return
    }
    try! world.set_by_key(
      entity,
      ecs_key_previous_global_transform,
      @pbr_prepass.PreviousGlobalTransform::from_global_transform(
        world_transform,
      ),
    )
  })
}
