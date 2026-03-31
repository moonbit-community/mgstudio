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
fn build_glyph_text(repeat_count : Int) -> String {
  "0123456789".repeat(repeat_count)
}

///|
struct Args {
  mut no_ui : Bool
  mut no_text2d : Bool
  mut recompute_text : Bool
}

///|
let args_key : @ecs.ResourceKey[Args] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_glyphs.Args",
)

///|
impl @app.Resource for Args with resource() {
  args_key
}

///|
fn parse_args() -> Args {
  let args = Args::{ no_ui: false, no_text2d: false, recompute_text: false }
  for arg in @env.args() {
    match arg {
      "--no-ui" => args.no_ui = true
      "--no-text2d" => args.no_text2d = true
      "--recompute-text" => args.recompute_text = true
      _ => ()
    }
  }
  args
}

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::default()
  window.present_mode = @window.PresentMode::AutoNoVsync
  window.resolution = @window.WindowResolution::new(1920, 1080).with_scale_factor_override(
    1.0F,
  )
  window
}

///|
fn setup(commands : @app.Commands, args : @app.Res[Args]) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  let text_string = build_glyph_text(10_000)
  let text_font = @text.TextFont::from_font_size(4.0F)
  let text_layout = @text.TextLayout::new(
    @text.Justify::Left,
    @text.LineBreak::AnyCharacter,
  )
  if !args.get().no_ui {
    let center_node = commands.spawn_component(
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
    )
    let text_node = commands.spawn(
      (
        @hierarchy.Parent::new(center_node),
        @ui.Node::default().with_width(@ui.Val::Px(1000.0F)),
      ),
    )
    ignore(
      commands.spawn(
        (
          @hierarchy.Parent::new(text_node),
          @text.Text::new(text_string),
          text_font,
          text_layout,
        ),
      ),
    )
  }
  if !args.get().no_text2d {
    ignore(
      commands.spawn(
        (
          @text.Text2d::new(text_string),
          text_font,
          @text.TextColor::new(@sprite.Color::srgb(1.0F, 0.0F, 0.0F)),
          @sprite.Anchor::center(),
          @text.TextBounds::new_horizontal(1000.0F),
          text_layout,
        ),
      ),
    )
  }
}

///|
fn force_recompute(
  args : @app.Res[Args],
  texts : @ecs.Query[@ecs.Mut[@text.TextLayout], @ecs.All],
) -> Unit {
  if !args.get().recompute_text {
    return
  }
  try! texts.for_each(fn(_entity, text_layout) {
    text_layout.set(text_layout.value())
  })
}

///|
fn main {
  let args = parse_args()
  @app.App::new(@ecs.World::new())
  .insert_resource(args)
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugin_group(fn() {
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window()),
      primary_cursor_options: None,
      exit_condition: @window.ExitCondition::OnAllClosed,
      close_when_requested: true,
    })
  })
  .add_plugin(@diagnostic.stress_diagnostics_plugin)
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(force_recompute)))
  .run()
}
