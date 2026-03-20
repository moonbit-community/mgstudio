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

  let material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.8F, 0.7F, 0.6F, 1.0F),
    ),
  )

  let parent = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_cuboid(2.0F, 2.0F, 2.0F),
    @pbr.MeshMaterial3d::new(material),
    @transform.Transform::from_xyz(0.0F, 0.0F, 1.0F),
  ).spawn(world)
  rotator_state.val.rotators.push(parent)

  let child = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_cuboid(2.0F, 2.0F, 2.0F),
    @pbr.MeshMaterial3d::new(material),
    @transform.Transform::from_xyz(0.0F, 0.0F, 3.0F),
  ).spawn(world)
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(child, @hierarchy.Parent::new(parent), tick)

  let light_entity = world.spawn_empty()
  world
  .component(@pbr.ecs_key_point_light)
  .insert(light_entity, @pbr.PointLight::default(), tick)
  world
  .component(@transform.ecs_key_transform)
  .insert(light_entity, @transform.Transform::from_xyz(4.0F, 5.0F, -4.0F), tick)

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(5.0F, 10.0F, 10.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in parenting example")
  }
}

///|
fn rotator_system(world : @ecs.World) -> Unit {
  let delta = 3.0F * world_time(world).delta_seconds()
  let spin = @math.Quat::from_rotation_x(delta)
  let tick = world.read_change_tick()
  let transform_store = world.component(@transform.ecs_key_transform)
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
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(rotator_system))
  .run()
}
