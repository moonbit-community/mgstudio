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
const GRID_COLUMNS : Int = 8

///|
const GRID_ROWS : Int = 6

///|
struct IdleColor {
  color : @sprite.Color
}

///|
let idle_color_key : @ecs.ComponentKey[IdleColor] = @ecs.register_component(
  debug_name="examples.testbed.full_ui.IdleColor",
)

///|
pub impl @ecs.Component for IdleColor with component() {
  idle_color_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_display(@ui.Display::Flex)
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_padding(@ui.UiRect::all(@ui.Val::Px(16.0F)))
      .with_row_gap(@ui.Val::Px(12.0F))
      .with_align_items(@ui.AlignItems::Stretch),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.1F, 0.12F, 0.16F)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @text.Text::new("Full UI Testbed"),
        @text.TextFont::default().with_font(font).with_font_size(32.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @ui.Node::default().with_height(@ui.Val::Px(44.0F)),
      ),
    ),
  )

  let grid = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_display(@ui.Display::Grid)
      .with_height(@ui.Val::Percent(100.0F))
      .with_grid_template_columns([
        @ui.RepeatedGridTrack::new(
          @ui.GridTrackRepetition::Count(GRID_COLUMNS),
          [@ui.GridTrack::Fr(1.0F)],
        ),
      ])
      .with_grid_template_rows([
        @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(GRID_ROWS), [
          @ui.GridTrack::Fr(1.0F),
        ]),
      ])
      .with_column_gap(@ui.Val::Px(6.0F))
      .with_row_gap(@ui.Val::Px(6.0F)),
    ),
  )

  let cell_count = GRID_COLUMNS * GRID_ROWS
  for i in 0..<cell_count {
    let h = float_from_int(i * 29 % 360)
    let idle = @sprite.Color::hsl(h, 0.72F, 0.62F)
    ignore(
      commands.spawn(
        (
          @hierarchy.Parent::new(grid),
          @ui.Button::default(),
          IdleColor::{ color: idle },
          @ui.Node::default()
          .with_width(@ui.Val::Percent(100.0F))
          .with_height(@ui.Val::Percent(100.0F))
          .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F))),
          @ui.BackgroundColor::new(idle),
          @ui.BorderColor::new(@sprite.Color::new(1.0F, 1.0F, 1.0F, 0.2F)),
        ),
      ),
    )
  }
}

///|
fn button_system(
  buttons : @ecs.Query[
    (
      @ecs.Comp[@ui.Interaction],
      @ecs.Mut[@ui.BackgroundColor],
      @ecs.Comp[IdleColor],
    ),
    @ecs.With[@ui.Button],
  ],
) -> Unit {
  try! buttons.for_each(fn(_entity, data) {
    let (interaction, color, idle) = data
    let next = match interaction.value() {
      @ui.Interaction::Hovered => @sprite.Color::srgb(1.0F, 0.38F, 0.0F)
      @ui.Interaction::Pressed => @sprite.Color::srgb(1.0F, 0.16F, 0.0F)
      _ => idle.value().color
    }
    color.set(@ui.BackgroundColor::new(next))
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
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param(button_system)))
  .run()
}
