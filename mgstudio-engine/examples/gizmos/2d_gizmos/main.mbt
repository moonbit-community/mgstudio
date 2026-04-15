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
struct MyRoundGizmos {}

///|
impl Default for MyRoundGizmos with default() {
  MyRoundGizmos::{  }
}

///|
impl @sprite.GizmoConfigGroup for MyRoundGizmos with gizmo_config_group_marker(
  _self,
) {

}

///|
fn clamp_float(value : Float, min : Float, max : Float) -> Float {
  if value < min {
    min
  } else if value > max {
    max
  } else {
    value
  }
}

///|
fn gizmo_config_with_line_width(
  config : @gizmos.GizmoConfig,
  width : Float,
) -> @gizmos.GizmoConfig {
  { ..config, line: { ..config.line, width, } }
}

///|
fn gizmo_config_with_line_style(
  config : @gizmos.GizmoConfig,
  style : @gizmos.GizmoLineStyle,
) -> @gizmos.GizmoConfig {
  { ..config, line: { ..config.line, style, } }
}

///|
fn gizmo_config_with_line_joints(
  config : @gizmos.GizmoConfig,
  joints : @gizmos.GizmoLineJoint,
) -> @gizmos.GizmoConfig {
  { ..config, line: { ..config.line, joints, } }
}

///|
fn gizmo_config_toggle_enabled(
  config : @gizmos.GizmoConfig,
) -> @gizmos.GizmoConfig {
  { ..config, enabled: !config.enabled }
}

///|
fn cycle_line_style_forward(
  style : @gizmos.GizmoLineStyle,
) -> @gizmos.GizmoLineStyle {
  match style {
    Solid => Dotted
    Dotted => Dashed(gap_scale=3.0F, line_scale=5.0F)
    Dashed(..) => Solid
  }
}

///|
fn cycle_line_style_backward(
  style : @gizmos.GizmoLineStyle,
) -> @gizmos.GizmoLineStyle {
  match style {
    Solid => Dashed(gap_scale=3.0F, line_scale=5.0F)
    Dotted => Solid
    Dashed(..) => Dotted
  }
}

///|
fn cycle_line_joint_forward(
  joint : @gizmos.GizmoLineJoint,
) -> @gizmos.GizmoLineJoint {
  match joint {
    None => Bevel
    Bevel => Miter
    Miter => Round(4)
    Round(_) => None
  }
}

///|
fn cycle_line_joint_backward(
  joint : @gizmos.GizmoLineJoint,
) -> @gizmos.GizmoLineJoint {
  match joint {
    None => Round(4)
    Bevel => None
    Miter => Bevel
    Round(_) => Miter
  }
}

///|
fn wave_points(seconds : Float) -> Array[(@math.Vec2, @sprite.Color)] {
  let points : Array[(@math.Vec2, @sprite.Color)] = []
  let steps = 64
  for i in 0..<=steps {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(steps.to_double())
    let x = (t - 0.5F) * 600.0F
    let y = @math.sin(x / 25.0F + seconds) * 100.0F
    let color = if t < 0.5F {
      @sprite.Color::srgb(0.0F, 0.8F, 0.8F)
    } else {
      @sprite.Color::srgb(1.0F, 0.2F, 0.6F)
    }
    points.push((@math.Vec2::new(x, y), color))
  }
  points
}

///|
fn spawn_help_overlay(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(12.0F))
        .with_top(@ui.Val::Px(12.0F)),
        @text.Text::new(
          "Arrow Left/Right: straight gizmo line width\nArrow Up/Down: round gizmo line width\n1 / 2: toggle straight / round gizmos\nU / I: cycle line styles\nJ / K: cycle line joins\nSpace: pause virtual time",
        ),
        @text.TextFont::default().with_font(font).with_font_size(18.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  config_store : @app.ResMut[@gizmos.GizmoConfigStore],
) -> Unit {
  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default())),
  )
  spawn_help_overlay(commands, asset_server)

  let store_ref = config_store.get_ref()
  let (default_config, _default_group) = store_ref.val.config_mut(
    @gizmos.DefaultGizmoConfigGroup::default(),
  )
  let current_default = default_config.val
  default_config.val = gizmo_config_with_line_joints(
    gizmo_config_with_line_width(current_default, 2.0F),
    None,
  )

  let (round_config, _round_group) = store_ref.val.config_mut(
    MyRoundGizmos::default(),
  )
  let current_round = round_config.val
  round_config.val = gizmo_config_with_line_joints(
    gizmo_config_with_line_width(current_round, 4.0F),
    Round(4),
  )
}

///|
fn draw_example_collection(
  gizmos : @gizmos.Gizmos[@gizmos.DefaultGizmoConfigGroup],
  my_gizmos : @gizmos.Gizmos[MyRoundGizmos],
  time : @app.Res[@time.Time[@time.Virtual]],
) -> Unit {
  let seconds = time.get().elapsed_secs()
  let sin_t_scaled = @math.sin(seconds) * 50.0F

  gizmos.line_2d(
    @math.Vec2::new(0.0F, -sin_t_scaled),
    @math.Vec2::new(-80.0F, -80.0F),
    @sprite.Color::srgb(1.0F, 0.0F, 0.0F),
  )
  gizmos.ray_2d(
    @math.Vec2::new(0.0F, sin_t_scaled),
    @math.Vec2::new(80.0F, 80.0F),
    @sprite.Color::srgb(0.0F, 1.0F, 0.0F),
  )

  ignore(
    gizmos
    .grid_2d(
      @gizmos.Isometry2d::identity(),
      @math.IVec2::new(16, 9),
      @math.Vec2::new(80.0F, 80.0F),
      @sprite.Color::srgb(0.05F, 0.05F, 0.05F),
    )
    .outer_edges(),
  )

  gizmos.linestrip_gradient_2d([
    (@math.Vec2::new(0.0F, 300.0F), @sprite.Color::srgb(0.0F, 0.0F, 1.0F)),
    (@math.Vec2::new(-255.0F, -155.0F), @sprite.Color::srgb(1.0F, 0.0F, 0.0F)),
    (@math.Vec2::new(255.0F, -155.0F), @sprite.Color::srgb(0.0F, 1.0F, 0.0F)),
    (@math.Vec2::new(0.0F, 300.0F), @sprite.Color::srgb(0.0F, 0.0F, 1.0F)),
  ])

  gizmos.rect_2d(
    @gizmos.Isometry2d::identity(),
    @math.Vec2::new(650.0F, 650.0F),
    @sprite.Color::black(),
  )
  gizmos.cross_2d(
    @gizmos.Isometry2d::new(@math.Vec2::new(-160.0F, 120.0F), 0.0F),
    12.0F,
    @sprite.Color::srgb(1.0F, 0.0F, 1.0F),
  )
  gizmos.curve_gradient_2d(wave_points(seconds))

  ignore(
    my_gizmos
    .rounded_rect_2d(
      @gizmos.Isometry2d::identity(),
      @math.Vec2::new(630.0F, 630.0F),
      @sprite.Color::black(),
    )
    .corner_radius(@math.cos(seconds / 3.0F) * 100.0F),
  )
  ignore(
    my_gizmos
    .circle_2d(
      @gizmos.Isometry2d::identity(),
      300.0F,
      @sprite.Color::srgb(0.0F, 0.0F, 0.5F),
    )
    .resolution(64),
  )
  ignore(
    my_gizmos.ellipse_2d(
      @gizmos.Isometry2d::new(@math.Vec2::new(0.0F, 0.0F), seconds),
      @math.Vec2::new(100.0F, 200.0F),
      @sprite.Color::srgb(0.6F, 0.8F, 0.2F),
    ),
  )
  ignore(
    my_gizmos.arc_2d(
      @gizmos.Isometry2d::new(@math.Vec2::new(0.0F, 0.0F), sin_t_scaled / 10.0F),
      @math.pi_half(),
      310.0F,
      @sprite.Color::srgb(1.0F, 0.27F, 0.0F),
    ),
  )
  ignore(
    my_gizmos.arc_2d(
      @gizmos.Isometry2d::identity(),
      @math.pi_half(),
      80.0F,
      @sprite.Color::srgb(1.0F, 0.27F, 0.0F),
    ),
  )
  ignore(
    my_gizmos.long_arc_2d_between(
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(20.0F, 0.0F),
      @math.Vec2::new(0.0F, 20.0F),
      @sprite.Color::srgb(1.0F, 0.27F, 0.0F),
    ),
  )
  ignore(
    my_gizmos.short_arc_2d_between(
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(40.0F, 0.0F),
      @math.Vec2::new(0.0F, 40.0F),
      @sprite.Color::srgb(1.0F, 0.27F, 0.0F),
    ),
  )

  ignore(
    gizmos
    .arrow_2d(
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(
        @math.cos(-sin_t_scaled / 10.0F) * 50.0F,
        @math.sin(-sin_t_scaled / 10.0F) * 50.0F,
      ),
      @sprite.Color::srgb(1.0F, 1.0F, 0.0F),
    )
    .with_double_end()
    .with_tip_length(10.0F),
  )
}

///|
fn update_config(
  config_store : @app.ResMut[@gizmos.GizmoConfigStore],
  keyboard : @input.ButtonInput[@window.KeyCode],
  real_time : @app.Res[@time.Time[@time.Real]],
  virtual_time : @app.ResMut[@time.Time[@time.Virtual]],
) -> Unit {
  let delta = real_time.get().delta_secs()
  let store_ref = config_store.get_ref()

  let (default_config, _default_group) = store_ref.val.config_mut(
    @gizmos.DefaultGizmoConfigGroup::default(),
  )
  if keyboard.pressed(ArrowRight) {
    let current = default_config.val
    default_config.val = gizmo_config_with_line_width(
      current,
      clamp_float(current.line.width + 5.0F * delta, 0.0F, 50.0F),
    )
  }
  if keyboard.pressed(ArrowLeft) {
    let current = default_config.val
    default_config.val = gizmo_config_with_line_width(
      current,
      clamp_float(current.line.width - 5.0F * delta, 0.0F, 50.0F),
    )
  }
  if keyboard.just_pressed(Digit1) {
    default_config.val = gizmo_config_toggle_enabled(default_config.val)
  }
  if keyboard.just_pressed(KeyU) {
    let current = default_config.val
    default_config.val = gizmo_config_with_line_style(
      current,
      cycle_line_style_forward(current.line.style),
    )
  }
  if keyboard.just_pressed(KeyJ) {
    let current = default_config.val
    default_config.val = gizmo_config_with_line_joints(
      current,
      cycle_line_joint_forward(current.line.joints),
    )
  }

  let (round_config, _round_group) = store_ref.val.config_mut(
    MyRoundGizmos::default(),
  )
  if keyboard.pressed(ArrowUp) {
    let current = round_config.val
    round_config.val = gizmo_config_with_line_width(
      current,
      clamp_float(current.line.width + 5.0F * delta, 0.0F, 50.0F),
    )
  }
  if keyboard.pressed(ArrowDown) {
    let current = round_config.val
    round_config.val = gizmo_config_with_line_width(
      current,
      clamp_float(current.line.width - 5.0F * delta, 0.0F, 50.0F),
    )
  }
  if keyboard.just_pressed(Digit2) {
    round_config.val = gizmo_config_toggle_enabled(round_config.val)
  }
  if keyboard.just_pressed(KeyI) {
    let current = round_config.val
    round_config.val = gizmo_config_with_line_style(
      current,
      cycle_line_style_backward(current.line.style),
    )
  }
  if keyboard.just_pressed(KeyK) {
    let current = round_config.val
    round_config.val = gizmo_config_with_line_joints(
      current,
      cycle_line_joint_backward(current.line.joints),
    )
  }
  if keyboard.just_pressed(Space) {
    let virtual_time_ref = virtual_time.get_ref()
    virtual_time_ref.val = virtual_time_ref.val.toggle()
  }
}

///|
fn main {
  @gizmos.init_gizmo_group(
    @app.App::new(@ecs.World::new()).add_plugins(
      @mgstudio.DefaultPlugins::default(),
    ),
    MyRoundGizmos::default(),
  )
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(draw_example_collection)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param4(update_config)))
  .run()
}
