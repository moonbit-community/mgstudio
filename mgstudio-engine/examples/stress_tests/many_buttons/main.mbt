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
const BUTTONS_PER_AXIS : Int = 20

///|
struct IdleColor {
  color : @sprite.Color
}

///|
let idle_color_key : @ecs.ComponentKey[IdleColor] = @ecs.register_component(
  debug_name="examples.stress_tests.many_buttons.IdleColor",
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
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_display(@ui.Display::Grid)
      .with_grid_template_columns([
        @ui.RepeatedGridTrack::new(
          @ui.GridTrackRepetition::Count(BUTTONS_PER_AXIS),
          [@ui.GridTrack::Fr(1.0F)],
        ),
      ])
      .with_grid_template_rows([
        @ui.RepeatedGridTrack::new(
          @ui.GridTrackRepetition::Count(BUTTONS_PER_AXIS),
          [@ui.GridTrack::Fr(1.0F)],
        ),
      ]),
    ),
  )

  let buttons_f = float_from_int(BUTTONS_PER_AXIS)
  for row in 0..<BUTTONS_PER_AXIS {
    for column in 0..<BUTTONS_PER_AXIS {
      let h = float_from_int((row * BUTTONS_PER_AXIS + column) % 360)
      let bg = @sprite.Color::hsl(h, 0.9F, 0.8F)
      ignore(
        commands.spawn(
          (
            @hierarchy.Parent::new(root),
            @ui.Button::default(),
            IdleColor::{ color: bg },
            @ui.Node::default()
            .with_width(@ui.Val::Percent(100.0F))
            .with_height(@ui.Val::Percent(100.0F))
            .with_border(
              @ui.UiRect::all(@ui.Val::VMin(0.05F * 90.0F / buttons_f)),
            ),
            @ui.BackgroundColor::new(bg),
            @ui.BorderColor::new(@sprite.Color::new(1.0F, 1.0F, 1.0F, 0.5F)),
          ),
        ),
      )
    }
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
    let (interaction, color, idle_color) = data
    let next = match interaction.value() {
      @ui.Interaction::Hovered => @sprite.Color::srgb(1.0F, 0.27F, 0.0F)
      _ => idle_color.value().color
    }
    color.set(@ui.BackgroundColor::new(next))
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(
    [..@mgstudio.default_plugins(), @diagnostic.stress_diagnostics_plugin],
  )
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param(button_system)))
  .run()
}
