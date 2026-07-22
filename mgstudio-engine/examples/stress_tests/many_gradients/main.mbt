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
pub impl @ecs.Component for GradientCell with fn component() {
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
  commands.spawn(
    (@camera_components2d.Camera2d::Camera2d(), @camera_camera.Camera::Camera()),
  )
  |> ignore

  let rows = div_ceil(CELL_COUNT, COLS)
  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node()
      .with_width(Percent(100.0F))
      .with_height(Percent(100.0F))
      .with_display(Grid)
      .with_grid_template_columns([
        @ui.RepeatedGridTrack::new(Count(COLS), [Fr(1.0F)]),
      ])
      .with_grid_template_rows([
        @ui.RepeatedGridTrack::new(Count(rows), [Fr(1.0F)]),
      ]),
    ),
  )

  for i in 0..<CELL_COUNT {
    let hue = float_from_int(i * 10 % 360)
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        GradientCell::{ index: i },
        @ui.Node::Node()
        .with_width(Percent(100.0F))
        .with_height(Percent(100.0F)),
        @ui.BackgroundColor::new(@color.Color::hsl(hue, 1.0F, 0.5F)),
      ),
    )
    |> ignore
  }
}

///|
fn animate_cells(
  time : @app.Res[@time.Time[Unit]],
  cells : @ecs.Query[
    (@ecs.Read[GradientCell], @ecs.Write[@ui.BackgroundColor]),
    @ecs.All,
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! cells.for_each(fn(_entity, data) {
    let (cell, background) = data
    let idxf = float_from_int(cell.value().index)
    let h = (@math.sin(t + idxf * 0.01F) * 0.5F + 0.5F) * 360.0F
    let color = @color.Color::hsl(h, 1.0F, 0.5F)
    background.set(@ui.BackgroundColor::new(color))
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(@diagnostic.StressDiagnosticsPlugin::StressDiagnosticsPlugin())
  .add_systems_param(Startup, setup)
  .add_systems_param2(Update, animate_cells)
  .run()
}
