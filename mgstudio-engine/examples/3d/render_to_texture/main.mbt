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
/// Port of `bevy/examples/3d/render_to_texture.rs`.

///|
const PI : Float = 3.141592653589793F

///|
priv struct RenderToTextureState {
  mut first_pass_cube : @core.Entity
  mut main_pass_cube : @core.Entity
}

///|
let render_to_texture_state : Ref[RenderToTextureState] = Ref::new({
  first_pass_cube: @core.Entity::placeholder(),
  main_pass_cube: @core.Entity::placeholder(),
})

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  render_to_texture_state.val.first_pass_cube = @core.Entity::placeholder()
  render_to_texture_state.val.main_pass_cube = @core.Entity::placeholder()

  let image = @render2d.render2d_create_render_target(world, 512, 512, true)
  let first_pass_layer = @render2d.RenderLayers::layer(1)

  let first_pass_cube = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(4.0F, 4.0F, 4.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(0.8F, 0.7F, 0.6F, 1.0F),
        ),
      ),
    ),
    @math.Transform::from_xyz(0.0F, 0.0F, 1.0F),
  ).spawn(world)
  world
  .get_render_layers_store()
  .insert(first_pass_cube, first_pass_layer, tick)
  render_to_texture_state.val.first_pass_cube = first_pass_cube

  let light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(light, @render3d.PointLight::default(), tick)
  world
  .get_transform_store()
  .insert(light, @math.Transform::from_xyz(0.0F, 0.0F, 10.0F), tick)

  let first_pass_camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::new(@render2d.Color::white()).with_order(-1),
    @math.Transform::from_xyz(0.0F, 0.0F, 15.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world
  .get_render_target_store()
  .insert(first_pass_camera, @render2d.RenderTarget::Image(image), tick)
  world
  .get_render_layers_store()
  .insert(first_pass_camera, first_pass_layer, tick)

  let main_pass_cube = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(4.0F, 4.0F, 4.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(@render2d.Color::white()).with_base_color_texture(
          Some(image),
        ),
      ),
    ),
    @math.Transform::from_xyz(0.0F, 0.0F, 1.5F).with_rotation(
      @math.Quat::from_rotation_x(-PI / 5.0F),
    ),
  ).spawn(world)
  render_to_texture_state.val.main_pass_cube = main_pass_cube

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.0F, 0.0F, 15.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn rotator_system(world : @ecs_world.World) -> Unit {
  if render_to_texture_state.val.first_pass_cube.is_placeholder() {
    return
  }
  let tick = world.read_change_tick()
  let transform_store = world.get_transform_store()
  if transform_store.get(render_to_texture_state.val.first_pass_cube)
    is Some(transform) {
    let delta = @time.time_delta_seconds()
    let rotation = transform.rotation
      .mul(@math.Quat::from_rotation_x(1.5F * delta))
      .mul(@math.Quat::from_rotation_z(1.3F * delta))
      .normalize()
    transform_store.set(
      render_to_texture_state.val.first_pass_cube,
      transform.with_rotation(rotation),
      tick,
    )
    |> ignore
  }
}

///|
fn cube_rotator_system(world : @ecs_world.World) -> Unit {
  if render_to_texture_state.val.main_pass_cube.is_placeholder() {
    return
  }
  let tick = world.read_change_tick()
  let transform_store = world.get_transform_store()
  if transform_store.get(render_to_texture_state.val.main_pass_cube)
    is Some(transform) {
    let delta = @time.time_delta_seconds()
    let rotation = transform.rotation
      .mul(@math.Quat::from_rotation_x(1.0F * delta))
      .mul(@math.Quat::from_rotation_y(0.7F * delta))
      .normalize()
    transform_store.set(
      render_to_texture_state.val.main_pass_cube,
      transform.with_rotation(rotation),
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
  .add_system(cube_rotator_system)
  .add_system(rotator_system)
  .run()
}
