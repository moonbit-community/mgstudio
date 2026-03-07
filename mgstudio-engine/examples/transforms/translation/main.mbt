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
/// Port of `bevy/examples/transforms/translation.rs`.

///|
pub struct Movable {
  spawn : @math.Vec3
  max_distance : Float
  mut speed : Float
}

///|
let movable_component_key : @ecs.ComponentKey[Movable] = @ecs.register_component(
  debug_name="examples.transforms.translation.Movable",
)

///|
impl @ecs.Component for Movable with component() {
  movable_component_key
}

///|
fn Movable::new(spawn : @math.Vec3) -> Movable {
  { spawn, max_distance: 5.0F, speed: 2.0F }
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let entity_spawn = @math.Vec3::zero()
  let material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white()),
  )
  let cube = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(material),
    @math.Transform::from_translation(entity_spawn),
  ).spawn(world)
  world
  .component(Movable::component())
  .insert(cube, Movable::new(entity_spawn), tick)

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.0F, 10.0F, 20.0F).looking_at(
      entity_spawn,
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
fn move_cube(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let delta = @time.time_delta_seconds()
  let transform_store = world.component(@math.Transform::component())
  let movable_store = world.component(Movable::component())
  let updates : Array[(@core.Entity, Movable, @math.Transform)] = []
  movable_store.for_each(fn(entity, movable) {
    if transform_store.get(entity) is Some(transform) {
      updates.push((entity, movable, transform))
    }
  })

  for update in updates {
    let entity = update.0
    let movable = update.1
    let transform = update.2
    let next_movable = Movable::{
      spawn: movable.spawn,
      max_distance: movable.max_distance,
      speed: movable.speed,
    }
    if movable.spawn.sub(transform.translation).length() > movable.max_distance {
      next_movable.speed = -next_movable.speed
    }
    let direction = transform.local_x()
    let next_transform = transform.with_translation(
      transform.translation.add(
        direction.mul_scalar(next_movable.speed * delta),
      ),
    )
    ignore(transform_store.set(entity, next_transform, tick))
    ignore(movable_store.set(entity, next_movable, tick))
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(move_cube))
  .run()
}
