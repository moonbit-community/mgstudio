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
fn repeated_word(word : String, count : Int) -> String {
  let mut out = ""
  for _ in 0..<count {
    out = out + word
  }
  out
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  let root = commands.spawn(
    (
      PipelineText::{  },
      @text.Text2d::default(),
      @text.TextLayout::new(
        @text.Justify::Center,
        @text.LineBreak::AnyCharacter,
      ),
      @text.TextBounds::default(),
    ),
  )

  let mono_font = asset_server.get().load_font("fonts/FiraMono-Medium.ttf")
  let sans_font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  for i in 1..<50 {
    ignore(
      commands.spawn(
        (
          @hierarchy.Parent::new(root),
          @text.TextSpan::new(repeated_word("text", i)),
          @text.TextFont::default()
          .with_font(mono_font)
          .with_font_size(Float::from_double((4 + i % 10).to_double())),
          @text.TextColor::new(@sprite.Color::srgb(0.0F, 0.0F, 1.0F)),
        ),
      ),
    )
    ignore(
      commands.spawn(
        (
          @hierarchy.Parent::new(root),
          @text.TextSpan::new(repeated_word("pipeline", i)),
          @text.TextFont::default()
          .with_font(sans_font)
          .with_font_size(Float::from_double((4 + i % 11).to_double())),
          @text.TextColor::new(@sprite.Color::srgb(1.0F, 1.0F, 0.0F)),
        ),
      ),
    )
  }
}

///|
fn update_text_pipeline(
  time : @app.Res[@time.Time[Unit]],
  texts : @ecs.Query[@ecs.Mut[@text.TextBounds], @ecs.With[PipelineText]],
) -> Unit {
  let elapsed = time.get().elapsed_secs()
  let width = (1.0F + @math.sin(elapsed)) * 600.0F
  try! texts.for_each(fn(_entity, bounds) {
    bounds.set(@text.TextBounds::new_horizontal(width))
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(
    [..@mgstudio.default_plugins(), @diagnostic.stress_diagnostics_plugin],
  )
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(update_text_pipeline)),
  )
  .run()
}
