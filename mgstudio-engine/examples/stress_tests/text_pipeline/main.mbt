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
struct PipelineText {}

///|
let pipeline_text_key : @ecs.ComponentKey[PipelineText] = @ecs.register_component(
  debug_name="examples.stress_tests.text_pipeline.PipelineText",
)

///|
pub impl @ecs.Component for PipelineText with component() {
  pipeline_text_key
}

///|
fn make_text(repeat_count : Int) -> String {
  let mut out = ""
  for i in 0..<repeat_count {
    out = "\{out}text\{i} pipeline\{repeat_count - i} "
  }
  out
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  ignore(
    commands.spawn(
      (
        PipelineText::{  },
        @text.Text::new(make_text(80)),
        @text.TextFont::from_font_size(18.0F),
        @text.TextColor::new(@sprite.Color::srgb(0.2F, 0.55F, 1.0F)),
        @text.TextLayout::new(
          @text.Justify::Center,
          @text.LineBreak::AnyCharacter,
        ),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(160.0F))
        .with_top(@ui.Val::Px(140.0F))
        .with_width(@ui.Val::Px(920.0F)),
      ),
    ),
  )
}

///|
fn update_text_pipeline(
  time : @app.Res[@time.Time[Unit]],
  texts : @ecs.Query[
    (@ecs.Mut[@text.Text], @ecs.Mut[@ui.Node]),
    @ecs.With[PipelineText],
  ],
) -> Unit {
  let elapsed = time.get().elapsed_secs()
  let width = 300.0F + (@math.sin(elapsed) + 1.0F) * 420.0F
  let cycle = 30 +
    ((@math.sin(elapsed * 0.7F) + 1.0F).to_double() * 35.0).to_int()
  try! texts.for_each(fn(_entity, data) {
    let (text, node) = data
    text.set(@text.Text::new(make_text(cycle)))
    node.set(
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(160.0F))
      .with_top(@ui.Val::Px(140.0F))
      .with_width(@ui.Val::Px(width)),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(
    [
      ..@mgstudio.default_plugins(),
      @diagnostic.frame_time_diagnostics_plugin,
      @diagnostic.log_diagnostics_plugin,
    ],
  )
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(update_text_pipeline)),
  )
  .run()
}
