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
const TWO_PI : Float = 6.283185307179586F

///|
struct Config {
  mut line_count : Int
  mut fancy : Bool
}

///|
let config_key : @ecs.ResourceKey[Config] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_gizmos.Config",
)

///|
impl @app.Resource for Config with resource() {
  config_key
}

///|
fn Config::default() -> Config {
  { line_count: 50000, fancy: false }
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
fn max_float(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(3.0F, 1.0F, 5.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.PointLight::default().with_intensity(300000.0F),
        @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
      ),
    ),
  )
}

///|
fn input(config : @app.ResMut[Config]) -> Unit {
  let config_ref = config.get_ref()
  if @input.key_just_pressed(@input_events.KeyCode::ArrowUp) {
    config_ref.val.line_count += 10000
  }
  if @input.key_just_pressed(@input_events.KeyCode::ArrowDown) {
    config_ref.val.line_count = max_int(config_ref.val.line_count - 10000, 0)
  }
  if @input.key_just_pressed(@input_events.KeyCode::Space) {
    config_ref.val.fancy = !config_ref.val.fancy
  }
}

///|
fn draw_many_lines(
  config : @app.Res[Config],
  time : @app.Res[@time.Time[Unit]],
  gizmos : @gizmos.Gizmos[@gizmos.DefaultGizmoConfigGroup],
) -> Unit {
  let count = config.get().line_count / 10
  if !config.get().fancy {
    for _ in 0..<count {
      gizmos.line_3d(
        @math.Vec3::new(0.0F, -1.0F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
        @sprite.Color::black(),
      )
    }
    return
  }
  let seconds = time.get().elapsed_secs()
  let count_f = max_float(float_from_int(count), 1.0F)
  for i in 0..<count {
    let angle = float_from_int(i) / count_f * TWO_PI
    let x = @math.cos(angle)
    let y = @math.sin(angle)
    let z = @math.sin(seconds)
    let start = @math.Vec3::new(x, y, z)
    let end = @math.Vec3::new(-x, -y, -z)
    gizmos.line_gradient_3d(
      start,
      end,
      @sprite.Color::srgb((x + 1.0F) * 0.5F, (z + 1.0F) * 0.5F, 0.5F),
      @sprite.Color::srgb((-z + 1.0F) * 0.5F, (-y + 1.0F) * 0.5F, 0.5F),
    )
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(Config::default())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_plugins(@diagnostic.StressDiagnosticsPlugin::default())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param(input)))
  .add_systems(@app.Update, @app.system(@app.system_param3(draw_many_lines)))
  .run()
}
