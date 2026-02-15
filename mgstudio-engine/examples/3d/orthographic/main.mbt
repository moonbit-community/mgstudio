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
/// Port of `bevy/examples/3d/orthographic.rs`.

///|
const FIXED_VIEWPORT_HEIGHT : Float = 6.0F

///|
fn fixed_vertical_orthographic_projection() -> @render3d.Projection3d {
  let scale_factor = @window.window_scale_factor()
  let safe_scale_factor = if scale_factor <= 0.0F { 1.0F } else { scale_factor }
  let logical_height = Float::from_double(@window.window_height().to_double()) /
    safe_scale_factor
  let safe_logical_height = if logical_height <= 0.0F {
    // Keep startup behavior deterministic before first resize callback.
    720.0F
  } else {
    logical_height
  }
  let projection_scale = FIXED_VIEWPORT_HEIGHT / safe_logical_height
  @render3d.Projection3d::Orthographic(
    @render3d.OrthographicProjection3d::default().with_scale(projection_scale),
  )
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()

  @render3d.Camera3dBundle::new_with_projection(
    @render2d.Camera::default(),
    fixed_vertical_orthographic_projection(),
    @math.Transform::from_xyz(5.0F, 5.0F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(5.0F, 5.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(0.3F, 0.5F, 0.3F, 1.0F),
        ),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let cube_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.8F, 0.7F, 0.6F, 1.0F),
    ),
  )

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(1.5F, 0.5F, 1.5F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(1.5F, 0.5F, -1.5F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(-1.5F, 0.5F, 1.5F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(-1.5F, 0.5F, -1.5F),
  ).spawn(world)
  |> ignore

  let light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(light, @render3d.PointLight::default(), tick)
  world
  .get_transform_store()
  .insert(light, @math.Transform::from_xyz(3.0F, 8.0F, 5.0F), tick)
}

///|
fn sync_fixed_vertical_projection(world : @ecs_world.World) -> Unit {
  let projection = fixed_vertical_orthographic_projection()
  let tick = world.read_change_tick()
  let camera3d_store = world.get_camera3d_store()
  let projection_store = world.get_camera_projection3d_store()
  camera3d_store.for_each(fn(entity, _camera3d) {
    if projection_store.get(entity) is Some(current) {
      projection_store.insert(entity, current.with_projection(projection), tick)
    }
  })
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(sync_fixed_vertical_projection)
  .run()
}
