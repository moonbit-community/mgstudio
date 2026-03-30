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
const GRID_HALF : Int = 12

///|
const GRID_SPACING : Float = 1.4F

///|
struct RotatingCube {}

///|
let rotating_cube_key : @ecs.ComponentKey[RotatingCube] = @ecs.register_component(
  debug_name="examples.stress_tests.many_cubes.RotatingCube",
)

///|
pub impl @ecs.Component for RotatingCube with component() {
  rotating_cube_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@pbr.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let floor_mesh = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(70.0F, 0.1F, 70.0F)),
  )
  let floor_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.17F, 0.2F, 0.23F)),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(floor_mesh),
        @pbr.MeshMaterial3d::new(floor_material),
        @transform.Transform::from_xyz(0.0F, -0.05F, 0.0F),
      ),
    ),
  )

  let cube_mesh = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(0.9F, 0.9F, 0.9F)),
  )
  let cube_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.75F, 0.79F, 0.9F)),
  )
  for z in -GRID_HALF..<GRID_HALF {
    for x in -GRID_HALF..<GRID_HALF {
      let px = float_from_int(x) * GRID_SPACING
      let pz = float_from_int(z) * GRID_SPACING
      ignore(
        commands.spawn(
          (
            @pbr.Mesh3d::new(cube_mesh),
            @pbr.MeshMaterial3d::new(cube_material),
            @transform.Transform::from_xyz(px, 0.45F, pz),
            RotatingCube::{  },
          ),
        ),
      )
    }
  }

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::default()
        .with_intensity(800000.0F)
        .with_range(120.0F)
        .with_shadow_maps_enabled(true),
        @transform.Transform::from_xyz(16.0F, 30.0F, 12.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@sprite.Color::white(), 18000.0F, true),
        @transform.Transform::from_xyz(-10.0F, 20.0F, -10.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(20.0F, 18.0F, 20.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn rotate_cubes(
  time : @app.Res[@time.Time[Unit]],
  cubes : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[RotatingCube]],
) -> Unit {
  let dt = time.get().delta_secs()
  let spin = @math.Quat::from_rotation_y(dt * 0.6F)
  try! cubes.for_each(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.rotation = spin.mul(transform_ref.val.rotation)
  })
}

///|
fn move_camera(
  time : @app.Res[@time.Time[Unit]],
  cameras : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[@pbr.Camera3d]],
) -> Unit {
  let seconds = time.get().elapsed_secs()
  let radius = 26.0F
  let x = @math.cos(seconds * 0.22F) * radius
  let z = @math.sin(seconds * 0.22F) * radius
  let y = 10.0F + @math.sin(seconds * 0.7F) * 4.0F
  try! cameras.for_each(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val = @transform.Transform::from_xyz(x, y, z).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(
    [
      ..@mgstudio.default_plugins(),
      @diagnostic.frame_time_diagnostics_plugin,
      @diagnostic.log_diagnostics_plugin,
    ],
  )
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate_cubes)))
  .add_systems(@app.Update, @app.system(@app.system_param2(move_camera)))
  .run()
}
