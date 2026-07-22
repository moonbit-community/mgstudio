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
fn spawn_node(
  world : @ecs.World,
  parent : @core.Entity,
  node : @ui.Node,
) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(entity, @ui.ecs_key_node, node)
  entity
}

///|
fn spawn_text_line(
  world : @ecs.World,
  parent : @core.Entity,
  content : String,
  font : @text.TextFont,
  underline? : Bool = false,
) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(entity, @text.ecs_key_text, @text.Text::new(content))
  try! world.set_by_key(entity, @text.ecs_key_text_font, font)
  if underline {
    try! world.set_by_key(entity, @text.ecs_key_text_underline, Underline())
  }
  entity
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_world(Startup, setup)
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.increment_change_tick()
  ignore(tick)
  let asset_server = @asset.AssetServer::new()
  let family = asset_server.load_font("fonts/MonaSans-VariableFont.ttf")

  try! (world.spawn_bundle(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera(),
      @transform.Transform::identity(),
    ),
  )
  |> ignore)

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, UiRoot())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::Node()
    .with_width(Percent(100.0F))
    .with_height(Percent(100.0F))
    .with_justify_content(Center)
    .with_align_items(Center),
  )

  let panel = spawn_node(
    world,
    root,
    @ui.Node::Node()
    .with_flex_direction(Column)
    .with_align_items(Center)
    .with_padding(@ui.UiRect::all(Px(16.0F)))
    .with_row_gap(Px(16.0F)),
  )
  ignore(
    spawn_text_line(
      world,
      panel,
      "Font Weights, Widths & Styles",
      @text.TextFont::TextFont()
      .with_font(family)
      .with_font_size(@text.FontSize::Px(32.0F)),
      underline=true,
    ),
  )

  let columns = spawn_node(
    world,
    panel,
    @ui.Node::Node().with_flex_direction(Row).with_column_gap(Px(32.0F)),
  )

  let weights_column = spawn_node(
    world,
    columns,
    @ui.Node::Node()
    .with_flex_direction(Column)
    .with_padding(@ui.UiRect::all(Px(8.0F)))
    .with_row_gap(Px(8.0F)),
  )
  let weights : Array[(String, @text.FontWeight)] = [
    ("Weight 100 (Thin)", THIN),
    ("Weight 200 (Extra Light)", EXTRA_LIGHT),
    ("Weight 300 (Light)", LIGHT),
    ("Weight 400 (Normal)", NORMAL),
    ("Weight 500 (Medium)", MEDIUM),
    ("Weight 600 (Semibold)", SEMIBOLD),
    ("Weight 700 (Bold)", BOLD),
    ("Weight 800 (Extra Bold)", EXTRA_BOLD),
    ("Weight 900 (Black)", BLACK),
  ]
  for row in weights {
    ignore(
      spawn_text_line(
        world,
        weights_column,
        row.0,
        @text.TextFont::TextFont().with_font(family).with_weight(row.1),
      ),
    )
  }

  let widths_column = spawn_node(
    world,
    columns,
    @ui.Node::Node()
    .with_flex_direction(Column)
    .with_padding(@ui.UiRect::all(Px(8.0F)))
    .with_row_gap(Px(8.0F)),
  )
  let widths : Array[(String, @text.FontWidth)] = [
    ("FontWidth::ULTRA_CONDENSED", ULTRA_CONDENSED),
    ("FontWidth::EXTRA_CONDENSED", EXTRA_CONDENSED),
    ("FontWidth::CONDENSED", CONDENSED),
    ("FontWidth::SEMI_CONDENSED", SEMI_CONDENSED),
    ("FontWidth::NORMAL", NORMAL),
    ("FontWidth::SEMI_EXPANDED", SEMI_EXPANDED),
    ("FontWidth::EXPANDED", EXPANDED),
    ("FontWidth::EXTRA_EXPANDED", EXTRA_EXPANDED),
    ("FontWidth::ULTRA_EXPANDED", ULTRA_EXPANDED),
  ]
  for row in widths {
    ignore(
      spawn_text_line(
        world,
        widths_column,
        row.0,
        @text.TextFont::TextFont().with_font(family).with_width(row.1),
      ),
    )
  }

  let styles_column = spawn_node(
    world,
    columns,
    @ui.Node::Node()
    .with_flex_direction(Column)
    .with_padding(@ui.UiRect::all(Px(8.0F)))
    .with_row_gap(Px(8.0F)),
  )
  let styles : Array[(String, @text.FontStyle)] = [
    ("FontStyle::Normal", Normal),
    ("FontStyle::Oblique", Oblique(None)),
    ("FontStyle::Italic", Italic),
  ]
  for row in styles {
    ignore(
      spawn_text_line(
        world,
        styles_column,
        row.0,
        @text.TextFont::TextFont().with_font(family).with_style(row.1),
      ),
    )
  }
}
