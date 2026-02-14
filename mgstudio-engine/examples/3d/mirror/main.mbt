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
/// Baseline parity: this keeps the core mirror pipeline (camera render target +
/// textured mirror plane) while simplifying Bevy's custom screen-space material
/// and full reflection-matrix camera model.

///|
const PI : Float = 3.141592653589793F

///|
priv struct MirrorState {
  mut animated_cube : @core.Entity
}

///|
let mirror_state : Ref[MirrorState] = Ref::new({
  animated_cube: @core.Entity::placeholder(),
})

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  mirror_state.val.animated_cube = @core.Entity::placeholder()

  let mirror_target = @render2d.render2d_create_render_target(
    world,
    1024,
    1024,
    true,
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
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(220.0F, 140.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(@render2d.Color::white())
        .with_base_color_texture(Some(mirror_target))
        .with_unlit(true),
      ),
    ),
    @math.Transform::from_xyz(0.0F, 70.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_z(-PI / 2.0F),
    ),
  ).spawn(world)
  |> ignore

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

  // Mirror camera (renders to texture).
  let mirror_camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::new(@render2d.Color::black()).with_order(-1),
    @math.Transform::from_xyz(-140.0F, 70.0F, 0.0F).looking_at(
      @math.Vec3::new(-55.0F, 20.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world
  .get_render_target_store()
  .insert(mirror_camera, @render2d.RenderTarget::Image(mirror_target), tick)

  // Main camera.
  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(140.0F, 80.0F, 140.0F).looking_at(
      @math.Vec3::new(-20.0F, 40.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
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
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(rotate_cube)
  .run()
}
