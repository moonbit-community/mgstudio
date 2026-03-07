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
/// Port of `bevy/examples/transforms/transform.rs`.

///|
pub struct CubeState {
  start_pos : @math.Vec3
  move_speed : Float
  turn_speed : Float
}

///|
let cube_state_component_key : @ecs.ComponentKey[CubeState] = @ecs.register_component(
  debug_name="examples.transforms.transform.CubeState",
)

///|
impl @ecs.Component for CubeState with component() {
  cube_state_component_key
}

///|
pub struct Center {
  max_size : Float
  min_size : Float
  scale_factor : Float
}

///|
let center_component_key : @ecs.ComponentKey[Center] = @ecs.register_component(
  debug_name="examples.transforms.transform.Center",
)

///|
impl @ecs.Component for Center with component() {
  center_component_key
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let sphere_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::srgb(1.0F, 1.0F, 0.0F),
    ),
  )
  let center_sphere = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_sphere(3.0F),
    @render3d.MeshMaterial3d::new(sphere_material),
    @math.Transform::from_translation(@math.Vec3::zero()),
  ).spawn(world)
  world
  .component(Center::component())
  .insert(
    center_sphere,
    { max_size: 1.0F, min_size: 0.1F, scale_factor: 0.05F },
    tick,
  )

  let cube_spawn = @math.Transform::from_translation(
    @math.Vec3::new(0.0F, 0.0F, -10.0F),
  ).with_rotation(@math.Quat::from_rotation_y(@math.pi() / 2.0F))
  let cube_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white()),
  )
  let cube = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(cube_material),
    cube_spawn,
  ).spawn(world)
  world
  .component(CubeState::component())
  .insert(
    cube,
    { start_pos: cube_spawn.translation, move_speed: 2.0F, turn_speed: 0.2F },
    tick,
  )

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.0F, 10.0F, 20.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  let light = world.spawn_empty()
  world
  .component(@render3d.DirectionalLight::component())
  .insert(light, @render3d.DirectionalLight::default(), tick)
  world
  .component(@math.Transform::component())
  .insert(
    light,
    @math.Transform::from_xyz(3.0F, 3.0F, 3.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
}

///|
fn move_cube(
  cubes : @ecs.Query2RefMutFiltered[
    CubeState,
    @math.Transform,
    @ecs.Without[Center],
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta = time.get().delta_secs()
  try! cubes.view_mut(fn(_entity, cube, transform) {
    let transform_ref = transform.get_ref()
    let forward = transform_ref.val.forward()
    transform_ref.val.translation = transform_ref.val.translation.add(
      forward.mul_scalar(cube.value().move_speed * delta),
    )
  })
}

///|
fn rotate_cube(
  cubes : @ecs.Query2RefMutFiltered[
    CubeState,
    @math.Transform,
    @ecs.Without[Center],
  ],
  center_spheres : @ecs.Query1Filtered[@math.Transform, @ecs.With[Center]],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let center = Ref::new(@math.Vec3::zero())
  try! center_spheres.view(fn(_entity, transform) {
    center.val = center.val.add(transform.translation)
  })
  let delta = time.get().delta_secs()
  try! cubes.view_mut(fn(_entity, cube, transform) {
    let transform_ref = transform.get_ref()
    let look_at_sphere = transform_ref.val.looking_at(
      center.val,
      transform_ref.val.local_y(),
    )
    let weight = cube.value().turn_speed * delta
    let old_rotation = transform_ref.val.rotation
    transform_ref.val.rotation = old_rotation.lerp(
      look_at_sphere.rotation,
      weight,
    )
  })
}

///|
fn scale_down_sphere_proportional_to_cube_travel_distance(
  cubes : @ecs.Query2Filtered[@math.Transform, CubeState, @ecs.Without[Center]],
  centers : @ecs.Query2RefMutFiltered[Center, @math.Transform, @ecs.All],
) -> Unit {
  let distances = Ref::new(0.0F)
  try! cubes.view(fn(_entity, cube_transform, cube_state) {
    distances.val = distances.val +
      cube_state.start_pos.sub(cube_transform.translation).length()
  })
  try! centers.view_mut(fn(_entity, center, transform) {
    let center_state = center.value()
    let mut new_size = center_state.max_size -
      center_state.scale_factor * distances.val
    if new_size < center_state.min_size {
      new_size = center_state.min_size
    }
    transform.get_ref().val.scale = @math.Vec3::splat(new_size)
  })
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param2(move_cube)))
  .add_systems(@app.Update, @app.system(@app.system_param3(rotate_cube)))
  .add_systems(
    @app.Update,
    @app.system(
      @app.system_param2(scale_down_sphere_proportional_to_cube_travel_distance),
    ),
  )
  .run()
}
