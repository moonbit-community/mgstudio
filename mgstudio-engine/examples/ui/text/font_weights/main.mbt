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
fn setup(world : @ecs.World) -> Unit {
  ignore(world.advance_sequence())
  let asset_server = @asset.AssetServer::new()
  let variable_font = asset_server.load_font("fonts/MonaSans-VariableFont.ttf")

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
    .with_row_gap(@ui.Val::Px(8.0F)),
  )

  ignore(
    spawn_text_line(
      world,
      panel,
      "Font Weights",
      @text.TextFont::default()
      .with_font(variable_font)
      .with_font_size(@text.FontSize::Px(32.0F)),
      underline=true,
    ),
  )

  let weights : Array[Int] = [
    100, 134, 200, 300, 400, 500, 600, 700, 800, 900, 950,
  ]
  for weight in weights {
    ignore(
      spawn_text_line(
        world,
        panel,
        "Weight \{weight}",
        @text.TextFont::default()
        .with_font(variable_font)
        .with_font_size(@text.FontSize::Px(32.0F))
        .with_weight(@text.FontWeight::VALUE(weight)),
      ),
    )
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}
