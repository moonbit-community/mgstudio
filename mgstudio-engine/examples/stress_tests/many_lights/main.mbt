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
  print_timer : Float
}

///|
let light_stats_key : @ecs.ResourceKey[LightStats] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_lights.LightStats",
)

///|
impl @app.Resource for LightStats with fn resource() {
  light_stats_key
}

///|
fn LightStats::LightStats() -> LightStats {
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
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let room_mesh = meshes.peek()
    |> @pbr.add_mesh(@math.Cuboid::new(90.0F, 0.2F, 90.0F))
  let room_material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@color.Color::srgb(0.2F, 0.2F, 0.22F)),
    )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(room_mesh),
        @pbr.MeshMaterial3dTyped::new(room_material),
        @transform.Transform::from_xyz(0.0F, -12.0F, 0.0F),
      ),
    ),
  )

  let marker_mesh = meshes.peek()
    |> @pbr.add_mesh(@math.Cuboid::new(8.0F, 8.0F, 8.0F))
  let marker_material = materials
    .peek()
    .add(@pbr.StandardMaterial::from_color(@palettes.css_deep_pink()))
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(marker_mesh),
        @pbr.MeshMaterial3dTyped::new(marker_material),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@color.Color::white(), 15000.0F, false),
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
          @pbr.PointLight::PointLight()
          .with_range(3.5F)
          .with_intensity(2200.0F)
          .with_color(@color.Color::hsl(float_from_int(i % 360), 1.0F, 0.5F)),
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
        @camera.Camera3d::Camera3d(),
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
  camera : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[@camera.Camera3d],
  ],
) -> Unit {
  let t = time.get().elapsed_secs() * 0.15F
  let x = @math.cos(t) * CAMERA_RADIUS
  let z = @math.sin(t) * CAMERA_RADIUS
  let y = @math.sin(t * 0.8F) * 16.0F
  try! camera.for_each(fn(_entity, transform) {
    transform.set(
      @transform.Transform::from_xyz(x, y, z).looking_at(
        @math.Vec3::new(0.0F, 0.0F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
  })
}

///|
fn print_light_count(
  time : @app.Res[@time.Time[Unit]],
  stats : @app.ResMut[LightStats],
  lights : @ecs.Query[@ecs.Read[@pbr.PointLight], @ecs.All],
) -> Unit {
  let next_timer = stats.get().print_timer + time.get().delta_secs()
  if next_timer < 1.0F {
    stats.set({ print_timer: next_timer })
    return
  }
  stats.set({ print_timer: next_timer - 1.0F })
  println("Lights: \{lights.count()}")
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(LightStats::LightStats())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(@diagnostic.StressDiagnosticsPlugin::StressDiagnosticsPlugin())
  .add_systems_param3(Startup, setup)
  .add_systems_param2(Update, move_camera)
  .add_systems_param3(Update, print_light_count)
  .run()
}
