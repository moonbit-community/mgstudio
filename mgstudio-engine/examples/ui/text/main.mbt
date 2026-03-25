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
//
// Port of `bevy/examples/ui/text/text.rs`.

///|
struct FpsText {}

///|
struct AnimatedText {}

///|
let fps_text_key : @ecs.ComponentKey[FpsText] = @ecs.register_component(
  debug_name="examples.ui.text.fps_text",
)

///|
let animated_text_key : @ecs.ComponentKey[AnimatedText] = @ecs.register_component(
  debug_name="examples.ui.text.animated_text",
)

///|
pub impl @ecs.Component for FpsText with component() {
  fps_text_key
}

///|
pub impl @ecs.Component for AnimatedText with component() {
  animated_text_key
}

///|
fn gold() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 0.84F, 0.0F)
}

///|
fn format_fps(value : Float) -> String {
  value.to_string()
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_plugin(@diagnostic.frame_time_diagnostics_plugin)
  .add_startup_system(setup)
  .add_system_param2(text_update_system)
  .add_system_param2(text_color_system)
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.advance_sequence()
  ignore(tick)
  let asset_server = @asset.AssetServer::new()
  let bold_font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let mono_font = asset_server.load_font("fonts/FiraMono-Medium.ttf")
  let opentype_font = asset_server.load_font("fonts/EBGaramond12-Regular.otf")

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
  )

  let animated = world.spawn_empty()
  try! world.set_by_key(
    animated,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    animated,
    @mgtext.ecs_key_text,
    @mgtext.Text::new("hello\nbevy!"),
  )
  try! world.set_by_key(
    animated,
    @mgtext.ecs_key_text_font,
    @mgtext.TextFont::default()
    .with_font(bold_font)
    .with_font_size(@mgtext.FontSize::Vh(20.0F)),
  )
  try! world.set_by_key(
    animated,
    @mgtext.ecs_key_text_underline,
    @mgtext.Underline::default(),
  )
  try! world.set_by_key(
    animated,
    @mgtext.ecs_key_text_shadow,
    @mgtext.TextShadow::default(),
  )
  try! world.set_by_key(
    animated,
    @mgtext.ecs_key_text_layout,
    @mgtext.TextLayout::new_with_justify(@mgtext.Justify::Center),
  )
  try! world.set_by_key(
    animated,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_bottom(@ui.Val::Px(5.0F))
    .with_right(@ui.Val::Px(5.0F)),
  )
  try! world.set_by_key(animated, animated_text_key, AnimatedText::{  })

  let fps_root = world.spawn_empty()
  try! world.set_by_key(
    fps_root,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    fps_root,
    @mgtext.ecs_key_text,
    @mgtext.Text::new("FPS: "),
  )
  try! world.set_by_key(
    fps_root,
    @mgtext.ecs_key_text_font,
    @mgtext.TextFont::default()
    .with_font(bold_font)
    .with_font_size(@mgtext.FontSize::Px(42.0F)),
  )
  try! world.set_by_key(
    fps_root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(5.0F))
    .with_left(@ui.Val::Px(15.0F)),
  )

  let fps_span = world.spawn_empty()
  try! world.set_by_key(
    fps_span,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(fps_root),
  )
  try! world.set_by_key(
    fps_span,
    @mgtext.ecs_key_text_span,
    @mgtext.TextSpan::default(),
  )
  try! world.set_by_key(
    fps_span,
    @mgtext.ecs_key_text_font,
    @mgtext.TextFont::default()
    .with_font(mono_font)
    .with_font_size(@mgtext.FontSize::Px(33.0F)),
  )
  try! world.set_by_key(
    fps_span,
    @mgtext.ecs_key_text_color,
    @mgtext.TextColor::new(gold()),
  )
  try! world.set_by_key(fps_span, fps_text_key, FpsText::{  })

  let opentype = world.spawn_empty()
  try! world.set_by_key(
    opentype,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    opentype,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(5.0F))
    .with_right(@ui.Val::Px(5.0F))
    .with_margin(@ui.UiRect::all(@ui.Val::Px(12.0F))),
  )
  try! world.set_by_key(
    opentype,
    @mgtext.ecs_key_text,
    @mgtext.Text::new("Opentype features:\n"),
  )
  try! world.set_by_key(
    opentype,
    @mgtext.ecs_key_text_font,
    @mgtext.TextFont::default()
    .with_font(opentype_font)
    .with_font_size(@mgtext.FontSize::Px(32.0F)),
  )

  let text_rows : Array[(String, @mgtext.FontFeatureTag, String)] = [
    ("Smallcaps: ", @mgtext.FontFeatureTag::SMALL_CAPS, "Hello World"),
    (
      "Ligatures: ",
      @mgtext.FontFeatureTag::STANDARD_LIGATURES,
      "fi fl ff ffi ffl",
    ),
    ("Fractions: ", @mgtext.FontFeatureTag::FRACTIONS, "12/134"),
    ("Superscript: ", @mgtext.FontFeatureTag::SUPERSCRIPT, "Up here!"),
    ("Subscript: ", @mgtext.FontFeatureTag::SUBSCRIPT, "Down here!"),
    (
      "Oldstyle figures: ",
      @mgtext.FontFeatureTag::OLDSTYLE_FIGURES,
      "1234567890",
    ),
    ("Lining figures: ", @mgtext.FontFeatureTag::LINING_FIGURES, "1234567890"),
  ]
  for row in text_rows {
    let title_span = world.spawn_empty()
    try! world.set_by_key(
      title_span,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(opentype),
    )
    try! world.set_by_key(
      title_span,
      @mgtext.ecs_key_text_span,
      @mgtext.TextSpan::new(row.0),
    )
    try! world.set_by_key(
      title_span,
      @mgtext.ecs_key_text_font,
      @mgtext.TextFont::default()
      .with_font(opentype_font)
      .with_font_size(@mgtext.FontSize::Px(24.0F)),
    )

    let feature_span = world.spawn_empty()
    try! world.set_by_key(
      feature_span,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(opentype),
    )
    try! world.set_by_key(
      feature_span,
      @mgtext.ecs_key_text_span,
      @mgtext.TextSpan::new(row.2 + "\n"),
    )
    try! world.set_by_key(
      feature_span,
      @mgtext.ecs_key_text_font,
      @mgtext.TextFont::default()
      .with_font(opentype_font)
      .with_font_size(@mgtext.FontSize::Px(24.0F))
      .with_font_features(@mgtext.FontFeatures::builder().enable(row.1).build()),
    )
  }

  let default_font_text = world.spawn_empty()
  try! world.set_by_key(
    default_font_text,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    default_font_text,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_bottom(@ui.Val::Px(5.0F))
    .with_left(@ui.Val::Px(15.0F)),
  )
  try! world.set_by_key(
    default_font_text,
    @mgtext.ecs_key_text,
    @mgtext.Text::new("From a String into Text with the default font!"),
  )
}

///|
fn text_color_system(
  time : @app.Res[@time.Time[@time.Real]],
  query : @ecs.Query[@ecs.Mut[@mgtext.TextColor], @ecs.With[AnimatedText]],
) -> Unit {
  let seconds = time.get().elapsed_secs()
  try! query.view(fn(_entity, text_color) {
    text_color.get_ref().val = @mgtext.TextColor::new(
      @sprite.Color::srgb(
        @math.sin(1.25F * seconds) / 2.0F + 0.5F,
        @math.sin(0.75F * seconds) / 2.0F + 0.5F,
        @math.sin(0.50F * seconds) / 2.0F + 0.5F,
      ),
    )
  })
}

///|
fn text_update_system(
  diagnostics : @app.Res[@diagnostic.DiagnosticsStore],
  query : @ecs.Query[@ecs.Mut[@mgtext.TextSpan], @ecs.With[FpsText]],
) -> Unit {
  let value = match
    diagnostics.get().get(@diagnostic.frame_time_diagnostic_fps) {
    Some(diagnostic) => diagnostic.smoothed()
    None => None
  }
  guard value is Some(fps) else { return }
  try! query.view(fn(_entity, span) {
    span.get_ref().val.content = format_fps(fps)
  })
}
