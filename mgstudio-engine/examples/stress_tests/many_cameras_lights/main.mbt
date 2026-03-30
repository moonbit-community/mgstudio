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
const CAMERA_ROWS : Int = 4

///|
const CAMERA_COLS : Int = 4

///|
const NUM_LIGHTS : Int = 5

///|
struct OrbitCamera {
  mut angle : Float
  radius : Float
  height : Float
}

///|
let orbit_camera_key : @ecs.ComponentKey[OrbitCamera] = @ecs.register_component(
  debug_name="examples.stress_tests.many_cameras_lights.OrbitCamera",
)

///|
pub impl @ecs.Component for OrbitCamera with component() {
  orbit_camera_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@pbr.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let plane_mesh = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(9.0F, 0.1F, 9.0F)),
  )
  let white_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(plane_mesh),
        @pbr.MeshMaterial3d::new(white_material),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      ),
    ),
  )

  let cube_mesh = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F)),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(cube_mesh),
        @pbr.MeshMaterial3d::new(white_material),
        @transform.Transform::from_xyz(0.0F, 0.55F, 0.0F),
      ),
    ),
  )

  for i in 0..<NUM_LIGHTS {
    let angle = float_from_int(i) /
      float_from_int(NUM_LIGHTS) *
      6.283185307179586F
    ignore(
      commands.spawn(
        (
          @pbr.PointLight::default()
          .with_color(
            @sprite.Color::hsl(float_from_int(i) * 72.0F, 1.0F, 0.55F),
          )
          .with_intensity(400000.0F)
          .with_range(32.0F)
          .with_shadow_maps_enabled(true),
          @transform.Transform::from_xyz(
            @math.sin(angle) * 4.0F,
            2.0F,
            @math.cos(angle) * 4.0F,
          ),
        ),
      ),
    )
  }

  let window_width = max_int(@window.window_width(), 1)
  let window_height = max_int(@window.window_height(), 1)
  let cell_width = max_int(window_width / CAMERA_COLS, 1)
  let cell_height = max_int(window_height / CAMERA_ROWS, 1)

  let mut index = 0
  for row in 0..<CAMERA_ROWS {
    for col in 0..<CAMERA_COLS {
      let ratio = float_from_int(index) /
        float_from_int(CAMERA_ROWS * CAMERA_COLS)
      let angle = ratio * 6.283185307179586F
      ignore(
        commands.spawn(
          (
            @pbr.Camera3d::default(),
            @sprite.Camera::default()
            .with_order(index)
            .with_viewport(
              @sprite.Viewport::new(
                @math.IVec2::new(col * cell_width, row * cell_height),
                @math.IVec2::new(cell_width, cell_height),
              ),
            ),
            @transform.Transform::from_xyz(
              @math.sin(angle) * 4.0F,
              2.5F,
              @math.cos(angle) * 4.0F,
            ).looking_at(
              @math.Vec3::new(0.0F, 0.0F, 0.0F),
              @math.Vec3::new(0.0F, 1.0F, 0.0F),
            ),
            OrbitCamera::{ angle, radius: 4.0F, height: 2.5F },
          ),
        ),
      )
      index += 1
    }
  }
}

///|
fn rotate_cameras(
  time : @app.Res[@time.Time[Unit]],
  cameras : @ecs.Query[
    (@ecs.Mut[OrbitCamera], @ecs.Mut[@transform.Transform]),
    @ecs.With[@pbr.Camera3d],
  ],
) -> Unit {
  try! cameras.for_each(fn(_entity, data) {
    let (orbit, transform) = data
    let orbit_ref = orbit.get_ref()
    let transform_ref = transform.get_ref()
    orbit_ref.val.angle += time.get().delta_secs()
    transform_ref.val = @transform.Transform::from_xyz(
      @math.sin(orbit_ref.val.angle) * orbit_ref.val.radius,
      orbit_ref.val.height,
      @math.cos(orbit_ref.val.angle) * orbit_ref.val.radius,
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
  .add_plugins(
    [
      ..@mgstudio.default_plugins(),
      @diagnostic.frame_time_diagnostics_plugin,
      @diagnostic.log_diagnostics_plugin,
    ],
  )
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate_cameras)))
  .run()
}
