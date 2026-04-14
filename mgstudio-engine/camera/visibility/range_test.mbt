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
fn spawn_camera_entity(
  world : @ecs.World,
  x : Float,
  y : Float,
  z : Float,
) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(x, y, z),
    ),
  )
  try! world.set_by_key(
    entity,
    @sprite.ecs_key_camera,
    @sprite.Camera::default(),
  )
  entity
}

///|
fn spawn_visibility_entity(
  world : @ecs.World,
  x : Float,
  y : Float,
  z : Float,
  visibility_range : @root_visibility.VisibilityRange,
) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(x, y, z),
    ),
  )
  try! world.set_by_key(
    entity, @root_visibility.ecs_key_visibility_range, visibility_range,
  )
  entity
}

///|
test "camera visibility range: entity in range of camera" {
  let world = @ecs.World::new()
  world.insert_resource(
    ecs_key_visible_entity_ranges,
    VisibleEntityRanges::default(),
  )
  let camera = spawn_camera_entity(world, 0.0F, 0.0F, 0.0F)
  let mesh = spawn_visibility_entity(
    world,
    0.0F,
    0.0F,
    5.0F,
    @root_visibility.VisibilityRange::abrupt(0.0F, 10.0F),
  )
  check_visibility_ranges(world)
  let ranges = (world.get_resource(ecs_key_visible_entity_ranges) catch {
    _ => None
  }).unwrap()
  debug_inspect(ranges.entity_is_in_range_of_view(mesh, camera), content="true")
  debug_inspect(ranges.entity_is_in_range_of_any_view(mesh), content="true")
}

///|
test "camera visibility range: entity out of range of camera" {
  let world = @ecs.World::new()
  world.insert_resource(
    ecs_key_visible_entity_ranges,
    VisibleEntityRanges::default(),
  )
  let camera = spawn_camera_entity(world, 0.0F, 0.0F, 0.0F)
  let mesh = spawn_visibility_entity(
    world,
    0.0F,
    0.0F,
    25.0F,
    @root_visibility.VisibilityRange::abrupt(0.0F, 10.0F),
  )
  check_visibility_ranges(world)
  let ranges = (world.get_resource(ecs_key_visible_entity_ranges) catch {
    _ => None
  }).unwrap()
  debug_inspect(
    ranges.entity_is_in_range_of_view(mesh, camera),
    content="false",
  )
  debug_inspect(ranges.entity_is_in_range_of_any_view(mesh), content="false")
}

///|
test "camera visibility range: use_aabb uses transformed aabb center" {
  let world = @ecs.World::new()
  world.insert_resource(
    ecs_key_visible_entity_ranges,
    VisibleEntityRanges::default(),
  )
  let camera = spawn_camera_entity(world, 0.0F, 0.0F, 0.0F)
  let mesh = spawn_visibility_entity(
    world,
    100.0F,
    0.0F,
    0.0F,
    @root_visibility.VisibilityRange::new(0.0F, 0.0F, 5.0F, 5.0F, true),
  )
  try! world.set_by_key(
    mesh,
    @camera_primitives.ecs_key_aabb,
    @camera_primitives.Aabb::from_min_max(
      @math.Vec3::new(-100.5F, 0.0F, 0.0F),
      @math.Vec3::new(-99.5F, 0.0F, 0.0F),
    ),
  )
  check_visibility_ranges(world)
  let ranges = (world.get_resource(ecs_key_visible_entity_ranges) catch {
    _ => None
  }).unwrap()
  debug_inspect(ranges.entity_is_in_range_of_view(mesh, camera), content="true")
}
