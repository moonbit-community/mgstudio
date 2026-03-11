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
/// Port of `bevy/examples/transforms/3d_rotation.rs`.

///|
pub struct Rotatable {
  speed : Float
}

///|
let rotatable_component_key : @ecs.ComponentKey[Rotatable] = @ecs.register_component(
  debug_name="examples.transforms.3d_rotation.Rotatable",
)

///|
impl @ecs.Component for Rotatable with component() {
  rotatable_component_key
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()),
  )
  let cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @pbr.MeshMaterial3d::new(material),
    @math.Transform::from_translation(@math.Vec3::zero()),
  ).spawn(world)
  world.component(Rotatable::component()).insert(cube, { speed: 0.3F }, tick)

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::from_xyz(0.0F, 10.0F, 20.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  let light = world.spawn_empty()
  world
  .component(@pbr.DirectionalLight::component())
  .insert(light, @pbr.DirectionalLight::default(), tick)
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
fn rotate_cube(
  cubes : @ecs.Query2RefMutFiltered[Rotatable, @math.Transform, @ecs.All],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta = time.get().delta_secs()
  try! cubes.view_mut(fn(_entity, cube, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.rotate_y(cube.value().speed * (@math.pi() * 2.0F) * delta)
  })
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate_cube)))
  .run()
}
