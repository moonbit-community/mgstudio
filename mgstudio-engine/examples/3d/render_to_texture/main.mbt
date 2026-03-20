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
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  render_to_texture_state.val.first_pass_cube = @core.Entity::placeholder()
  render_to_texture_state.val.main_pass_cube = @core.Entity::placeholder()

  let image = @sprite_render.render2d_create_render_target(
    world, 512, 512, true,
  )
  let first_pass_layer = @sprite.RenderLayers::layer(1)

  let first_pass_cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_cuboid(4.0F, 4.0F, 4.0F),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::new(0.8F, 0.7F, 0.6F, 1.0F),
        ).with_reflectance(0.02F),
      ),
    ),
    @transform.Transform::from_xyz(0.0F, 0.0F, 1.0F),
  ).spawn(world)
  world
  .component(@sprite.ecs_key_render_layers)
  .insert(first_pass_cube, first_pass_layer, tick)
  render_to_texture_state.val.first_pass_cube = first_pass_cube

  let light = world.spawn_empty()
  world
  .component(@pbr.ecs_key_point_light)
  .insert(light, @pbr.PointLight::default(), tick)
  world
  .component(@transform.ecs_key_transform)
  .insert(light, @transform.Transform::from_xyz(0.0F, 0.0F, 10.0F), tick)
  world
  .component(@sprite.ecs_key_render_layers)
  .insert(light, @sprite.RenderLayers::layer(0).with_layer(1), tick)

  let first_pass_camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::new(@sprite.Color::white()).with_order(-1),
    @transform.Transform::from_xyz(0.0F, 0.0F, 15.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world
  .component(@sprite.ecs_key_render_target)
  .insert(first_pass_camera, @sprite.RenderTarget::Image(image), tick)
  world
  .component(@sprite.ecs_key_render_layers)
  .insert(first_pass_camera, first_pass_layer, tick)

  let main_pass_cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_cuboid(4.0F, 4.0F, 4.0F),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@sprite.Color::white())
        .with_base_color_texture(Some(image))
        .with_reflectance(0.02F),
      ),
    ),
    @transform.Transform::from_xyz(0.0F, 0.0F, 1.5F).with_rotation(
      @math.Quat::from_rotation_x(-PI / 5.0F),
    ),
  ).spawn(world)
  render_to_texture_state.val.main_pass_cube = main_pass_cube

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(0.0F, 0.0F, 15.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in render_to_texture example")
  }
}

///|
fn rotator_system(world : @ecs.World) -> Unit {
  if render_to_texture_state.val.first_pass_cube.is_placeholder() {
    return
  }
  let tick = world.read_change_tick()
  let transform_store = world.component(@transform.ecs_key_transform)
  if transform_store.get(render_to_texture_state.val.first_pass_cube)
    is Some(transform) {
    let delta = world_time(world).delta_seconds()
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
fn cube_rotator_system(world : @ecs.World) -> Unit {
  if render_to_texture_state.val.main_pass_cube.is_placeholder() {
    return
  }
  let tick = world.read_change_tick()
  let transform_store = world.component(@transform.ecs_key_transform)
  if transform_store.get(render_to_texture_state.val.main_pass_cube)
    is Some(transform) {
    let delta = world_time(world).delta_seconds()
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
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(cube_rotator_system))
  .add_systems(@app.Update, @app.system(rotator_system))
  .run()
}
