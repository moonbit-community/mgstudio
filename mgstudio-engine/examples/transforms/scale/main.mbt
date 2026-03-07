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
/// Port of `bevy/examples/transforms/scale.rs`.

///|
pub struct Scaling {
  mut scale_direction : @math.Vec3
  scale_speed : Float
  max_element_size : Float
  min_element_size : Float
}

///|
let scaling_component_key : @ecs.ComponentKey[Scaling] = @ecs.register_component(
  debug_name="examples.transforms.scale.Scaling",
)

///|
impl @ecs.Component for Scaling with component() {
  scaling_component_key
}

///|
fn Scaling::new() -> Scaling {
  {
    scale_direction: @math.Vec3::new(1.0F, 0.0F, 0.0F),
    scale_speed: 2.0F,
    max_element_size: 5.0F,
    min_element_size: 1.0F,
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white()),
  )
  let cube = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(material),
    @math.Transform::from_rotation(
      @math.Quat::from_rotation_y(@math.pi() / 4.0F),
    ),
  ).spawn(world)
  world.component(Scaling::component()).insert(cube, Scaling::new(), tick)

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
fn change_scale_direction(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let transform_store = world.component(@math.Transform::component())
  let scaling_store = world.component(Scaling::component())
  let updates : Array[(@core.Entity, Scaling, @math.Transform)] = []
  scaling_store.for_each(fn(entity, scaling) {
    if transform_store.get(entity) is Some(transform) {
      updates.push((entity, scaling, transform))
    }
  })

  for update in updates {
    let entity = update.0
    let scaling = update.1
    let transform = update.2
    let next_scaling = Scaling::{
      scale_direction: scaling.scale_direction,
      scale_speed: scaling.scale_speed,
      max_element_size: scaling.max_element_size,
      min_element_size: scaling.min_element_size,
    }
    let next_transform = transform
    if transform.scale.max_element() > scaling.max_element_size {
      next_scaling.scale_direction = next_scaling.scale_direction.mul_scalar(
        -1.0F,
      )
      next_transform.scale = next_transform.scale.floor()
    }
    if next_transform.scale.min_element() < scaling.min_element_size {
      next_scaling.scale_direction = next_scaling.scale_direction.mul_scalar(
        -1.0F,
      )
      next_transform.scale = next_transform.scale.ceil()
      next_scaling.scale_direction = next_scaling.scale_direction.zxy()
    }
    ignore(transform_store.set(entity, next_transform, tick))
    ignore(scaling_store.set(entity, next_scaling, tick))
  }
}

///|
fn scale_cube(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let delta = @time.time_delta_seconds()
  let transform_store = world.component(@math.Transform::component())
  let scaling_store = world.component(Scaling::component())
  let updates : Array[(@core.Entity, Scaling, @math.Transform)] = []
  scaling_store.for_each(fn(entity, scaling) {
    if transform_store.get(entity) is Some(transform) {
      updates.push((entity, scaling, transform))
    }
  })

  for update in updates {
    let entity = update.0
    let scaling = update.1
    let transform = update.2
    let next_transform = transform.with_scale(
      transform.scale.add(
        scaling.scale_direction.mul_scalar(scaling.scale_speed * delta),
      ),
    )
    ignore(transform_store.set(entity, next_transform, tick))
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(change_scale_direction))
  .add_systems(@app.Update, @app.system(scale_cube))
  .run()
}
