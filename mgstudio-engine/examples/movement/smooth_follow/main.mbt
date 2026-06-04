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
impl @ecs.Component for TargetSphere with fn component() {
  target_sphere_key
}

///|
impl @ecs.Component for FollowingSphere with fn component() {
  following_sphere_key
}

///|
impl @app.Resource for TargetSphereSpeed with fn resource() {
  target_sphere_speed_key
}

///|
impl @app.Resource for TargetPosition with fn resource() {
  target_position_key
}

///|
impl @app.Resource for DecayRate with fn resource() {
  decay_rate_key
}

///|
impl @app.Resource for RandomSource with fn resource() {
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
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(
          meshes.peek()
          |> @pbr.add_mesh(
            @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
              @math.Vec2::new(12.0F, 12.0F),
            ).build(),
          ),
        ),
        @pbr.MeshMaterial3d::new(
          materials
          .peek()
          .add(
            @pbr.StandardMaterial::from_color(
              @sprite.Color::srgb(0.3F, 0.15F, 0.3F),
            ),
          ),
        ),
        @transform.Transform::from_xyz(0.0F, -2.5F, 0.0F),
      ),
    ),
  )

  let sphere_mesh = meshes.modify(fn(meshes) {
    meshes |> @pbr.add_mesh(@math.Sphere::new(0.3F))
  })
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(sphere_mesh),
        @pbr.MeshMaterial3d::new(
          materials
          .peek()
          .add(
            @pbr.StandardMaterial::from_color(
              @sprite.Color::srgb(0.3F, 0.15F, 0.9F),
            ),
          ),
        ),
        TargetSphere::{  },
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(sphere_mesh),
        @pbr.MeshMaterial3d::new(
          materials
          .peek()
          .add(
            @pbr.StandardMaterial::from_color(
              @sprite.Color::srgb(0.9F, 0.3F, 0.3F),
            ),
          ),
        ),
        @transform.Transform::from_xyz(0.0F, -2.0F, 0.0F),
        FollowingSphere::{  },
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::PointLight()
        .with_intensity(15_000_000.0F)
        .with_shadow_maps_enabled(true),
        @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @transform.Transform::from_xyz(-2.0F, 3.0F, 5.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  commands.insert_resource(TargetSphereSpeed::{ value: 5.0F })
  commands.insert_resource(DecayRate::{ value: 2.0F })
  commands.insert_resource(TargetPosition::{ value: @math.Vec3::zero() })
  commands.insert_resource(RandomSource::{
    rng: @random.Rand::chacha8(seed=b"bevyfollow68941654987813521seedx"),
  })
}

///|
fn move_target(
  target : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[TargetSphere]],
  target_speed : @app.Res[TargetSphereSpeed],
  target_pos : @app.ResMut[TargetPosition],
  time : @app.Res[@time.Time[Unit]],
  rng : @app.ResMut[RandomSource],
) -> Unit {
  let delta_time = time.get().delta_secs()
  let current_target_position = target_pos.peek().value

  try! target.view(fn(_entity, transform) {
    let current_translation = transform.value().translation
    let offset = current_target_position.sub(current_translation)
    let abs_delta = offset.length()

    if abs_delta > 0.000001F {
      let magnitude = min_float(
        abs_delta,
        delta_time * target_speed.get().value,
      )
      transform.modify(fn(value) {
        value.translation = value.translation.add(
          offset.normalize_or_zero().mul_scalar(magnitude),
        )
      })
    } else {
      let legal_region = @math.Cuboid::from_size(@math.Vec3::splat(4.0F))
      let next_target = rng.modify(fn(value) {
        legal_region.sample_interior(value.rng)
      })
      target_pos.modify(fn(value) { value.value = next_target })
    }
  })
}

///|
fn move_follower(
  following : @ecs.Query[
    @ecs.Mut[@transform.Transform],
    @ecs.With[FollowingSphere],
  ],
  target : @ecs.Query[
    @ecs.Comp[@transform.Transform],
    (@ecs.With[TargetSphere], @ecs.Without[FollowingSphere]),
  ],
  decay_rate : @app.Res[DecayRate],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  guard (target.single() catch { _ => None }) is Some(target_transform_comp) else {
    return
  }
  let target_transform = target_transform_comp.value()

  let delta_time = time.get().delta_secs()
  try! following.view(fn(_entity, transform) {
    let next_translation = transform.value().translation
    next_translation.smooth_nudge(
      target_transform.translation,
      decay_rate.get().value,
      delta_time,
    )
    transform.modify(fn(value) { value.translation = next_translation })
  })
}

///|
fn main {
  let move_target_system : @app.SystemConfig[@ecs.World] = @app.system_config_param5(
    move_target,
  )
  let move_follower_system : @app.SystemConfig[@ecs.World] = @app.system_config_param4(
    move_follower,
  )

  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems(@app.Startup, @app.system_config_param3(setup))
  .add_systems(
    @app.Update,
    (move_target_system, move_follower_system) |> @app.chain(),
  )
  .run()
}
