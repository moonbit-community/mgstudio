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
const GRID_COLUMNS : Int = 12

///|
const GRID_ROWS : Int = 8

///|
struct IdleColor {
  color : @sprite.Color
}

///|
let idle_color_key : @ecs.ComponentKey[IdleColor] = @ecs.register_component(
  debug_name="examples.testbed.ui.IdleColor",
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
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  let root = commands.spawn(
    (
      @mgui.UiRoot::default(),
      @mgui.Node::default()
      .with_width(@mgui.Val::Percent(100.0F))
      .with_height(@mgui.Val::Percent(100.0F))
      .with_display(@mgui.Display::Grid)
      .with_grid_template_columns([
        @mgui.RepeatedGridTrack::new(
          @mgui.GridTrackRepetition::Count(GRID_COLUMNS),
          [@mgui.GridTrack::Fr(1.0F)],
        ),
      ])
      .with_grid_template_rows([
        @mgui.RepeatedGridTrack::new(
          @mgui.GridTrackRepetition::Count(GRID_ROWS),
          [@mgui.GridTrack::Fr(1.0F)],
        ),
      ]),
    ),
  )
  let cell_count = GRID_COLUMNS * GRID_ROWS
  let cell_count_f = float_from_int(cell_count)
  for i in 0..<cell_count {
    let h = float_from_int(i * 17 % 360)
    let bg = @sprite.Color::hsl(h, 0.8F, 0.75F)
    ignore(
      commands.spawn(
        (
          @hierarchy.Parent::new(root),
          @mgui.Button::default(),
          IdleColor::{ color: bg },
          @mgui.Node::default()
          .with_width(@mgui.Val::Percent(100.0F))
          .with_height(@mgui.Val::Percent(100.0F))
          .with_border(
            @mgui.UiRect::all(@mgui.Val::VMin(0.1F * 96.0F / cell_count_f)),
          ),
          @mgui.BackgroundColor::new(bg),
          @mgui.BorderColor::new(@sprite.Color::new(1.0F, 1.0F, 1.0F, 0.4F)),
        ),
      ),
    )
  }
}

///|
fn button_system(
  buttons : @ecs.Query[
    (
      @ecs.Comp[@mgui.Interaction],
      @ecs.Mut[@mgui.BackgroundColor],
      @ecs.Comp[IdleColor],
    ),
    @ecs.With[@mgui.Button],
  ],
) -> Unit {
  try! buttons.for_each(fn(_entity, data) {
    let (interaction, color, idle_color) = data
    let next = match interaction.value() {
      @mgui.Interaction::Hovered => @sprite.Color::srgb(1.0F, 0.33F, 0.0F)
      _ => idle_color.value().color
    }
    color.set(@mgui.BackgroundColor::new(next))
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_plugins(@diagnostic.FrameTimeDiagnosticsPlugin::default())
  .add_plugins(@diagnostic.LogDiagnosticsPlugin::default())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param(button_system)))
  .run()
}
