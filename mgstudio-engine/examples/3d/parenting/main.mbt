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
/// Port of `bevy/examples/3d/parenting.rs`.

///|
priv struct RotatorState {
  rotators : Array[@core.Entity]
}

///|
let rotator_state : Ref[RotatorState] = Ref::new({ rotators: [] })

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  rotator_state.val.rotators.clear()

  let material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.8F, 0.7F, 0.6F, 1.0F),
    ),
  )

  let parent = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(2.0F, 2.0F, 2.0F),
    @render3d.MeshMaterial3d::new(material),
    @math.Transform::from_xyz(0.0F, 0.0F, 1.0F),
  ).spawn(world)
  rotator_state.val.rotators.push(parent)

  let child = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(2.0F, 2.0F, 2.0F),
    @render3d.MeshMaterial3d::new(material),
    @math.Transform::from_xyz(0.0F, 0.0F, 3.0F),
  ).spawn(world)
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(child, @hierarchy.Parent::new(parent), tick)

  let light_entity = world.spawn_empty()
  world
  .component(@render3d.ecs_key_point_light)
  .insert(light_entity, @render3d.PointLight::default(), tick)
  world
  .component(@math.ecs_key_transform)
  .insert(light_entity, @math.Transform::from_xyz(4.0F, 5.0F, -4.0F), tick)

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(5.0F, 10.0F, 10.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn rotator_system(world : @ecs.World) -> Unit {
  let delta = 3.0F * @time.time_delta_seconds()
  let spin = @math.Quat::from_rotation_x(delta)
  let tick = world.read_change_tick()
  let transform_store = world.component(@math.ecs_key_transform)
  for entity in rotator_state.val.rotators {
    if transform_store.get(entity) is Some(transform) {
      let next = transform.with_rotation(
        transform.rotation.mul(spin).normalize(),
      )
      transform_store.set(entity, next, tick) |> ignore
    }
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(rotator_system)
  .run()
}
