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
const HALF_X : Int = 5

///|
const HALF_Y : Int = 5

///|
const TILE_SIZE_X : Float = 48.0F

///|
const TILE_SIZE_Y : Float = 28.0F

///|
struct TextStats {
  mut print_timer : Float
}

///|
let text_stats_key : @ecs.ResourceKey[TextStats] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_text2d.TextStats",
)

///|
impl @app.Resource for TextStats with resource() {
  text_stats_key
}

///|
fn TextStats::default() -> TextStats {
  { print_timer: 0.0F }
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn sample_text(idx : Int) -> String {
  match idx % 7 {
    0 => "Bevy"
    1 => "Moon"
    2 => "Glyph"
    3 => "Text"
    4 => "ABCD"
    5 => "ABC"
    _ => "1234"
  }
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  for y in -HALF_Y..<HALF_Y {
    for x in -HALF_X..<HALF_X {
      let idx = (y + HALF_Y) * (HALF_X * 2) + (x + HALF_X)
      let px = float_from_int(x) * TILE_SIZE_X + 460.0F
      let py = float_from_int(y) * TILE_SIZE_Y + 320.0F
      ignore(
        commands.spawn(
          (
            @text.Text::new(sample_text(idx)),
            @text.TextFont::from_font_size(22.0F),
            @text.TextColor::new(
              @sprite.Color::hsl(float_from_int(idx % 360), 0.8F, 0.75F),
            ),
            @ui.Node::default()
            .with_position_type(@ui.PositionType::Absolute)
            .with_left(@ui.Val::Px(px))
            .with_top(@ui.Val::Px(py)),
          ),
        ),
      )
    }
  }
}

///|
fn print_counts(
  time : @app.Res[@time.Time[Unit]],
  stats : @app.ResMut[TextStats],
  texts : @ecs.Query[@ecs.Comp[@text.Text], @ecs.All],
  atlas_set : @app.Res[@text.FontAtlasSet],
) -> Unit {
  let stats_ref = stats.get_ref()
  stats_ref.val.print_timer += time.get().delta_secs()
  if stats_ref.val.print_timer < 1.0F {
    return
  }
  stats_ref.val.print_timer -= 1.0F
  let atlas_count = atlas_set.get().entries.length()
  println("Texts: \{texts.count()} FontAtlasSets: \{atlas_count}")
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(TextStats::default())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(
    [
      ..@mgstudio.default_plugins(),
      @diagnostic.frame_time_diagnostics_plugin,
      @diagnostic.log_diagnostics_plugin,
    ],
  )
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param4(print_counts)))
  .run()
}
