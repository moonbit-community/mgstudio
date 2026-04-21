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
struct Ship {
  mut target_index : Int
  mut in_motion : Bool
}

///|
let ship_key : @ecs.ComponentKey[Ship] = @ecs.register_component(
  debug_name="examples.transforms.align.Ship",
)

///|
pub impl @ecs.Component for Ship with component() {
  ship_key
}

///|
fn normalize_or_up(direction : @math.Vec3) -> @math.Vec3 {
  let normalized = direction.normalize_or_zero()
  if normalized.length() <= 1.0e-5 {
    @math.Vec3::new(0.0F, 1.0F, 0.0F)
  } else {
    normalized
  }
}

///|
fn target_axes(index : Int) -> (@math.Vec3, @math.Vec3) {
  match index % 4 {
    0 =>
      (
        normalize_or_up(@math.Vec3::new(0.8F, 0.45F, -0.2F)),
        normalize_or_up(@math.Vec3::new(-0.1F, 0.2F, 1.0F)),
      )
    1 =>
      (
        normalize_or_up(@math.Vec3::new(-0.5F, 0.7F, -0.4F)),
        normalize_or_up(@math.Vec3::new(0.9F, 0.05F, 0.3F)),
      )
    2 =>
      (
        normalize_or_up(@math.Vec3::new(0.2F, 0.9F, 0.4F)),
        normalize_or_up(@math.Vec3::new(-0.7F, 0.1F, 0.7F)),
      )
    _ =>
      (
        normalize_or_up(@math.Vec3::new(-0.85F, 0.3F, 0.15F)),
        normalize_or_up(@math.Vec3::new(0.25F, 0.15F, -0.95F)),
      )
  }
}

///|
fn apply_alignment(
  transform : @transform.Transform,
  index : Int,
) -> @transform.Transform {
  let (primary, secondary) = target_axes(index)
  transform.aligned_by(
    @math.Vec3::new(0.0F, 0.0F, -1.0F),
    primary,
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    secondary,
  )
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let plane_mesh = meshes
    .peek()
    .add(
      @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(100.0F, 100.0F)),
    )
  let ship_mesh = meshes.peek()
    |> @pbr.add_mesh(@math.Cuboid::new(0.8F, 0.4F, 2.0F))
  let plane_material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.28F, 0.5F, 0.32F)),
    )
  let ship_material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(
        @sprite.Color::srgb(0.86F, 0.86F, 0.92F),
      ).with_reflectance(0.3F),
    )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(plane_mesh),
        @pbr.MeshMaterial3d::new(plane_material),
        @transform.Transform::from_xyz(0.0F, -2.0F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(ship_mesh),
        @pbr.MeshMaterial3d::new(ship_material),
        Ship::{ target_index: 0, in_motion: false },
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::new(@sprite.Color::white(), 1_600_000.0F, 30.0F, false),
        @transform.Transform::from_xyz(4.0F, 7.0F, -4.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(3.0F, 2.5F, 4.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn handle_keys(
  keyboard : @input.ButtonInput[@window.KeyCode],
  ships : @ecs.Query[(@ecs.Mut[Ship], @ecs.Mut[@transform.Transform]), @ecs.All],
) -> Unit {
  let randomize = keyboard.just_pressed(@window.KeyCode::KeyR)
  let toggle_motion = keyboard.just_pressed(@window.KeyCode::KeyT)
  if !randomize && !toggle_motion {
    return
  }

  try! ships.view(fn(_entity, pair) {
    let (ship, transform) = pair
    let next_ship = ship.value()
    let next_transform = transform.value()

    if randomize {
      next_ship.target_index = next_ship.target_index + 1
      next_ship.in_motion = false
      transform.set(apply_alignment(next_transform, next_ship.target_index))
      ship.set(next_ship)
    }
    if toggle_motion {
      next_ship.in_motion = !next_ship.in_motion
      ship.set(next_ship)
      if next_ship.in_motion {
        transform.set(apply_alignment(next_transform, next_ship.target_index))
      }
    }
  })
}

///|
fn spin_ship(
  time : @app.Res[@time.Time[Unit]],
  ships : @ecs.Query[
    (@ecs.Comp[Ship], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! ships.view(fn(_entity, pair) {
    let (ship, transform) = pair
    if ship.value().in_motion {
      transform.modify(fn(value) { value.rotate_y(delta * 0.7F) })
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(handle_keys)))
  .add_systems(@app.Update, @app.system(@app.system_param2(spin_ship)))
  .run()
}
