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
struct TextChanges {}

///|
let text_changes_key : @ecs.ComponentKey[TextChanges] = @ecs.register_component(
  debug_name="examples.ui.text.text_debug.text_changes",
)

///|
pub impl @ecs.Component for TextChanges with fn component() {
  text_changes_key
}

///|
fn maroon() -> @color.Color {
  @color.Color::srgb(0.5F, 0.0F, 0.0F)
}

///|
fn yellow() -> @color.Color {
  @color.Color::srgb(1.0F, 1.0F, 0.0F)
}

///|
fn pink() -> @color.Color {
  @color.Color::srgb(0.8F, 0.2F, 0.7F)
}

///|
fn green_yellow() -> @color.Color {
  @color.Color::srgb(0.68F, 1.0F, 0.18F)
}

///|
fn orange_red() -> @color.Color {
  @color.Color::srgb(1.0F, 0.27F, 0.0F)
}

///|
fn lime() -> @color.Color {
  @color.Color::srgb(0.0F, 1.0F, 0.0F)
}

///|
fn blue() -> @color.Color {
  @color.Color::srgb(0.0F, 0.0F, 1.0F)
}

///|
fn red() -> @color.Color {
  @color.Color::srgb(1.0F, 0.0F, 0.0F)
}

///|
fn background(color : @color.Color) -> @ui.BackgroundColor {
  @ui.BackgroundColor::new(color)
}

///|
fn spawn_node(
  commands : @app.Commands,
  parent : @core.Entity,
  node : @ui.Node,
) -> @core.Entity {
  commands.spawn((@hierarchy.Parent::new(parent), node))
}

///|
fn spawn_text_block(
  commands : @app.Commands,
  parent : @core.Entity,
  content : String,
  font : @text.TextFont,
  node : @ui.Node,
  background_color : @color.Color,
  text_color? : @color.Color = @color.Color::white(),
  layout? : @text.TextLayout = @text.TextLayout::TextLayout(),
) -> @core.Entity {
  commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @text.Text::new(content),
      font,
      node,
      @text.TextColor::new(text_color),
      layout,
      background(background_color),
    ),
  )
}

///|
fn spawn_text_span(
  commands : @app.Commands,
  parent : @core.Entity,
  content : String,
  font : @text.TextFont,
  color : @color.Color,
) -> @core.Entity {
  commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @text.TextSpan::new(content),
      font,
      @text.TextColor::new(color),
    ),
  )
}

///|
fn format_fixed(value : Float, precision : Int) -> String {
  if precision <= 0 {
    value.round().to_int().to_string()
  } else {
    let mut scale = 1
    for _ in 0..<precision {
      scale = scale * 10
    }
    let scaled = (value * Float::from_int(scale)).round().to_int()
    let sign = if scaled < 0 { "-" } else { "" }
    let magnitude = if scaled < 0 { -scaled } else { scaled }
    let whole = magnitude / scale
    let fraction = magnitude % scale
    let mut fraction_text = fraction.to_string()
    while fraction_text.length() < precision {
      fraction_text = "0\{fraction_text}"
    }
    "\{sign}\{whole.to_string()}.\{fraction_text}"
  }
}

///|
fn push_recent(
  values : Array[Float],
  value : Float,
  limit : Int,
) -> Array[Float] {
  values.push(value)
  while values.length() > limit {
    ignore(values.remove(0))
  }
  values
}

///|
fn mean(data : Array[Float]) -> Float? {
  let count = data.length()
  if count == 0 {
    None
  } else {
    let mut sum = 0.0F
    for value in data {
      sum = sum + value
    }
    Some(sum / Float::from_int(count))
  }
}

///|
fn std_deviation(data : Array[Float]) -> Float? {
  match mean(data) {
    Some(data_mean) if data.length() > 0 => {
      let mut variance_sum = 0.0F
      for value in data {
        let diff = data_mean - value
        variance_sum = variance_sum + diff * diff
      }
      Some(Float::sqrt(variance_sum / Float::from_int(data.length())))
    }
    _ => None
  }
}

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::Window()
  window.present_mode = @window.PresentMode::AutoNoVsync
  window
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")

  ignore(
    commands.spawn(
      (
        @camera_components2d.Camera2d::Camera2d(),
        @camera_camera.Camera::Camera(),
      ),
    ),
  )

  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_justify_content(@ui.JustifyContent::SpaceBetween),
    ),
  )

  let left_column = spawn_node(
    commands,
    root,
    @ui.Node::Node()
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_justify_content(@ui.JustifyContent::SpaceBetween)
    .with_align_items(@ui.AlignItems::Start)
    .with_flex_grow(1.0F)
    .with_margin(
      @ui.UiRect::new(
        @ui.Val::Px(15.0F),
        @ui.Val::Px(15.0F),
        @ui.Val::Px(5.0F),
        @ui.Val::Px(5.0F),
      ),
    ),
  )
  ignore(
    spawn_text_block(
      commands,
      left_column,
      "This is\ntext with\nline breaks\nin the top left.",
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(25.0F)),
      @ui.Node::Node(),
      maroon(),
    ),
  )
  ignore(
    spawn_text_block(
      commands,
      left_column,
      "This text is right-justified. The `Justify` component controls the horizontal alignment of the lines of multi-line text relative to each other, and does not affect the text node's position in the UI layout.",
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(25.0F)),
      { ..@ui.Node(), max_width: @ui.Val::Px(300.0F) },
      maroon(),
      text_color=yellow(),
      layout=@text.TextLayout::new_with_justify(@text.Justify::Right),
    ),
  )
  ignore(
    spawn_text_block(
      commands,
      left_column,
      "This\ntext has\nline breaks and also a set width in the bottom left.",
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(25.0F)),
      { ..@ui.Node(), max_width: @ui.Val::Px(300.0F) },
      maroon(),
    ),
  )

  let right_column = spawn_node(
    commands,
    root,
    @ui.Node::Node()
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_justify_content(@ui.JustifyContent::SpaceBetween)
    .with_align_items(@ui.AlignItems::End)
    .with_flex_grow(1.0F)
    .with_margin(
      @ui.UiRect::new(
        @ui.Val::Px(15.0F),
        @ui.Val::Px(15.0F),
        @ui.Val::Px(5.0F),
        @ui.Val::Px(5.0F),
      ),
    ),
  )
  ignore(
    spawn_text_block(
      commands,
      right_column,
      "This text is very long, has a limited width, is center-justified, is positioned in the top right and is also colored pink.",
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(33.0F)),
      { ..@ui.Node(), max_width: @ui.Val::Px(400.0F) },
      maroon(),
      text_color=pink(),
      layout=@text.TextLayout::new_with_justify(@text.Justify::Center),
    ),
  )
  ignore(
    spawn_text_block(
      commands,
      right_column,
      "This text is left-justified and is vertically positioned to distribute the empty space equally above and below it.",
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(29.0F)),
      { ..@ui.Node(), max_width: @ui.Val::Px(300.0F) },
      maroon(),
      text_color=yellow(),
      layout=@text.TextLayout::new_with_justify(@text.Justify::Left),
    ),
  )
  ignore(
    spawn_text_block(
      commands,
      right_column,
      "This text is fully justified and is positioned in the same way.",
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(29.0F)),
      { ..@ui.Node(), max_width: @ui.Val::Px(300.0F) },
      maroon(),
      text_color=green_yellow(),
      layout=@text.TextLayout::new_with_justify(@text.Justify::Justified),
    ),
  )

  let changing_text = commands.spawn(
    (
      @hierarchy.Parent::new(right_column),
      @text.Text::new(""),
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(21.0F)),
      @text.TextColor::new(@color.Color::white()),
      @ui.Node::Node(),
      TextChanges::{  },
      background(maroon()),
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      changing_text,
      "\nThis text changes in the bottom right",
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(21.0F)),
      @color.Color::white(),
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      changing_text,
      " this text has zero font size",
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(0.0F)),
      blue(),
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      changing_text,
      "\nThis text changes in the bottom right - ",
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(21.0F)),
      red(),
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      changing_text,
      "",
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(21.0F)),
      orange_red(),
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      changing_text,
      " fps, ",
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(10.0F)),
      yellow(),
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      changing_text,
      "",
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(21.0F)),
      lime(),
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      changing_text,
      " ms/frame",
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(42.0F)),
      blue(),
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      changing_text,
      " this text has negative font size",
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(-42.0F)),
      blue(),
    ),
  )
}

///|
fn change_text_system(
  fps_history : @app.Local[Array[Float]],
  time_history : @app.Local[Array[Float]],
  time : @app.Res[@time.Time[@time.Real]],
  diagnostics : @app.Res[@diagnostic.DiagnosticsStore],
  query : @ecs.Query[@core.Entity, @ecs.With[TextChanges]],
  writer : @ui.TextUiWriter,
) -> Unit {
  let time_value = time.get()
  let mut times = time_history.get()
  times = push_recent(times, time_value.elapsed_seconds(), 120)
  time_history.set(times)

  let time_count = times.length()
  let time_span = if time_count >= 2 {
    times[time_count - 1] - times[0]
  } else {
    0.0001F
  }
  let fps_denominator = if time_span > 0.0001F { time_span } else { 0.0001F }
  let avg_fps = Float::from_int(time_count) / fps_denominator
  let mut fps_values = fps_history.get()
  fps_values = push_recent(fps_values, avg_fps, 120)
  let fps_variance = std_deviation(fps_values).unwrap_or(0.0F)
  fps_history.set(fps_values)

  let fps = diagnostics
    .get()
    .get(@diagnostic.frame_time_diagnostic_fps)
    .map(fn(diagnostic) { diagnostic.smoothed() })
    .unwrap_or(None)
    .unwrap_or(0.0F)

  let frame_time = diagnostics
    .get()
    .get(@diagnostic.frame_time_diagnostic_frame_time)
    .map(fn(diagnostic) { diagnostic.smoothed() })
    .unwrap_or(None)
    .unwrap_or(time_value.delta_seconds())

  try! query.view(fn(entity, _value) {
    ignore(
      writer.set_text(
        entity,
        0,
        "\{format_fixed(avg_fps, 1)} avg fps, \{format_fixed(fps_variance, 1)} frametime variance",
      ),
    )
    ignore(
      writer.set_text(
        entity,
        1,
        "\nThis text changes in the bottom right - \{format_fixed(fps, 1)} fps, \{format_fixed(frame_time, 3)} ms/frame",
      ),
    )
    ignore(writer.set_text(entity, 4, format_fixed(fps, 1)))
    ignore(writer.set_text(entity, 6, format_fixed(frame_time, 3)))
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window()),
      primary_cursor_options: None,
      exit_condition: @window.ExitCondition::OnAllClosed,
      close_when_requested: true,
    }),
  )
  .add_plugins(
    @diagnostic.FrameTimeDiagnosticsPlugin::FrameTimeDiagnosticsPlugin(),
  )
  .add_systems_param2(@app.Startup, setup)
  .add_systems_param6(@app.Update, change_text_system)
  .run()
}
