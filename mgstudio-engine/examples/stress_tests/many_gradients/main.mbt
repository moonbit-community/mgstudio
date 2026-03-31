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
const COLS : Int = 30

///|
const CELL_COUNT : Int = 900

///|
struct GradientCell {
  index : Int
}

///|
let gradient_cell_key : @ecs.ComponentKey[GradientCell] = @ecs.register_component(
  debug_name="examples.stress_tests.many_gradients.GradientCell",
)

///|
pub impl @ecs.Component for GradientCell with component() {
  gradient_cell_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn div_ceil(a : Int, b : Int) -> Int {
  if a % b == 0 {
    a / b
  } else {
    a / b + 1
  }
}

///|
fn setup(commands : @app.Commands) -> Unit {
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore

  let rows = div_ceil(CELL_COUNT, COLS)
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_display(@ui.Display::Grid)
      .with_grid_template_columns([
        @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(COLS), [
          @ui.GridTrack::Fr(1.0F),
        ]),
      ])
      .with_grid_template_rows([
        @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(rows), [
          @ui.GridTrack::Fr(1.0F),
        ]),
      ]),
    ),
  )

  for i in 0..<CELL_COUNT {
    let hue = float_from_int(i * 10 % 360)
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        GradientCell::{ index: i },
        @ui.Node::default()
        .with_width(@ui.Val::Percent(100.0F))
        .with_height(@ui.Val::Percent(100.0F)),
        @ui.BackgroundColor::new(@sprite.Color::hsl(hue, 1.0F, 0.5F)),
      ),
    )
    |> ignore
  }
}

///|
fn animate_cells(
  time : @app.Res[@time.Time[Unit]],
  cells : @ecs.Query[
    (@ecs.Comp[GradientCell], @ecs.Mut[@ui.BackgroundColor]),
    @ecs.All,
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! cells.for_each(fn(_entity, data) {
    let (cell, background) = data
    let idxf = float_from_int(cell.value().index)
    let h = (@math.sin(t + idxf * 0.01F) * 0.5F + 0.5F) * 360.0F
    let color = @sprite.Color::hsl(h, 1.0F, 0.5F)
    background.get_ref().val = @ui.BackgroundColor::new(color)
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
  .add_systems(@app.Update, @app.system(@app.system_param2(animate_cells)))
  .run()
}
