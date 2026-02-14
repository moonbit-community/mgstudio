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
/// Port of `bevy/examples/3d/mirror.rs`.
///
/// Parity scope: align mirror camera reflection transform and near-clip
/// behavior with Bevy's mirror setup.

///|
const PI : Float = 3.141592653589793F

///|
priv struct MirrorState {
  mut animated_cube : @core.Entity
  mut main_camera : @core.Entity
  mut mirror_camera : @core.Entity
  mut mirror_plane : @core.Entity
}

///|
let mirror_state : Ref[MirrorState] = Ref::new({
  animated_cube: @core.Entity::placeholder(),
  main_camera: @core.Entity::placeholder(),
  mirror_camera: @core.Entity::placeholder(),
  mirror_plane: @core.Entity::placeholder(),
})

///|
fn normalize_or(value : @math.Vec3, fallback : @math.Vec3) -> @math.Vec3 {
  let normalized = value.normalize_or_zero()
  if normalized.length_squared() <= 0.0000001F {
    fallback
  } else {
    normalized
  }
}

///|
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
fn reflect_vector(value : @math.Vec3, normal : @math.Vec3) -> @math.Vec3 {
  value.sub(normal.mul_scalar(2.0F * value.dot(normal)))
}

///|
fn reflect_point(
  point : @math.Vec3,
  plane_point : @math.Vec3,
  plane_normal : @math.Vec3,
) -> @math.Vec3 {
  let offset = point.sub(plane_point)
  point.sub(plane_normal.mul_scalar(2.0F * offset.dot(plane_normal)))
}

///|
fn calculate_mirror_camera_transform_and_projection(
  main_camera_transform : @math.Transform,
  main_camera_projection : @render3d.PerspectiveProjection3d,
  mirror_transform : @math.Transform,
) -> (@math.Transform, @render3d.PerspectiveProjection3d) {
  let world_up = @math.Vec3::new(0.0F, 1.0F, 0.0F)
  let forward_axis = @math.Vec3::new(0.0F, 0.0F, -1.0F)

  let mirror_normal = normalize_or(
    quat_rotate_vec3(mirror_transform.rotation, world_up),
    world_up,
  )
  let reflected_translation = reflect_point(
    main_camera_transform.translation,
    mirror_transform.translation,
    mirror_normal,
  )
  let main_forward = normalize_or(
    quat_rotate_vec3(main_camera_transform.rotation, forward_axis),
    forward_axis,
  )
  let main_up = normalize_or(
    quat_rotate_vec3(main_camera_transform.rotation, world_up),
    world_up,
  )
  let reflected_forward = normalize_or(
    reflect_vector(main_forward, mirror_normal),
    forward_axis,
  )
  let reflected_up = normalize_or(
    reflect_vector(main_up, mirror_normal),
    world_up,
  )
  let reflected_target = reflected_translation.add(reflected_forward)
  let mirror_camera_transform = @math.Transform::from_xyz(
    reflected_translation.x,
    reflected_translation.y,
    reflected_translation.z,
  ).looking_at(reflected_target, reflected_up)

  let signed_distance = mirror_transform.translation
    .sub(main_camera_transform.translation)
    .dot(mirror_normal)
  let distance_to_mirror = if signed_distance < 0.0F {
    -signed_distance
  } else {
    signed_distance
  }
  let mirror_near = if distance_to_mirror > main_camera_projection.near {
    distance_to_mirror
  } else {
    main_camera_projection.near
  }
  let mirror_camera_projection = main_camera_projection.with_near(mirror_near)

  (mirror_camera_transform, mirror_camera_projection)
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  mirror_state.val.animated_cube = @core.Entity::placeholder()
  mirror_state.val.main_camera = @core.Entity::placeholder()
  mirror_state.val.mirror_camera = @core.Entity::placeholder()
  mirror_state.val.mirror_plane = @core.Entity::placeholder()

  let mirror_target = @render2d.render2d_create_render_target(
    world, 1024, 1024, true,
  )

  // Ground
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(400.0F, 400.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(0.23F, 0.34F, 0.23F, 1.0F),
        ),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  // Scene object(s) reflected in mirror.
  let cube_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.93F, 0.62F, 0.18F, 1.0F),
    ),
  )
  let animated_cube = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(30.0F, 30.0F, 30.0F),
    @render3d.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(-55.0F, 20.0F, -70.0F),
  ).spawn(world)
  mirror_state.val.animated_cube = animated_cube

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(22.0F, 50.0F, 22.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(0.33F, 0.56F, 0.87F, 1.0F),
        ),
      ),
    ),
    @math.Transform::from_xyz(-85.0F, 25.0F, 40.0F),
  ).spawn(world)
  |> ignore

  // Mirror plane.
  let mirror_transform = @math.Transform::from_xyz(-25.0F, 75.0F, 0.0F).with_rotation(
    @math.Quat::from_rotation_x(-PI / 2.0F),
  )
  let mirror_entity = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(300.0F, 150.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(@render2d.Color::black())
        .with_emissive(@render2d.Color::white())
        .with_emissive_texture(Some(mirror_target))
        .with_perceptual_roughness(0.0F)
        .with_metallic(1.0F),
      ),
    ),
    mirror_transform,
  ).spawn(world)
  mirror_state.val.mirror_plane = mirror_entity

  // Lighting.
  let light = world.spawn_empty()
  world
  .get_directional_light_store()
  .insert(
    light,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 8_000.0F, true),
    tick,
  )
  world
  .get_transform_store()
  .insert(
    light,
    @math.Transform::from_xyz(-85.0F, 40.0F, -200.0F).looking_at(
      @math.Vec3::new(-50.0F, 0.0F, 100.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  // Main camera.
  let main_camera_projection = @render3d.PerspectiveProjection3d::default()
  let main_camera_transform = @math.Transform::from_xyz(140.0F, 80.0F, 140.0F).looking_at(
    @math.Vec3::new(-20.0F, 40.0F, 0.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  let main_camera = @render3d.Camera3dBundle::new_with_projection(
    @render2d.Camera::default(),
    @render3d.Projection3d::Perspective(main_camera_projection),
    main_camera_transform,
  ).spawn(world)
  mirror_state.val.main_camera = main_camera

  // Mirror camera (renders to texture).
  let (mirror_camera_transform, mirror_camera_projection) = calculate_mirror_camera_transform_and_projection(
    main_camera_transform, main_camera_projection, mirror_transform,
  )
  let mirror_camera = @render3d.Camera3dBundle::new_with_projection(
    @render2d.Camera::new(@render2d.Color::black()).with_order(-1),
    @render3d.Projection3d::Perspective(mirror_camera_projection),
    mirror_camera_transform,
  ).spawn(world)
  world
  .get_render_target_store()
  .insert(mirror_camera, @render2d.RenderTarget::Image(mirror_target), tick)
  mirror_state.val.mirror_camera = mirror_camera
}

///|
fn rotate_cube(world : @ecs_world.World) -> Unit {
  if mirror_state.val.animated_cube.is_placeholder() {
    return
  }
  let tick = world.read_change_tick()
  let transform_store = world.get_transform_store()
  if transform_store.get(mirror_state.val.animated_cube) is Some(transform) {
    let delta = @time.time_delta_seconds()
    let next_rotation = transform.rotation
      .mul(@math.Quat::from_rotation_y(0.9F * delta))
      .mul(@math.Quat::from_rotation_x(0.4F * delta))
      .normalize()
    transform_store.set(
      mirror_state.val.animated_cube,
      transform.with_rotation(next_rotation),
      tick,
    )
    |> ignore
  }
}

///|
fn update_mirror_camera_on_main_camera_transform_change(
  world : @ecs_world.World,
) -> Unit {
  if mirror_state.val.main_camera.is_placeholder() ||
    mirror_state.val.mirror_camera.is_placeholder() ||
    mirror_state.val.mirror_plane.is_placeholder() {
    return
  }

  let transform_store = world.get_transform_store()
  guard transform_store.get(mirror_state.val.main_camera)
    is Some(main_camera_transform) else {
    return
  }
  guard transform_store.get(mirror_state.val.mirror_plane)
    is Some(mirror_transform) else {
    return
  }

  let projection_store = world.get_camera_projection3d_store()
  guard projection_store.get(mirror_state.val.main_camera)
    is Some(main_camera_projection_component) else {
    return
  }
  guard main_camera_projection_component.projection
    is Perspective(main_projection) else {
    return
  }

  let (mirror_camera_transform, mirror_camera_projection) = calculate_mirror_camera_transform_and_projection(
    main_camera_transform, main_projection, mirror_transform,
  )

  let tick = world.read_change_tick()
  transform_store.set(
    mirror_state.val.mirror_camera,
    mirror_camera_transform,
    tick,
  )
  |> ignore
  projection_store.set(
    mirror_state.val.mirror_camera,
    @render3d.CameraProjection3d::new(
      @render3d.Projection3d::Perspective(mirror_camera_projection),
    ),
    tick,
  )
  |> ignore
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(rotate_cube)
  .add_system(update_mirror_camera_on_main_camera_transform_change)
  .run()
}
