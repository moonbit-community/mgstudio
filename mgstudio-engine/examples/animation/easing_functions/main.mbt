// Copyright 2025 International Digital Economy Academy
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
/// Port of `bevy/examples/animation/easing_functions.rs`.
///
/// Baseline parity:
/// - Matches the Bevy function grid layout and color assignment.
/// - Draws per-cell box, easing curve, horizontal progress bar and moving markers.
/// - Shows top-left progress text with the same timing window behavior.

///|
const COLS : Int = 12

///|
const EXTENT_X : Float = 1172.0F

///|
const EXTENT_Y : Float = 520.0F

///|
const PLOT_SIZE_X : Float = 80.0F

///|
const PLOT_SIZE_Y : Float = 80.0F

///|
const SAMPLE_COUNT : Int = 100

///|
const DURATION_SECONDS : Float = 2.5F

///|
const TIME_MARGIN_SECONDS : Float = 0.5F

///|
const MARKER_Z : Float = 1.0F

///|
const LABEL_Z : Float = 2.0F

///|
const PI : Float = 3.141592653589793F

///|
const TWO_PI : Float = 6.283185307179586F

///|
const LOG2_1023 : Float = 9.998590429745329F

///|
const FRAC_1_1023 : Float = 0.0009775171065493646F

///|
pub(all) enum StepJump {
  Start
  End
  None
  Both
}

///|
pub(all) enum EasingFunction {
  SineIn
  QuadraticIn
  CubicIn
  QuarticIn
  QuinticIn
  SmoothStepIn
  SmootherStepIn
  CircularIn
  ExponentialIn
  ElasticIn
  BackIn
  BounceIn
  SineOut
  QuadraticOut
  CubicOut
  QuarticOut
  QuinticOut
  SmoothStepOut
  SmootherStepOut
  CircularOut
  ExponentialOut
  ElasticOut
  BackOut
  BounceOut
  SineInOut
  QuadraticInOut
  CubicInOut
  QuarticInOut
  QuinticInOut
  SmoothStep
  SmootherStep
  CircularInOut
  ExponentialInOut
  ElasticInOut
  BackInOut
  BounceInOut
  Linear
  StepsEnd
  StepsStart
  StepsBoth
  StepsNone
  Elastic50
}

///|
priv struct EaseSpec {
  function : EasingFunction
  label : String
}

///|
priv struct PlotEntry {
  function : EasingFunction
  color : @render2d.Color
  center : @math.Vec2
  value_bar_entity : @core.Entity
  progress_dot_entity : @core.Entity
}

///|
priv struct EasingFunctionsState {
  mut plots : Array[PlotEntry]
  mut progress_text : @text.TextHandle?
}

///|
let easing_state : Ref[EasingFunctionsState] = Ref::new(EasingFunctionsState::{
  plots: [],
  progress_text: None,
})

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(display_curves)
  .run()
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  easing_state.val.plots = []
  easing_state.val.progress_text = None

  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let label_font = @text.TextFont::default()
    .with_font(font)
    .with_font_size(10.0F)

  let rows = easing_rows()
  let max_rows = rows.length()

  let half_extent_x = EXTENT_X / 2.0F
  let half_extent_y = EXTENT_Y / 2.0F
  let half_size_x = PLOT_SIZE_X / 2.0F
  let half_size_y = PLOT_SIZE_Y / 2.0F

  for row in 0..<rows.length() {
    let functions = rows[row]
    for col in 0..<functions.length() {
      let spec = functions[col]
      let hue = float_from_int(col) / float_from_int(COLS) * 360.0F
      let color = @render2d.Color::hsl(hue, 0.8F, 0.75F)
      let center = @math.Vec2::new(
        -half_extent_x +
        EXTENT_X / float_from_int(COLS - 1) * float_from_int(col),
        half_extent_y -
        EXTENT_Y / float_from_int(max_rows - 1) * float_from_int(row),
      )

      let value_bar_entity = spawn_marker(
        world,
        5.0F,
        color,
        @math.Vec2::new(center.x + half_size_x + 5.0F, center.y - half_size_y),
      )
      let progress_dot_entity = spawn_marker(
        world,
        4.0F,
        color,
        @math.Vec2::new(center.x - half_size_x, center.y - half_size_y),
      )

      spawn_label(
        spec.label,
        label_font,
        color,
        @math.Vec2::new(center.x, center.y - half_size_y - 15.0F),
      )

      easing_state.val.plots.push(PlotEntry::{
        function: spec.function,
        color,
        center,
        value_bar_entity,
        progress_dot_entity,
      })
    }
  }

  easing_state.val.progress_text = Some(spawn_progress_text(world))
}

///|
fn display_curves(world : @ecs_world.World) -> Unit {
  if easing_state.val.plots.length() == 0 {
    return
  }

  let cycle_seconds = DURATION_SECONDS + TIME_MARGIN_SECONDS * 2.0F
  let elapsed = @time.time_elapsed_seconds()
  let loops = (elapsed / cycle_seconds).to_int()
  let loop_offset = Float::from_double(loops.to_double()) * cycle_seconds
  let cycle_elapsed = elapsed - loop_offset
  let now = clamp01((cycle_elapsed - TIME_MARGIN_SECONDS) / DURATION_SECONDS)

  if easing_state.val.progress_text is Some(progress_text) {
    @text.text_set_content(progress_text, format_progress(now))
  }

  let gizmos = @render2d.Gizmos::get()
  let half_size_x = PLOT_SIZE_X / 2.0F
  let half_size_y = PLOT_SIZE_Y / 2.0F
  let tick = world.read_change_tick()
  let transform_store = world.get_transform_store()

  for plot in easing_state.val.plots {
    let center = plot.center

    let top_right = @math.Vec2::new(
      center.x + half_size_x,
      center.y + half_size_y,
    )
    let top_left = @math.Vec2::new(
      center.x - half_size_x,
      center.y + half_size_y,
    )
    let bottom_left = @math.Vec2::new(
      center.x - half_size_x,
      center.y - half_size_y,
    )
    let bottom_right = @math.Vec2::new(
      center.x + half_size_x,
      center.y - half_size_y,
    )

    gizmos.linestrip_2d(
      [top_right, top_left, bottom_left, bottom_right, top_right],
      color_darker(plot.color, 0.4F),
    )

    let curve_points : Array[@math.Vec2] = []
    for i in 0..<SAMPLE_COUNT {
      let x = if SAMPLE_COUNT <= 1 {
        0.0F
      } else {
        float_from_int(i) / float_from_int(SAMPLE_COUNT - 1)
      }
      let y = sample_easing(plot.function, x)
      curve_points.push(
        @math.Vec2::new(
          center.x - half_size_x + x * PLOT_SIZE_X,
          center.y - half_size_y + y * PLOT_SIZE_Y,
        ),
      )
    }
    gizmos.curve_2d(curve_points, plot.color)

    let y_progress = sample_easing(plot.function, now) * PLOT_SIZE_Y

    let value_bar_position = @math.Vec2::new(
      center.x + half_size_x + 5.0F,
      center.y - half_size_y + y_progress,
    )
    let progress_dot_position = @math.Vec2::new(
      center.x - half_size_x + now * PLOT_SIZE_X,
      center.y - half_size_y + y_progress,
    )

    transform_store.set(
      plot.value_bar_entity,
      transform_from_position(value_bar_position, MARKER_Z),
      tick,
    )
    |> ignore
    transform_store.set(
      plot.progress_dot_entity,
      transform_from_position(progress_dot_position, MARKER_Z),
      tick,
    )
    |> ignore

    gizmos.linestrip_2d(
      [
        @math.Vec2::new(
          center.x - half_size_x,
          center.y - half_size_y + y_progress,
        ),
        @math.Vec2::new(
          center.x + half_size_x,
          center.y - half_size_y + y_progress,
        ),
      ],
      color_darker(plot.color, 0.2F),
    )
  }
}

///|
fn easing_rows() -> Array[Array[EaseSpec]] {
  [
    [
      ease_spec(EasingFunction::SineIn, "SineIn"),
      ease_spec(EasingFunction::QuadraticIn, "QuadraticIn"),
      ease_spec(EasingFunction::CubicIn, "CubicIn"),
      ease_spec(EasingFunction::QuarticIn, "QuarticIn"),
      ease_spec(EasingFunction::QuinticIn, "QuinticIn"),
      ease_spec(EasingFunction::SmoothStepIn, "SmoothStepIn"),
      ease_spec(EasingFunction::SmootherStepIn, "SmootherStepIn"),
      ease_spec(EasingFunction::CircularIn, "CircularIn"),
      ease_spec(EasingFunction::ExponentialIn, "ExponentialIn"),
      ease_spec(EasingFunction::ElasticIn, "ElasticIn"),
      ease_spec(EasingFunction::BackIn, "BackIn"),
      ease_spec(EasingFunction::BounceIn, "BounceIn"),
    ],
    [
      ease_spec(EasingFunction::SineOut, "SineOut"),
      ease_spec(EasingFunction::QuadraticOut, "QuadraticOut"),
      ease_spec(EasingFunction::CubicOut, "CubicOut"),
      ease_spec(EasingFunction::QuarticOut, "QuarticOut"),
      ease_spec(EasingFunction::QuinticOut, "QuinticOut"),
      ease_spec(EasingFunction::SmoothStepOut, "SmoothStepOut"),
      ease_spec(EasingFunction::SmootherStepOut, "SmootherStepOut"),
      ease_spec(EasingFunction::CircularOut, "CircularOut"),
      ease_spec(EasingFunction::ExponentialOut, "ExponentialOut"),
      ease_spec(EasingFunction::ElasticOut, "ElasticOut"),
      ease_spec(EasingFunction::BackOut, "BackOut"),
      ease_spec(EasingFunction::BounceOut, "BounceOut"),
    ],
    [
      ease_spec(EasingFunction::SineInOut, "SineInOut"),
      ease_spec(EasingFunction::QuadraticInOut, "QuadraticInOut"),
      ease_spec(EasingFunction::CubicInOut, "CubicInOut"),
      ease_spec(EasingFunction::QuarticInOut, "QuarticInOut"),
      ease_spec(EasingFunction::QuinticInOut, "QuinticInOut"),
      ease_spec(EasingFunction::SmoothStep, "SmoothStep"),
      ease_spec(EasingFunction::SmootherStep, "SmootherStep"),
      ease_spec(EasingFunction::CircularInOut, "CircularInOut"),
      ease_spec(EasingFunction::ExponentialInOut, "ExponentialInOut"),
      ease_spec(EasingFunction::ElasticInOut, "ElasticInOut"),
      ease_spec(EasingFunction::BackInOut, "BackInOut"),
      ease_spec(EasingFunction::BounceInOut, "BounceInOut"),
    ],
    [
      ease_spec(EasingFunction::Linear, "Linear"),
      ease_spec(EasingFunction::StepsEnd, "Steps(4, End)"),
      ease_spec(EasingFunction::StepsStart, "Steps(4, Start)"),
      ease_spec(EasingFunction::StepsBoth, "Steps(4, Both)"),
      ease_spec(EasingFunction::StepsNone, "Steps(4, None)"),
      ease_spec(EasingFunction::Elastic50, "Elastic(50.0)"),
    ],
  ]
}

///|
fn ease_spec(function : EasingFunction, label : String) -> EaseSpec {
  EaseSpec::{ function, label }
}

///|
fn spawn_marker(
  world : @ecs_world.World,
  size : Float,
  color : @render2d.Color,
  position : @math.Vec2,
) -> @core.Entity {
  @render2d.Mesh2dBundle::new(
    @render2d.Mesh2d::from_rectangle(@render2d.Rectangle::new(size, size)),
    @render2d.ColorMaterial::new(color),
    transform_from_position(position, MARKER_Z),
  ).spawn(world)
}

///|
fn spawn_label(
  label : String,
  font : @text.TextFont,
  color : @render2d.Color,
  position : @math.Vec2,
) -> Unit {
  @text.Text2dBundle::new(
    @text.Text2d::new(label),
    font,
    transform_from_position(position, LABEL_Z),
  )
  .with_color(@text.TextColor::new(color))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
  .spawn()
  |> ignore
}

///|
fn spawn_progress_text(world : @ecs_world.World) -> @text.TextHandle {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text_handle = @text.Text2dBundle::new(
      @text.Text2d::new("Progress: 0.00"),
      @text.TextFont::default().with_font(font).with_font_size(20.0F),
      @math.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@render2d.Color::white()))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()

  let tick = world.read_change_tick()
  let root = world.spawn_empty()
  world.get_ui_root_store().insert(root, @ui.UiRoot::default(), tick)
  world
  .get_node_store()
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )

  let text_entity = world.spawn_empty()
  world
  .get_parent_store()
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .get_node_store()
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .get_ui_text_store()
  .insert(text_entity, @ui.UiText::new(text_handle), tick)

  text_handle
}

///|
fn sample_easing(function : EasingFunction, t : Float) -> Float {
  let x = clamp01(t)
  match function {
    Linear => x
    QuadraticIn => x * x
    QuadraticOut => 1.0F - (1.0F - x) * (1.0F - x)
    QuadraticInOut =>
      if x < 0.5F {
        2.0F * x * x
      } else {
        1.0F - (-2.0F * x + 2.0F) * (-2.0F * x + 2.0F) / 2.0F
      }
    CubicIn => x * x * x
    CubicOut => 1.0F - (1.0F - x) * (1.0F - x) * (1.0F - x)
    CubicInOut =>
      if x < 0.5F {
        4.0F * x * x * x
      } else {
        1.0F -
        (-2.0F * x + 2.0F) * (-2.0F * x + 2.0F) * (-2.0F * x + 2.0F) / 2.0F
      }
    QuarticIn => x * x * x * x
    QuarticOut => {
      let one_minus = 1.0F - x
      1.0F - one_minus * one_minus * one_minus * one_minus
    }
    QuarticInOut =>
      if x < 0.5F {
        8.0F * x * x * x * x
      } else {
        let v = -2.0F * x + 2.0F
        1.0F - v * v * v * v / 2.0F
      }
    QuinticIn => x * x * x * x * x
    QuinticOut => {
      let one_minus = 1.0F - x
      1.0F - one_minus * one_minus * one_minus * one_minus * one_minus
    }
    QuinticInOut =>
      if x < 0.5F {
        16.0F * x * x * x * x * x
      } else {
        let v = -2.0F * x + 2.0F
        1.0F - v * v * v * v * v / 2.0F
      }
    SmoothStepIn => (1.5F - 0.5F * x) * x * x
    SmoothStepOut => (1.5F + -0.5F * x * x) * x
    SmoothStep => (3.0F - 2.0F * x) * x * x
    SmootherStepIn => (2.5F + (-1.875F + 0.375F * x) * x) * x * x * x
    SmootherStepOut => (1.875F + (-1.25F + 0.375F * x * x) * x * x) * x
    SmootherStep => (10.0F + (-15.0F + 6.0F * x) * x) * x * x * x
    SineIn => 1.0F - @math.cos(x * PI / 2.0F)
    SineOut => @math.sin(x * PI / 2.0F)
    SineInOut => -(@math.cos(PI * x) - 1.0F) / 2.0F
    CircularIn => 1.0F - @math.sqrt(1.0F - x * x)
    CircularOut => @math.sqrt(1.0F - (x - 1.0F) * (x - 1.0F))
    CircularInOut =>
      if x < 0.5F {
        (1.0F - @math.sqrt(1.0F - 2.0F * x * (2.0F * x))) / 2.0F
      } else {
        (@math.sqrt(1.0F - (-2.0F * x + 2.0F) * (-2.0F * x + 2.0F)) + 1.0F) /
        2.0F
      }
    ExponentialIn => @math.pow(2.0F, 10.0F * x - LOG2_1023) - FRAC_1_1023
    ExponentialOut =>
      FRAC_1_1023 + 1.0F - @math.pow(2.0F, -10.0F * x - (LOG2_1023 - 10.0F))
    ExponentialInOut =>
      if x < 0.5F {
        @math.pow(2.0F, 20.0F * x - (LOG2_1023 + 1.0F)) - FRAC_1_1023 / 2.0F
      } else {
        FRAC_1_1023 / 2.0F +
        1.0F -
        @math.pow(2.0F, -20.0F * x - (LOG2_1023 - 19.0F))
      }
    ElasticIn =>
      -@math.pow(2.0F, 10.0F * x - 10.0F) *
      @math.sin((x * 10.0F - 10.75F) * 2.0F * PI / 3.0F)
    ElasticOut =>
      @math.pow(2.0F, -10.0F * x) *
      @math.sin((x * 10.0F - 0.75F) * 2.0F * PI / 3.0F) +
      1.0F
    ElasticInOut => {
      let c = TWO_PI / 4.5F
      if x < 0.5F {
        -@math.pow(2.0F, 20.0F * x - 10.0F) *
        @math.sin((x * 20.0F - 11.125F) * c) /
        2.0F
      } else {
        @math.pow(2.0F, -20.0F * x + 10.0F) *
        @math.sin((x * 20.0F - 11.125F) * c) /
        2.0F +
        1.0F
      }
    }
    BackIn => {
      let c = 1.70158F
      (c + 1.0F) * x * x * x - c * x * x
    }
    BackOut => {
      let c = 1.70158F
      let d = x - 1.0F
      1.0F + (c + 1.0F) * d * d * d + c * d * d
    }
    BackInOut => {
      let c1 = 1.70158F
      let c2 = c1 + 1.525F
      if x < 0.5F {
        2.0F * x * (2.0F * x) * ((c2 + 1.0F) * 2.0F * x - c2) / 2.0F
      } else {
        (
          (2.0F * x - 2.0F) *
          (2.0F * x - 2.0F) *
          ((c2 + 1.0F) * (2.0F * x - 2.0F) + c2) +
          2.0F
        ) /
        2.0F
      }
    }
    BounceIn => 1.0F - bounce_out(1.0F - x)
    BounceOut => bounce_out(x)
    BounceInOut =>
      if x < 0.5F {
        (1.0F - bounce_out(1.0F - 2.0F * x)) / 2.0F
      } else {
        (1.0F + bounce_out(2.0F * x - 1.0F)) / 2.0F
      }
    StepsEnd => steps(4, StepJump::End, x)
    StepsStart => steps(4, StepJump::Start, x)
    StepsBoth => steps(4, StepJump::Both, x)
    StepsNone => steps(4, StepJump::None, x)
    Elastic50 => {
      let omega = 50.0F
      1.0F -
      (1.0F - x) *
      (1.0F - x) *
      (2.0F * @math.sin(omega * x) / omega + @math.cos(omega * x))
    }
  }
}

///|
fn steps(num_steps : Int, jump_at : StepJump, t : Float) -> Float {
  let (a, b) = match jump_at {
    Start => (1, 0)
    End => (0, 0)
    None => (0, -1)
    Both => (1, 1)
  }
  let current_step = (clamp01(t) * float_from_int(num_steps)).to_int() + a
  let step_size = max_int(num_steps + b, 1)
  clamp01(float_from_int(current_step) / float_from_int(step_size))
}

///|
fn bounce_out(t : Float) -> Float {
  if t < 4.0F / 11.0F {
    121.0F * t * t / 16.0F
  } else if t < 8.0F / 11.0F {
    363.0F / 40.0F * t * t - 99.0F / 10.0F * t + 17.0F / 5.0F
  } else if t < 9.0F / 10.0F {
    4356.0F / 361.0F * t * t - 35442.0F / 1805.0F * t + 16061.0F / 1805.0F
  } else {
    54.0F / 5.0F * t * t - 513.0F / 25.0F * t + 268.0F / 25.0F
  }
}

///|
fn color_darker(color : @render2d.Color, factor : Float) -> @render2d.Color {
  let safe_factor = clamp(factor, 0.0F, 1.0F)
  @render2d.Color::new(
    color.r * (1.0F - safe_factor),
    color.g * (1.0F - safe_factor),
    color.b * (1.0F - safe_factor),
    color.a,
  )
}

///|
fn format_progress(now : Float) -> String {
  let scaled = (clamp01(now) * 100.0F + 0.5F).to_int()
  let whole = scaled / 100
  let fraction = scaled % 100
  let fraction_text = if fraction < 10 {
    "0" + fraction.to_string()
  } else {
    fraction.to_string()
  }
  "Progress: " + whole.to_string() + "." + fraction_text
}

///|
fn transform_from_position(position : @math.Vec2, z : Float) -> @math.Transform {
  @math.Transform::from_xy_rotation_scale(
    position,
    0.0F,
    @math.Vec2::new(1.0F, 1.0F),
    z~,
  )
}

///|
fn clamp(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn clamp01(value : Float) -> Float {
  clamp(value, 0.0F, 1.0F)
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
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}
