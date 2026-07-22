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
  let lifecycle_world_15_0 = @ecs.World::new()
  defer lifecycle_world_15_0.close()
  let mut app = @app.App::new(lifecycle_world_15_0).add_plugins(
    CameraPlugin::CameraPlugin(),
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
    app.world().get_resource(@camera_visibility.ecs_key_visible_entity_ranges)
    is Some(_),
    content="true",
  )
}

///|
test "camera plugin: owns Camera3d color grading and exposure requirements" {
  let lifecycle_world_46_0 = @ecs.World::new()
  defer lifecycle_world_46_0.close()
  let app = @app.App::new(lifecycle_world_46_0).add_plugins(
    CameraPlugin::CameraPlugin(),
  )
  let world = app.world()
  let entity = world.spawn()
  try! world.set_by_key(entity, ecs_key_camera3d, Camera3d())

  debug_inspect(
    (try! world.get_by_key(entity, @post_process.ecs_key_color_grading))
    is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, @pbr.ecs_key_exposure)) is Some(_),
    content="true",
  )
}

///|
test "camera plugin: owns Camera2d authoring required components" {
  let lifecycle_world_66_0 = @ecs.World::new()
  defer lifecycle_world_66_0.close()
  let app = @app.App::new(lifecycle_world_66_0).add_plugins(
    CameraPlugin::CameraPlugin(),
  )
  let world = app.world()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @camera_components2d.ecs_key_camera2d,
    Camera2d(),
  )

  debug_inspect(
    (try! world.get_by_key(entity, @camera_camera.ecs_key_camera)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, @camera_projection2d.ecs_key_projection))
    is Some(_),
    content="true",
  )
  let camera2d_frustum : @camera_primitives.Frustum? = try! world.get_by_key(
    entity, @camera_primitives.ecs_key_frustum,
  )
  debug_inspect(
    camera2d_frustum.map(fn(frustum) { frustum.half_spaces.length() == 6 }),
    content="Some(true)",
  )
  debug_inspect(
    (try! world.get_by_key(entity, @transform.ecs_key_transform)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, @camera_camera.ecs_key_render_target))
    is Some(_),
    content="true",
  )
}

///|
test "camera plugin: owns Camera required components" {
  let lifecycle_world_106_0 = @ecs.World::new()
  defer lifecycle_world_106_0.close()
  let app = @app.App::new(lifecycle_world_106_0).add_plugins(
    CameraPlugin::CameraPlugin(),
  )
  let world = app.world()
  let entity = world.spawn()
  try! world.set_by_key(entity, @camera_camera.ecs_key_camera, Camera())

  debug_inspect(
    (try! world.get_by_key(entity, @camera_primitives.ecs_key_frustum))
    is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(
      entity, @camera_camera.ecs_key_camera_main_texture_usages,
    ))
    is Some(_),
    content="true",
  )
  let visible_entities = try! world.get_by_key(
    entity, @camera_camera.ecs_key_visible_entities,
  )
  let visible_entities_ok = match visible_entities {
    Some(visible) => visible.is_empty(@mesh.ecs_key_mesh3d.id())
    None => false
  }
  debug_inspect(visible_entities_ok, content="true")
  debug_inspect(
    (try! world.get_by_key(entity, @transform.ecs_key_transform)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, @visibility.ecs_key_visibility)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, @render.ecs_key_sync_to_render_world))
    is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, @camera_camera.ecs_key_render_target))
    is Some(_),
    content="true",
  )
}

///|
test "camera projection plugin: updates frustum when transform or projection changes" {
  let lifecycle_world_159_0 = @ecs.World::new()
  defer lifecycle_world_159_0.close()
  let mut app = @app.App::new(lifecycle_world_159_0).add_plugins(
    CameraProjectionPlugin::CameraProjectionPlugin(),
  )
  let world = app.world()
  let entity = world.spawn()
  let projection = @pbr.Projection::default()
  let transform = @transform.Transform::identity()
  let initial_frustum = projection.compute_frustum(transform)
  try! world.set_by_key(entity, @pbr.ecs_key_projection, projection)
  try! world.set_by_key(entity, @transform.ecs_key_transform, transform)
  try! world.set_by_key(
    entity, @camera_primitives.ecs_key_frustum, initial_frustum,
  )

  let moved_transform = @transform.Transform::from_xyz(2.0F, 0.0F, 0.0F)
  try! (world.replace(entity, @transform.ecs_key_transform, moved_transform)
  |> ignore)
  app = app.update()

  let frustum_after_transform : @camera_primitives.Frustum? = try! app
    .world()
    .get_by_key(entity, @camera_primitives.ecs_key_frustum)
  let expected_after_transform = projection.compute_frustum(moved_transform)
  let frustum_after_transform_ok = match frustum_after_transform {
    Some(frustum) => frustum == expected_after_transform
    None => false
  }
  debug_inspect(frustum_after_transform_ok, content="true")

  let updated_projection = @pbr.Projection::Perspective(
    @pbr.PerspectiveProjection3d::PerspectiveProjection3d().with_far(250.0F),
  )
  try! (app.world().replace(entity, @pbr.ecs_key_projection, updated_projection)
  |> ignore)
  app = app.update()

  let frustum_after_projection : @camera_primitives.Frustum? = try! app
    .world()
    .get_by_key(entity, @camera_primitives.ecs_key_frustum)
  let expected_after_projection = updated_projection.compute_frustum(
    moved_transform,
  )
  debug_inspect(
    frustum_after_projection == Some(expected_after_projection),
    content="true",
  )
}

///|
test "camera projection plugin: updates Camera2d frustum from logical viewport" {
  let lifecycle_world_199_0 = @ecs.World::new()
  defer lifecycle_world_199_0.close()
  let mut app = @app.App::new(lifecycle_world_199_0).add_plugins(
    CameraPlugin::CameraPlugin(),
  )
  let world = app.world()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @camera_components2d.ecs_key_camera2d,
    Camera2d(),
  )
  try! world.set_by_key(
    entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::identity(),
  )
  let camera = (try! world.get_by_key(entity, @camera_camera.ecs_key_camera)).unwrap()
  let computed = @camera_computed.ComputedCameraValues::new(
    @math.Mat4::identity(),
    Some(
      @camera_computed.RenderTargetInfo::new(@math.IVec2::new(1280, 720), 2.0F),
    ),
    None,
    None,
  )
  try! (world.replace(
    entity,
    @camera_camera.ecs_key_camera,
    camera.with_computed(computed),
  )
  |> ignore)

  app = app.update()

  let frustum = (try! app
  .world()
  .get_by_key(entity, @camera_primitives.ecs_key_frustum)).unwrap()
  let inside = @camera_primitives.Sphere::new(
    @math.Vec3::new(300.0F, 0.0F, 0.0F),
    1.0F,
  )
  let outside = @camera_primitives.Sphere::new(
    @math.Vec3::new(400.0F, 0.0F, 0.0F),
    1.0F,
  )
  debug_inspect(frustum.intersects_sphere(inside, false), content="true")
  debug_inspect(frustum.intersects_sphere(outside, false), content="false")
}

///|
test "camera projection plugin: Camera2d frustum matches uniform X render scale" {
  let lifecycle_world = @ecs.World::new()
  defer lifecycle_world.close()
  let mut app = @app.App::new(lifecycle_world).add_plugins(
    CameraPlugin::CameraPlugin(),
  )
  let world = app.world()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @camera_components2d.ecs_key_camera2d,
    Camera2d(),
  )
  let camera_transform = @transform.Transform::identity().with_scale(
    @math.Vec3::new(2.0F, 1.0F, 1.0F),
  )
  try! world.set_by_key(
    entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(camera_transform),
  )
  let camera = (try! world.get_by_key(entity, @camera_camera.ecs_key_camera)).unwrap()
  let computed = @camera_computed.ComputedCameraValues::new(
    @math.Mat4::identity(),
    Some(
      @camera_computed.RenderTargetInfo::new(@math.IVec2::new(100, 100), 1.0F),
    ),
    None,
    None,
  )
  try! (world.replace(
    entity,
    @camera_camera.ecs_key_camera,
    camera.with_computed(computed),
  )
  |> ignore)
  let projection = match
    (try! world.get_by_key(entity, @camera_projection2d.ecs_key_projection)).unwrap() {
    Orthographic(value) => value
  }
  let vertically_visible = @math.Vec2::new(0.0F, 75.0F)
  let vertically_hidden = @math.Vec2::new(0.0F, 125.0F)
  debug_inspect(
    camera.world_to_viewport_2d(
      camera_transform,
      vertically_visible,
      projection,
      @math.IVec2::new(100, 100),
      1.0F,
    )
    is Some(_),
    content="true",
  )
  debug_inspect(
    camera.world_to_viewport_2d(
      camera_transform,
      vertically_hidden,
      projection,
      @math.IVec2::new(100, 100),
      1.0F,
    )
    is Some(_),
    content="false",
  )

  app = app.update()

  let frustum = (try! app
  .world()
  .get_by_key(entity, @camera_primitives.ecs_key_frustum)).unwrap()
  let visible_sphere = @camera_primitives.Sphere::new(
    @math.Vec3::new(vertically_visible.x, vertically_visible.y, 0.0F),
    1.0F,
  )
  let hidden_sphere = @camera_primitives.Sphere::new(
    @math.Vec3::new(vertically_hidden.x, vertically_hidden.y, 0.0F),
    1.0F,
  )
  debug_inspect(
    frustum.intersects_sphere(visible_sphere, false),
    content="true",
  )
  debug_inspect(
    frustum.intersects_sphere(hidden_sphere, false),
    content="false",
  )
}
