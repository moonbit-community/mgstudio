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
/// Port of `bevy/examples/3d/3d_viewport_to_world.rs`.

///|
priv struct ViewportToWorld3dState {
  mut camera : @core.Entity?
  mut cursor : @core.Entity?
}

///|
let viewport_to_world_3d_state : Ref[ViewportToWorld3dState] = Ref::new({
  camera: None,
  cursor: None,
})

///|
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn ray_plane_intersection_ground(
  origin : @math.Vec3,
  direction : @math.Vec3,
) -> @math.Vec3? {
  if absf(direction.y) <= 1.0e-6F {
    return None
  }
  let t = -origin.y / direction.y
  if t < 0.0F {
    return None
  }
  Some(origin.add(direction.mul_scalar(t)))
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()

  let ground = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(20.0F, 20.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(0.3F, 0.5F, 0.3F, 1.0F),
        ),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  ground |> ignore

  let light = world.spawn_empty()
  world
  .get_directional_light_store()
  .insert(light, @render3d.DirectionalLight::default(), tick)
  world
  .get_transform_store()
  .insert(
    light,
    @math.Transform::from_xyz(1.0F, 1.0F, 1.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(15.0F, 5.0F, 15.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  viewport_to_world_3d_state.val.camera = Some(camera)

  let cursor = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(0.2F, 0.02F, 0.2F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(@render2d.Color::white()),
      ),
    ),
    @math.Transform::from_xyz(0.0F, 0.01F, 0.0F),
  ).spawn(world)
  viewport_to_world_3d_state.val.cursor = Some(cursor)
}

///|
fn draw_cursor(world : @ecs_world.World) -> Unit {
  guard viewport_to_world_3d_state.val.camera is Some(camera_entity) else {
    return
  }
  guard viewport_to_world_3d_state.val.cursor is Some(cursor_entity) else {
    return
  }
  guard @input.mouse_position() is Some(screen_pos) else { return }

  let transform_store = world.get_transform_store()
  guard transform_store.get(camera_entity) is Some(camera_transform) else {
    return
  }
  let camera_store = world.get_camera_store()
  guard camera_store.get(camera_entity) is Some(camera) else { return }
  let projection_store = world.get_camera_projection3d_store()
  guard projection_store.get(camera_entity) is Some(projection) else { return }
  let target_size = @math.IVec2::new(
    @window.window_width(),
    @window.window_height(),
  )
  let scale_factor = @window.window_scale_factor()

  guard @render3d.render3d_camera_viewport_to_world_ray(
      screen_pos, camera, projection, camera_transform, target_size, scale_factor,
    )
    is Some((ray_origin, ray_dir)) else {
    return
  }
  guard ray_plane_intersection_ground(ray_origin, ray_dir) is Some(point) else {
    return
  }

  let tick = world.read_change_tick()
  transform_store.set(
    cursor_entity,
    @math.Transform::from_xyz(point.x, point.y + 0.01F, point.z),
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
  .add_system(draw_cursor)
  .run()
}
