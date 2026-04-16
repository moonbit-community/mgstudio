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
test "camera plugin: installs visibility and visibility-range plugins" {
  let mut app = @app.App::new(@ecs.World::new()).add_plugins(
    CameraPlugin::default(),
  )
  debug_inspect(
    app.contains_resource(@camera_visibility.ecs_key_visible_entity_ranges),
    content="true",
  )

  let world = app.world()
  let entity = world.spawn()
  try! world.set(entity, @camera_visibility.default_visibility())
  let (_visibility_key, inherited_visibility_key, view_visibility_key) = @camera_visibility.visibility_component_keys()
  debug_inspect(
    try! (world.get_by_key(entity, inherited_visibility_key) is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(entity, view_visibility_key) is Some(_)),
    content="true",
  )

  app = app.update()
  debug_inspect(
    try! (app
    .world()
    .get_resource(@camera_visibility.ecs_key_visible_entity_ranges)
    is Some(_)),
    content="true",
  )
}

///|
test "camera projection plugin: updates frustum when transform changes" {
  let mut app = @app.App::new(@ecs.World::new()).add_plugins(
    CameraProjectionPlugin::default(),
  )
  let world = app.world()
  let entity = world.spawn()
  let projection = @pbr.Projection::default()
  let transform = @transform.Transform::identity()
  let initial_frustum = projection.compute_frustum(transform)
  try! world.set_by_key(entity, @pbr.ecs_key_projection, projection)
  try! world.set_by_key(entity, @transform.ecs_key_transform, transform)
  try! world.set_by_key(entity, @pbr.ecs_key_frustum, initial_frustum)

  let moved_transform = @transform.Transform::from_xyz(2.0F, 0.0F, 0.0F)
  try! (world.replace(entity, @transform.ecs_key_transform, moved_transform)
  |> ignore)
  app = app.update()

  let frustum_after_transform : @pbr.Frustum? = try! app
    .world()
    .get_by_key(entity, @pbr.ecs_key_frustum)
  let expected_after_transform = projection.compute_frustum(moved_transform)
  let frustum_after_transform_ok = match frustum_after_transform {
    Some(frustum) => frustum == expected_after_transform
    None => false
  }
  debug_inspect(frustum_after_transform_ok, content="true")
}
