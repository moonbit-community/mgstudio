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
/// Port of `bevy/examples/movement/smooth_follow.rs`.

///|
struct TargetSphere {}

///|
struct FollowingSphere {}

///|
struct TargetSphereSpeed {
  value : Float
}

///|
struct TargetPosition {
  mut value : @math.Vec3
}

///|
struct DecayRate {
  value : Float
}

///|
struct RandomSource {
  rng : @random.Rand
}

///|
let target_sphere_key : @ecs.ComponentKey[TargetSphere] = @ecs.register_component(
  debug_name="examples.movement.smooth_follow.TargetSphere",
)

///|
let following_sphere_key : @ecs.ComponentKey[FollowingSphere] = @ecs.register_component(
  debug_name="examples.movement.smooth_follow.FollowingSphere",
)

///|
let target_sphere_speed_key : @ecs.ResourceKey[TargetSphereSpeed] = @ecs.register_resource(
  debug_name="examples.movement.smooth_follow.TargetSphereSpeed",
)

///|
let target_position_key : @ecs.ResourceKey[TargetPosition] = @ecs.register_resource(
  debug_name="examples.movement.smooth_follow.TargetPosition",
)

///|
let decay_rate_key : @ecs.ResourceKey[DecayRate] = @ecs.register_resource(
  debug_name="examples.movement.smooth_follow.DecayRate",
)

///|
let random_source_key : @ecs.ResourceKey[RandomSource] = @ecs.register_resource(
  debug_name="examples.movement.smooth_follow.RandomSource",
)

///|
let move_target_set : @app.SystemSet = @app.system_set(
  "examples.movement.smooth_follow.move_target",
)

///|
impl @ecs.Component for TargetSphere with component() {
  target_sphere_key
}

///|
impl @ecs.Component for FollowingSphere with component() {
  following_sphere_key
}

///|
impl @app.Resource for TargetSphereSpeed with resource() {
  target_sphere_speed_key
}

///|
impl @app.Resource for TargetPosition with resource() {
  target_position_key
}

///|
impl @app.Resource for DecayRate with resource() {
  decay_rate_key
}

///|
impl @app.Resource for RandomSource with resource() {
  random_source_key
}

///|
fn min_float(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn default_time_or_default(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.time_resource_key_of(()))) {
    Some(time) => time
    None => {
      let time : @time.Time[Unit] = @time.Time::default()
      time
    }
  }
}

///|
fn[T] first_marked_entity(
  world : @ecs.World,
  marker_key : @ecs.ComponentKey[T],
) -> @core.Entity? {
  let mut result : @core.Entity? = None
  world
  .component(marker_key)
  .for_each(fn(entity, _marker) { if result is None { result = Some(entity) } })
  result
}

///|
fn spawn_colored_sphere(
  world : @ecs.World,
  color : @render2d.Color,
  transform : @math.Transform,
) -> @core.Entity {
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_sphere(0.3F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(color),
      ),
    ),
    transform,
  ).spawn(world)
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(12.0F, 12.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::srgb(0.3F, 0.15F, 0.3F),
        ),
      ),
    ),
    @math.Transform::from_xyz(0.0F, -2.5F, 0.0F),
  ).spawn(world)
  |> ignore

  let target_sphere = spawn_colored_sphere(
    world,
    @render2d.Color::srgb(0.3F, 0.15F, 0.9F),
    @math.Transform::identity(),
  )
  world
  .component(TargetSphere::component())
  .insert(target_sphere, TargetSphere::{  }, tick)

  let following_sphere = spawn_colored_sphere(
    world,
    @render2d.Color::srgb(0.9F, 0.3F, 0.3F),
    @math.Transform::from_xyz(0.0F, -2.0F, 0.0F),
  )
  world
  .component(FollowingSphere::component())
  .insert(following_sphere, FollowingSphere::{  }, tick)

  let light = world.spawn_empty()
  world
  .component(@render3d.PointLight::component())
  .insert(
    light,
    @render3d.PointLight::default()
    .with_intensity(15_000_000.0F)
    .with_shadow_maps_enabled(true),
    tick,
  )
  world
  .component(@math.Transform::component())
  .insert(light, @math.Transform::from_xyz(4.0F, 8.0F, 4.0F), tick)

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-2.0F, 3.0F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  world.insert_resource(TargetSphereSpeed::resource(), TargetSphereSpeed::{
    value: 5.0F,
  })
  world.insert_resource(DecayRate::resource(), DecayRate::{ value: 2.0F })
  world.insert_resource(TargetPosition::resource(), TargetPosition::{
    value: @math.Vec3::zero(),
  })
  world.insert_resource(RandomSource::resource(), RandomSource::{
    rng: @random.Rand::chacha8(seed=b"bevyfollow68941654987813521seedx"),
  })
}

///|
fn move_target(world : @ecs.World) -> Unit {
  guard first_marked_entity(world, TargetSphere::component())
    is Some(target_entity) else {
    return
  }
  guard (try! world.get_resource(TargetSphereSpeed::resource()))
    is Some(target_speed) else {
    return
  }

  let delta_time = default_time_or_default(world).delta_secs()
  let tick = world.increment_change_tick()
  guard (try! world.get_resource_ref_mut(TargetPosition::resource(), tick))
    is Some(target_position) else {
    return
  }
  guard (try! world.get_resource_ref_mut(RandomSource::resource(), tick))
    is Some(random_source) else {
    return
  }

  let transform_store = world.component(@math.Transform::component())
  guard transform_store.get(target_entity) is Some(target_transform) else {
    return
  }

  let offset = target_position.val.value.sub(target_transform.translation)
  let abs_delta = offset.length()
  if abs_delta > 0.000001F {
    let magnitude = min_float(abs_delta, delta_time * target_speed.value)
    ignore(
      transform_store.set(
        target_entity,
        target_transform.with_translation(
          target_transform.translation.add(
            offset.normalize_or_zero().mul_scalar(magnitude),
          ),
        ),
        tick,
      ),
    )
  } else {
    let legal_region = @math.Cuboid::from_size(@math.Vec3::splat(4.0F))
    target_position.val.value = legal_region.sample_interior(
      random_source.val.rng,
    )
  }
}

///|
fn move_follower(world : @ecs.World) -> Unit {
  guard first_marked_entity(world, TargetSphere::component())
    is Some(target_entity) else {
    return
  }
  guard first_marked_entity(world, FollowingSphere::component())
    is Some(following_entity) else {
    return
  }
  guard (try! world.get_resource(DecayRate::resource())) is Some(decay_rate) else {
    return
  }

  let transform_store = world.component(@math.Transform::component())
  guard transform_store.get(target_entity) is Some(target_transform) else {
    return
  }
  guard transform_store.get(following_entity) is Some(following_transform) else {
    return
  }

  let delta_time = default_time_or_default(world).delta_secs()
  let next_translation = @math.Vec3::new(
    following_transform.translation.x,
    following_transform.translation.y,
    following_transform.translation.z,
  )
  next_translation.smooth_nudge(
    target_transform.translation,
    decay_rate.value,
    delta_time,
  )

  ignore(
    transform_store.set(
      following_entity,
      following_transform.with_translation(next_translation),
      world.increment_change_tick(),
    ),
  )
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(move_target).in_set(move_target_set))
  .add_systems(@app.Update, @app.system(move_follower).after(move_target_set))
  .run()
}
