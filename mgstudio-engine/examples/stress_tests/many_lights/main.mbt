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
const N_LIGHTS : Int = 3500

///|
const LIGHT_SPHERE_RADIUS : Float = 42.0F

///|
const CAMERA_RADIUS : Float = 62.0F

///|
const GOLDEN_ANGLE : Float = 2.399963229728653F

///|
struct LightStats {
  mut print_timer : Float
}

///|
let light_stats_key : @ecs.ResourceKey[LightStats] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_lights.LightStats",
)

///|
impl @app.Resource for LightStats with resource() {
  light_stats_key
}

///|
fn LightStats::default() -> LightStats {
  { print_timer: 0.0F }
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn max_float(a : Float, b : Float) -> Float {
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
  let room_mesh = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(90.0F, 0.2F, 90.0F)),
  )
  let room_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.2F, 0.2F, 0.22F)),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(room_mesh),
        @pbr.MeshMaterial3d::new(room_material),
        @transform.Transform::from_xyz(0.0F, -12.0F, 0.0F),
      ),
    ),
  )

  let marker_mesh = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(8.0F, 8.0F, 8.0F)),
  )
  let marker_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(1.0F, 0.08F, 0.58F)),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(marker_mesh),
        @pbr.MeshMaterial3d::new(marker_material),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@sprite.Color::white(), 15000.0F, false),
        @transform.Transform::from_xyz(15.0F, 25.0F, 15.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  for i in 0..<N_LIGHTS {
    let fi = float_from_int(i)
    let totalf = float_from_int(N_LIGHTS)
    let y = 1.0F - 2.0F * (fi + 0.5F) / totalf
    let r = @math.sqrt(max_float(0.0F, 1.0F - y * y))
    let theta = fi * GOLDEN_ANGLE
    let x = @math.cos(theta) * r
    let z = @math.sin(theta) * r
    ignore(
      commands.spawn(
        (
          @pbr.PointLight::default()
          .with_range(3.5F)
          .with_intensity(2200.0F)
          .with_color(@sprite.Color::hsl(float_from_int(i % 360), 1.0F, 0.5F)),
          @transform.Transform::from_xyz(
            x * LIGHT_SPHERE_RADIUS,
            y * LIGHT_SPHERE_RADIUS,
            z * LIGHT_SPHERE_RADIUS,
          ),
        ),
      ),
    )
  }

  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(CAMERA_RADIUS, 0.0F, 0.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn move_camera(
  time : @app.Res[@time.Time[Unit]],
  camera : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[@pbr.Camera3d]],
) -> Unit {
  let t = time.get().elapsed_secs() * 0.15F
  let x = @math.cos(t) * CAMERA_RADIUS
  let z = @math.sin(t) * CAMERA_RADIUS
  let y = @math.sin(t * 0.8F) * 16.0F
  try! camera.for_each(fn(_entity, transform) {
    transform.get_ref().val = @transform.Transform::from_xyz(x, y, z).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    )
  })
}

///|
fn print_light_count(
  time : @app.Res[@time.Time[Unit]],
  stats : @app.ResMut[LightStats],
  lights : @ecs.Query[@ecs.Comp[@pbr.PointLight], @ecs.All],
) -> Unit {
  let stats_ref = stats.get_ref()
  stats_ref.val.print_timer += time.get().delta_secs()
  if stats_ref.val.print_timer < 1.0F {
    return
  }
  stats_ref.val.print_timer -= 1.0F
  println("Lights: \{lights.count()}")
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(LightStats::default())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(
    [
      ..@mgstudio.default_plugins(),
      @diagnostic.frame_time_diagnostics_plugin,
      @diagnostic.log_diagnostics_plugin,
    ],
  )
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(move_camera)))
  .add_systems(@app.Update, @app.system(@app.system_param3(print_light_count)))
  .run()
}
