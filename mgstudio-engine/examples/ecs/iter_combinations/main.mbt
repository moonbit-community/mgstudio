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
const GRAVITY_CONSTANT : Float = 4000.0F

///|
const FIXED_STEP_SECONDS : Float = 0.016666667F

///|
struct Mass {
  value : Float
}

///|
struct Velocity {
  mut linear : @math.Vec2
}

///|
struct Acceleration {
  mut linear : @math.Vec2
}

///|
struct Star {}

///|
let mass_key : @ecs.ComponentKey[Mass] = @ecs.register_component(
  debug_name="examples.ecs.iter_combinations.mass",
)

///|
let velocity_key : @ecs.ComponentKey[Velocity] = @ecs.register_component(
  debug_name="examples.ecs.iter_combinations.velocity",
)

///|
let acceleration_key : @ecs.ComponentKey[Acceleration] = @ecs.register_component(
  debug_name="examples.ecs.iter_combinations.acceleration",
)

///|
let star_key : @ecs.ComponentKey[Star] = @ecs.register_component(
  debug_name="examples.ecs.iter_combinations.star",
)

///|
pub impl @ecs.Component for Mass with component() {
  mass_key
}

///|
pub impl @ecs.Component for Velocity with component() {
  velocity_key
}

///|
pub impl @ecs.Component for Acceleration with component() {
  acceleration_key
}

///|
pub impl @ecs.Component for Star with component() {
  star_key
}

///|
fn spawn_body(
  commands : @app.Commands,
  meshes : @asset.Assets[@mesh.Mesh],
  materials : @asset.Assets[@sprite.ColorMaterialAsset],
  position : @math.Vec2,
  velocity : @math.Vec2,
  radius : Float,
  mass : Float,
  color : @sprite.Color,
  star? : Bool = false,
) -> Unit {
  let bundle = (
    @sprite.Mesh2d::new(meshes |> @sprite.add_mesh(@sprite.Circle::new(1.0F))),
    @sprite.MeshMaterial2d::new(materials |> @sprite.add_material(color)),
    @transform.Transform::from_xyz(position.x, position.y, 0.0F).with_scale(
      @math.Vec3::splat(radius),
    ),
    Mass::{ value: mass },
    Velocity::{ linear: velocity },
    Acceleration::{ linear: @math.Vec2::new(0.0F, 0.0F) },
  )
  let entity = commands.spawn(bundle)
  if star {
    ignore(commands.entity(entity).insert_component(Star::{  }))
  }
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  let mesh_assets = meshes.get_ref().val
  let material_assets = materials.get_ref().val
  spawn_body(
    commands,
    mesh_assets,
    material_assets,
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
    28.0F,
    1800.0F,
    @sprite.Color::srgb(1.0F, 0.38F, 0.18F),
    star=true,
  )
  spawn_body(
    commands,
    mesh_assets,
    material_assets,
    @math.Vec2::new(-220.0F, 0.0F),
    @math.Vec2::new(0.0F, 62.0F),
    10.0F,
    8.0F,
    @sprite.Color::srgb(0.55F, 0.76F, 1.0F),
  )
  spawn_body(
    commands,
    mesh_assets,
    material_assets,
    @math.Vec2::new(220.0F, 0.0F),
    @math.Vec2::new(0.0F, -58.0F),
    12.0F,
    10.0F,
    @sprite.Color::srgb(0.35F, 0.95F, 0.78F),
  )
  spawn_body(
    commands,
    mesh_assets,
    material_assets,
    @math.Vec2::new(0.0F, 170.0F),
    @math.Vec2::new(-68.0F, 0.0F),
    11.0F,
    9.0F,
    @sprite.Color::srgb(0.96F, 0.87F, 0.42F),
  )
  spawn_body(
    commands,
    mesh_assets,
    material_assets,
    @math.Vec2::new(0.0F, -230.0F),
    @math.Vec2::new(52.0F, 0.0F),
    9.0F,
    7.0F,
    @sprite.Color::srgb(0.96F, 0.52F, 0.81F),
  )
}

///|
fn interact_bodies(
  query : @ecs.Query[
    (@ecs.Comp[Mass], @ecs.Comp[@transform.Transform], @ecs.Mut[Acceleration]),
    @ecs.All,
  ],
) -> Unit {
  let combinations = query.iter_combinations()
  while true {
    if (combinations.fetch_next() catch { _ => None }) is Some((left, right)) {
      let (left_mass, left_transform, left_acceleration) = left
      let (right_mass, right_transform, right_acceleration) = right
      let delta = @math.Vec2::new(
        right_transform.value().translation.x -
        left_transform.value().translation.x,
        right_transform.value().translation.y -
        left_transform.value().translation.y,
      )
      let distance_sq = if delta.length_squared() < 64.0F {
        64.0F
      } else {
        delta.length_squared()
      }
      let force_unit_mass = delta
        .normalize_or_zero()
        .mul_scalar(GRAVITY_CONSTANT / distance_sq)
      let left_ref = left_acceleration.get_ref()
      let right_ref = right_acceleration.get_ref()
      left_ref.val.linear = left_ref.val.linear.add(
        force_unit_mass.mul_scalar(right_mass.value().value),
      )
      right_ref.val.linear = right_ref.val.linear.add(
        force_unit_mass.mul_scalar(-left_mass.value().value),
      )
    } else {
      break
    }
  }
}

///|
fn integrate(
  query : @ecs.Query[
    (@ecs.Mut[Acceleration], @ecs.Mut[Velocity], @ecs.Mut[@transform.Transform]),
    @ecs.Without[Star],
  ],
  fixed_time : @app.Res[@time.Time[@time.Fixed]],
) -> Unit {
  let delta = fixed_time.get().delta_seconds()
  try! query.view(fn(_entity, body) {
    let (acceleration, velocity, transform) = body
    let acceleration_ref = acceleration.get_ref()
    let velocity_ref = velocity.get_ref()
    let transform_ref = transform.get_ref()
    velocity_ref.val.linear = velocity_ref.val.linear.add(
      acceleration_ref.val.linear.mul_scalar(delta),
    )
    transform_ref.val.translation.x = transform_ref.val.translation.x +
      velocity_ref.val.linear.x * delta
    transform_ref.val.translation.y = transform_ref.val.translation.y +
      velocity_ref.val.linear.y * delta
    acceleration_ref.val.linear = @math.Vec2::new(0.0F, 0.0F)
  })
}

///|
fn main {
  let fixed_time : @time.Time[@time.Fixed] = @time.Time::from_seconds(
    FIXED_STEP_SECONDS,
  )
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .insert_resource(fixed_time)
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(
    @app.FixedUpdate,
    @app.system(@app.system_param(interact_bodies)),
  )
  .add_systems(@app.FixedUpdate, @app.system(@app.system_param2(integrate)))
  .run()
}
