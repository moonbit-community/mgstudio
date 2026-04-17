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
const GRID_HALF : Int = 10

///|
const GRID_SPACING : Float = 1.5F

///|
struct SpinCube {}

///|
let spin_cube_key : @ecs.ComponentKey[SpinCube] = @ecs.register_component(
  debug_name="examples.testbed.3d.SpinCube",
)

///|
pub impl @ecs.Component for SpinCube with component() {
  spin_cube_key
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
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(80.0F, 0.1F, 80.0F)),
  )
  let floor_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.16F, 0.19F, 0.23F)),
  )
  ignore(
    commands.spawn(
      (@pbr.Mesh3d::new(floor_mesh), @pbr.MeshMaterial3d::new(floor_material)),
    ),
  )

  let cube_mesh = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(0.9F, 0.9F, 0.9F)),
  )
  let cube_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.75F, 0.8F, 0.95F)),
  )
  for z in -GRID_HALF..<GRID_HALF {
    for x in -GRID_HALF..<GRID_HALF {
      ignore(
        commands.spawn(
          (
            @pbr.Mesh3d::new(cube_mesh),
            @pbr.MeshMaterial3d::new(cube_material),
            @transform.Transform::from_xyz(
              float_from_int(x) * GRID_SPACING,
              0.45F,
              float_from_int(z) * GRID_SPACING,
            ),
            SpinCube::{  },
          ),
        ),
      )
    }
  }

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::default()
        .with_intensity(750000.0F)
        .with_shadow_maps_enabled(true),
        @transform.Transform::from_xyz(18.0F, 28.0F, 12.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(20.0F, 18.0F, 24.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn spin_cubes(
  time : @app.Res[@time.Time[Unit]],
  cubes : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[SpinCube]],
) -> Unit {
  let rot = @math.Quat::from_rotation_y(time.get().delta_secs() * 0.7F)
  try! cubes.for_each(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.rotation = rot.mul(transform_ref.val.rotation)
  })
}

///|
fn orbit_camera(
  time : @app.Res[@time.Time[Unit]],
  cameras : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[@pbr.Camera3d]],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! cameras.for_each(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val = @transform.Transform::from_xyz(
      @math.cos(t * 0.25F) * 26.0F,
      12.0F + @math.sin(t * 0.4F) * 4.0F,
      @math.sin(t * 0.25F) * 26.0F,
    ).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_plugins(@diagnostic.FrameTimeDiagnosticsPlugin::default())
  .add_plugins(@diagnostic.LogDiagnosticsPlugin::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(spin_cubes)))
  .add_systems(@app.Update, @app.system(@app.system_param2(orbit_camera)))
  .run()
}
