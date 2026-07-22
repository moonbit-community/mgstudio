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
fn centered_horizontal_margin() -> @ui.UiRect {
  @ui.UiRect::new(Auto, Px(0.0F), Auto, Px(0.0F))
}

///|
fn centered_vertical_margin() -> @ui.UiRect {
  @ui.UiRect::new(Px(0.0F), Auto, Px(0.0F), Auto)
}

///|
fn margin() -> @ui.Val {
  Px(12.0F)
}

///|
fn cell_node() -> @ui.Node {
  Node()
}

///|
fn anchored_label_node(node : @ui.Node) -> @ui.Node {
  {
    ..node,
    display: Block,
    position_type: Absolute,
    padding: @ui.UiRect::new(Px(5.0F), Px(1.0F), Px(5.0F), Px(1.0F)),
  }
}

///|
fn spawn_text(
  commands : @app.Commands,
  parent : @core.Entity,
  text : String,
  font : @asset.Handle[@asset.Font],
  color : @color.Color,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(parent),
        @text.Text::new(text),
        @text.TextFont::TextFont().with_font(font),
        @text.TextColor::new(color),
      ),
    ),
  )
}

///|
fn spawn_anchored_cell(
  commands : @app.Commands,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  node : @ui.Node,
  label : String,
) -> Unit {
  let cell = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      cell_node(),
      @ui.BackgroundColor::new(@color.Color::srgb(0.25F, 0.25F, 0.25F)),
    ),
  )
  let label_box = commands.spawn(
    (
      @hierarchy.Parent::new(cell),
      anchored_label_node(node),
      @ui.BackgroundColor::new(@color.Color::srgb(1.0F, 0.066F, 0.349F)),
    ),
  )
  spawn_text(commands, label_box, label, font, @color.Color::black())
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @camera_components2d.Camera2d::Camera2d(),
        @camera_camera.Camera::Camera(),
      ),
    ),
  )
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node()
      .with_width(Percent(100.0F))
      .with_height(Percent(100.0F))
      .with_padding(@ui.UiRect::all(margin()))
      .with_row_gap(margin())
      .with_column_gap(margin())
      .with_display(Grid)
      .with_grid_template_columns([
        @ui.RepeatedGridTrack::new(Count(3), [Fr(1.0F)]),
      ])
      .with_grid_template_rows([
        @ui.RepeatedGridTrack::new(Count(3), [Fr(1.0F)]),
      ]),
      @ui.BackgroundColor::new(@color.Color::black()),
    ),
  )
  spawn_anchored_cell(
    commands,
    root,
    font,
    { ..cell_node(), left: Px(10.0F), top: Px(10.0F) },
    "left: 10px\ntop: 10px",
  )
  spawn_anchored_cell(
    commands,
    root,
    font,
    { ..cell_node(), margin: centered_horizontal_margin(), top: Px(10.0F) },
    "center: 10px\ntop: 10px",
  )
  spawn_anchored_cell(
    commands,
    root,
    font,
    { ..cell_node(), right: Px(10.0F), top: Px(10.0F) },
    "right: 10px\ntop: 10px",
  )
  spawn_anchored_cell(
    commands,
    root,
    font,
    { ..cell_node(), left: Px(10.0F), margin: centered_vertical_margin() },
    "left: 10px\ncenter: 10px",
  )
  spawn_anchored_cell(
    commands,
    root,
    font,
    { ..cell_node(), margin: @ui.UiRect::all(Auto) },
    "center: 10px\ncenter: 10px",
  )
  spawn_anchored_cell(
    commands,
    root,
    font,
    { ..cell_node(), right: Px(10.0F), margin: centered_vertical_margin() },
    "right: 10px\ncenter: 10px",
  )
  spawn_anchored_cell(
    commands,
    root,
    font,
    { ..cell_node(), left: Px(10.0F), bottom: Px(10.0F) },
    "left: 10px\nbottom: 10px",
  )
  spawn_anchored_cell(
    commands,
    root,
    font,
    { ..cell_node(), margin: centered_horizontal_margin(), bottom: Px(10.0F) },
    "center: 10px\nbottom: 10px",
  )
  spawn_anchored_cell(
    commands,
    root,
    font,
    { ..cell_node(), right: Px(10.0F), bottom: Px(10.0F) },
    "right: 10px\nbottom: 10px",
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param2(Startup, setup)
  .run()
}
