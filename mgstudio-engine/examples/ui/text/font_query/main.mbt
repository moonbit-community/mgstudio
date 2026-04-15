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
    try! world.set_by_key(
      entity,
      @text.ecs_key_text_underline,
      @text.Underline::default(),
    )
  }
  entity
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.advance_sequence()
  ignore(tick)
  let asset_server = @asset.AssetServer::new()
  let family = asset_server.load_font("fonts/MonaSans-VariableFont.ttf")

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center),
  )

  let panel = spawn_node(
    world,
    root,
    @ui.Node::default()
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_align_items(@ui.AlignItems::Center)
    .with_padding(@ui.UiRect::all(@ui.Val::Px(16.0F)))
    .with_row_gap(@ui.Val::Px(16.0F)),
  )
  ignore(
    spawn_text_line(
      world,
      panel,
      "Font Weights, Widths & Styles",
      @text.TextFont::default()
      .with_font(family)
      .with_font_size(@text.FontSize::Px(32.0F)),
      underline=true,
    ),
  )

  let columns = spawn_node(
    world,
    panel,
    @ui.Node::default()
    .with_flex_direction(@ui.FlexDirection::Row)
    .with_column_gap(@ui.Val::Px(32.0F)),
  )

  let weights_column = spawn_node(
    world,
    columns,
    @ui.Node::default()
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_padding(@ui.UiRect::all(@ui.Val::Px(8.0F)))
    .with_row_gap(@ui.Val::Px(8.0F)),
  )
  let weights : Array[(String, @text.FontWeight)] = [
    ("Weight 100 (Thin)", @text.FontWeight::THIN),
    ("Weight 200 (Extra Light)", @text.FontWeight::EXTRA_LIGHT),
    ("Weight 300 (Light)", @text.FontWeight::LIGHT),
    ("Weight 400 (Normal)", @text.FontWeight::NORMAL),
    ("Weight 500 (Medium)", @text.FontWeight::MEDIUM),
    ("Weight 600 (Semibold)", @text.FontWeight::SEMIBOLD),
    ("Weight 700 (Bold)", @text.FontWeight::BOLD),
    ("Weight 800 (Extra Bold)", @text.FontWeight::EXTRA_BOLD),
    ("Weight 900 (Black)", @text.FontWeight::BLACK),
  ]
  for row in weights {
    ignore(
      spawn_text_line(
        world,
        weights_column,
        row.0,
        @text.TextFont::default().with_font(family).with_weight(row.1),
      ),
    )
  }

  let widths_column = spawn_node(
    world,
    columns,
    @ui.Node::default()
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_padding(@ui.UiRect::all(@ui.Val::Px(8.0F)))
    .with_row_gap(@ui.Val::Px(8.0F)),
  )
  let widths : Array[(String, @text.FontWidth)] = [
    ("FontWidth::ULTRA_CONDENSED", @text.FontWidth::ULTRA_CONDENSED),
    ("FontWidth::EXTRA_CONDENSED", @text.FontWidth::EXTRA_CONDENSED),
    ("FontWidth::CONDENSED", @text.FontWidth::CONDENSED),
    ("FontWidth::SEMI_CONDENSED", @text.FontWidth::SEMI_CONDENSED),
    ("FontWidth::NORMAL", @text.FontWidth::NORMAL),
    ("FontWidth::SEMI_EXPANDED", @text.FontWidth::SEMI_EXPANDED),
    ("FontWidth::EXPANDED", @text.FontWidth::EXPANDED),
    ("FontWidth::EXTRA_EXPANDED", @text.FontWidth::EXTRA_EXPANDED),
    ("FontWidth::ULTRA_EXPANDED", @text.FontWidth::ULTRA_EXPANDED),
  ]
  for row in widths {
    ignore(
      spawn_text_line(
        world,
        widths_column,
        row.0,
        @text.TextFont::default().with_font(family).with_width(row.1),
      ),
    )
  }

  let styles_column = spawn_node(
    world,
    columns,
    @ui.Node::default()
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_padding(@ui.UiRect::all(@ui.Val::Px(8.0F)))
    .with_row_gap(@ui.Val::Px(8.0F)),
  )
  let styles : Array[(String, @text.FontStyle)] = [
    ("FontStyle::Normal", @text.FontStyle::Normal),
    ("FontStyle::Oblique", @text.FontStyle::Oblique(None)),
    ("FontStyle::Italic", @text.FontStyle::Italic),
  ]
  for row in styles {
    ignore(
      spawn_text_line(
        world,
        styles_column,
        row.0,
        @text.TextFont::default().with_font(family).with_style(row.1),
      ),
    )
  }
}
