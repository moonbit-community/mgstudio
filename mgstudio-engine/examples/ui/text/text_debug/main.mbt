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
struct SecondsValue {}

///|
struct FpsValue {}

///|
struct FrameTimeValue {}

///|
let seconds_value_key : @ecs.ComponentKey[SecondsValue] = @ecs.register_component(
  debug_name="examples.ui.text.text_debug.seconds_value",
)

///|
let fps_value_key : @ecs.ComponentKey[FpsValue] = @ecs.register_component(
  debug_name="examples.ui.text.text_debug.fps_value",
)

///|
let frame_time_value_key : @ecs.ComponentKey[FrameTimeValue] = @ecs.register_component(
  debug_name="examples.ui.text.text_debug.frame_time_value",
)

///|
pub impl @ecs.Component for SecondsValue with component() {
  seconds_value_key
}

///|
pub impl @ecs.Component for FpsValue with component() {
  fps_value_key
}

///|
pub impl @ecs.Component for FrameTimeValue with component() {
  frame_time_value_key
}

///|
fn maroon() -> @sprite.Color {
  @sprite.Color::srgb(0.5F, 0.0F, 0.0F)
}

///|
fn yellow() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 1.0F, 0.0F)
}

///|
fn pink() -> @sprite.Color {
  @sprite.Color::srgb(0.8F, 0.2F, 0.7F)
}

///|
fn green_yellow() -> @sprite.Color {
  @sprite.Color::srgb(0.68F, 1.0F, 0.18F)
}

///|
fn orange_red() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 0.27F, 0.0F)
}

///|
fn lime() -> @sprite.Color {
  @sprite.Color::srgb(0.0F, 1.0F, 0.0F)
}

///|
fn background(color : @sprite.Color) -> @ui.BackgroundColor {
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
  background_color : @sprite.Color,
  text_color? : @sprite.Color = @sprite.Color::white(),
  layout? : @text.TextLayout = @text.TextLayout::default(),
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
  color : @sprite.Color,
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
fn format_metric(value : Float?) -> String {
  match value {
    Some(number) => number.to_string()
    None => "--"
  }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")

  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default())),
  )

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_justify_content(@ui.JustifyContent::SpaceBetween),
    ),
  )

  let left_column = spawn_node(
    commands,
    root,
    @ui.Node::default()
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
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(25.0F)),
      @ui.Node::default(),
      maroon(),
    ),
  )
  ignore(
    spawn_text_block(
      commands,
      left_column,
      "This text is right-justified. The `Justify` component controls the horizontal alignment of the lines of multi-line text relative to each other, and does not affect the text node's position in the UI layout.",
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(25.0F)),
      { ..@ui.Node::default(), max_width: @ui.Val::Px(300.0F) },
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
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(25.0F)),
      { ..@ui.Node::default(), max_width: @ui.Val::Px(300.0F) },
      maroon(),
    ),
  )

  let right_column = spawn_node(
    commands,
    root,
    @ui.Node::default()
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
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(33.0F)),
      { ..@ui.Node::default(), max_width: @ui.Val::Px(400.0F) },
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
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(29.0F)),
      { ..@ui.Node::default(), max_width: @ui.Val::Px(300.0F) },
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
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(29.0F)),
      { ..@ui.Node::default(), max_width: @ui.Val::Px(300.0F) },
      maroon(),
      text_color=green_yellow(),
      layout=@text.TextLayout::new_with_justify(@text.Justify::Justified),
    ),
  )

  let changing_text = commands.spawn(
    (
      @hierarchy.Parent::new(right_column),
      @text.Text::new("This text changes in the bottom right - "),
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(21.0F)),
      background(maroon()),
    ),
  )
  let seconds_value = spawn_text_span(
    commands,
    changing_text,
    "--",
    @text.TextFont::default()
    .with_font(font)
    .with_font_size(@text.FontSize::Px(21.0F)),
    orange_red(),
  )
  ignore(commands.entity(seconds_value).insert_component(SecondsValue::{  }))
  ignore(
    spawn_text_span(
      commands,
      changing_text,
      " s, ",
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(10.0F)),
      yellow(),
    ),
  )
  let fps_value = spawn_text_span(
    commands,
    changing_text,
    "--",
    @text.TextFont::default()
    .with_font(font)
    .with_font_size(@text.FontSize::Px(21.0F)),
    lime(),
  )
  ignore(commands.entity(fps_value).insert_component(FpsValue::{  }))
  ignore(
    spawn_text_span(
      commands,
      changing_text,
      " fps, ",
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(10.0F)),
      yellow(),
    ),
  )
  let frame_time_value = spawn_text_span(
    commands,
    changing_text,
    "--",
    @text.TextFont::default()
    .with_font(font)
    .with_font_size(@text.FontSize::Px(42.0F)),
    @sprite.Color::srgb(0.2F, 0.5F, 1.0F),
  )
  ignore(
    commands.entity(frame_time_value).insert_component(FrameTimeValue::{  }),
  )
  ignore(
    spawn_text_span(
      commands,
      changing_text,
      " ms/frame",
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(42.0F)),
      @sprite.Color::srgb(0.2F, 0.5F, 1.0F),
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      changing_text,
      " this text has zero font size",
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(0.0F)),
      @sprite.Color::srgb(0.2F, 0.5F, 1.0F),
    ),
  )
}

///|
fn change_text_system(
  diagnostics : @app.Res[@diagnostic.DiagnosticsStore],
  time : @app.Res[@time.Time[@time.Real]],
  seconds_value : @app.Single[@ecs.Mut[@text.TextSpan], @ecs.With[SecondsValue]],
  fps_value : @app.Single[@ecs.Mut[@text.TextSpan], @ecs.With[FpsValue]],
  frame_time_value : @app.Single[
    @ecs.Mut[@text.TextSpan],
    @ecs.With[FrameTimeValue],
  ],
) -> Unit {
  let elapsed_text = format_metric(Some(time.get().elapsed_seconds()))
  seconds_value.get().set(@text.TextSpan::new(elapsed_text))

  let fps = diagnostics
    .get()
    .get(@diagnostic.frame_time_diagnostic_fps)
    .map(fn(diagnostic) { diagnostic.smoothed() })
    .unwrap_or(None)
  fps_value.get().set(@text.TextSpan::new(format_metric(fps)))

  let frame_time = diagnostics
    .get()
    .get(@diagnostic.frame_time_diagnostic_frame_time)
    .map(fn(diagnostic) { diagnostic.smoothed() })
    .unwrap_or(None)
  frame_time_value.get().set(@text.TextSpan::new(format_metric(frame_time)))
}

///|
fn main {
  @diagnostic.frame_time_diagnostics_plugin(
    @app.App::new(@ecs.World::new()).add_plugins(@mgstudio.default_plugins()),
  )
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param5(change_text_system)))
  .run()
}
