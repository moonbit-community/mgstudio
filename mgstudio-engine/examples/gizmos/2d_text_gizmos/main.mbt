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
const TEXT_COUNT : Int = 50

///|
const START_X : Float = -800.0F

///|
const START_Y : Float = 200.0F

///|
const X_STEP : Float = 250.0F

///|
const Y_STEP : Float = 50.0F

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn label_color(index : Int) -> @sprite.Color {
  match index % 4 {
    0 => @sprite.Color::srgb(1.0F, 0.0F, 0.0F)
    1 => @sprite.Color::srgb(0.0F, 1.0F, 0.0F)
    2 => @sprite.Color::srgb(0.2F, 0.4F, 1.0F)
    _ => @sprite.Color::srgb(1.0F, 0.9F, 0.1F)
  }
}

///|
fn all_glyphs() -> String {
  " !\\\"#$%&'()*\n+,-./012345\n6789:;<=>?@\nABCDEFGHIJK\nLMNOPQRSTUV\nWXYZ[\\\\]^_`a\nbcdefghijkl\nmnopqrstuvw\nxyz{|}~"
}

///|
fn setup(
  commands : @app.Commands,
  config_store : @app.ResMut[@gizmos.GizmoConfigStore],
) -> Unit {
  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default())),
  )
  let store_ref = config_store.get_ref()
  let (config, _group) = store_ref.val.config_mut(
    @gizmos.DefaultGizmoConfigGroup::default(),
  )
  config.val = { ..config.val, line: { ..config.val.line, width: 1.0F } }
}

///|
fn draw_labels(
  gizmos : @gizmos.Gizmos[@gizmos.DefaultGizmoConfigGroup],
  diagnostics : @app.Res[@diagnostic.DiagnosticsStore],
) -> Unit {
  for i in 0..<TEXT_COUNT {
    let row = i / 5
    let col = i % 5
    let position = @math.Vec2::new(
      START_X + float_from_int(col) * X_STEP,
      START_Y - float_from_int(row) * Y_STEP,
    )
    gizmos.text_2d(
      @gizmos.Isometry2d::new(position, 0.03490658503988659F),
      "label \{i.to_string()}",
      25.0F,
      @math.Vec2::new(0.0F, 0.0F),
      label_color(i),
    )
  }

  let fps_value = match
    diagnostics.get().get(@diagnostic.frame_time_diagnostic_fps) {
    Some(diagnostic) => diagnostic.smoothed()
    None => None
  }
  if fps_value is Some(fps) {
    gizmos.text_2d(
      @gizmos.Isometry2d::new(@math.Vec2::new(600.0F, START_Y + 150.0F), 0.0F),
      "fps: \{fps.to_string()}",
      25.0F,
      @math.Vec2::new(0.0F, 0.0F),
      @sprite.Color::white(),
    )
  }

  gizmos.text_2d(
    @gizmos.Isometry2d::new(@math.Vec2::new(-300.0F, START_Y + 200.0F), 0.0F),
    "lxgh",
    150.0F,
    @math.Vec2::new(0.0F, 0.0F),
    @sprite.Color::white(),
  )
}

///|
fn draw_all_glyphs(
  gizmos : @gizmos.Gizmos[@gizmos.DefaultGizmoConfigGroup],
) -> Unit {
  gizmos.text_2d(
    @gizmos.Isometry2d::new(@math.Vec2::new(600.0F, 0.0F), 0.0F),
    all_glyphs(),
    30.0F,
    @math.Vec2::new(0.0F, 0.0F),
    @sprite.Color::white(),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_plugin(@diagnostic.log_diagnostics_plugin)
  .add_plugin(@diagnostic.frame_time_diagnostics_plugin)
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_system_param2(draw_labels)
  .add_system_param(draw_all_glyphs)
  .run()
}
