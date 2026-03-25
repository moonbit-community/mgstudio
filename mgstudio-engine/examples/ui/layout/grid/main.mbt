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
fn node_with_display(node : @ui.Node, display : @ui.Display) -> @ui.Node {
  @ui.Node::{ ..node, display, }
}

///|
fn node_with_aspect_ratio(node : @ui.Node, aspect_ratio : Float) -> @ui.Node {
  @ui.Node::{ ..node, aspect_ratio: Some(aspect_ratio) }
}

///|
fn spawn_text(
  world : @ecs.World,
  parent : @core.Entity,
  content : String,
  font : @asset.Handle[@asset.Font],
  color : @sprite.Color,
) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(entity, @text.ecs_key_text, @text.Text::new(content))
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_font,
    @text.TextFont::default()
    .with_font(font)
    .with_font_size(@text.FontSize::Px(16.0F)),
  )
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(color),
  )
  entity
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.advance_sequence()
  ignore(tick)
  let font = @asset.AssetServer::new().load_font("fonts/FiraSans-Bold.ttf")

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
    node_with_display(@ui.Node::default(), @ui.Display::Grid)
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_grid_template_columns([
      @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(1), [
        @ui.GridTrack::MinContent,
      ]),
      @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(1), [
        @ui.GridTrack::Fr(1.0F),
      ]),
    ])
    .with_grid_template_rows([
      @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(1), [
        @ui.GridTrack::Auto,
      ]),
      @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(1), [
        @ui.GridTrack::Fr(1.0F),
      ]),
      @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(1), [
        @ui.GridTrack::Px(20.0F),
      ]),
    ]),
  )
  try! world.set_by_key(
    root,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@sprite.Color::white()),
  )

  let header = world.spawn_empty()
  try! world.set_by_key(
    header,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(header, @ui.ecs_key_node, @ui.Node::{
    ..node_with_display(@ui.Node::default(), @ui.Display::Grid).with_padding(
      @ui.UiRect::all(@ui.Val::Px(6.0F)),
    ),
    grid_column: @ui.GridPlacement::span(2),
  })
  ignore(
    spawn_text(
      world,
      header,
      "Grid layout example",
      font,
      @sprite.Color::black(),
    ),
  )

  let main_grid = world.spawn_empty()
  try! world.set_by_key(
    main_grid,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    main_grid,
    @ui.ecs_key_node,
    node_with_aspect_ratio(
      node_with_display(@ui.Node::default(), @ui.Display::Grid)
      .with_height(@ui.Val::Percent(100.0F))
      .with_padding(@ui.UiRect::all(@ui.Val::Px(24.0F)))
      .with_grid_template_columns([
        @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(4), [
          @ui.GridTrack::Fr(1.0F),
        ]),
      ])
      .with_grid_template_rows([
        @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(4), [
          @ui.GridTrack::Fr(1.0F),
        ]),
      ])
      .with_row_gap(@ui.Val::Px(12.0F))
      .with_column_gap(@ui.Val::Px(12.0F)),
      1.0F,
    ),
  )
  try! world.set_by_key(
    main_grid,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@sprite.Color::srgb(0.25F, 0.25F, 0.25F)),
  )

  let colors : Array[@sprite.Color] = [
    @sprite.Color::srgb(1.0F, 0.647F, 0.0F),
    @sprite.Color::srgb(1.0F, 0.894F, 0.769F),
    @sprite.Color::srgb(0.0F, 0.0F, 1.0F),
    @sprite.Color::srgb(0.863F, 0.078F, 0.235F),
    @sprite.Color::srgb(0.0F, 1.0F, 1.0F),
    @sprite.Color::srgb(1.0F, 0.271F, 0.0F),
    @sprite.Color::srgb(0.0F, 0.392F, 0.0F),
    @sprite.Color::srgb(1.0F, 0.0F, 1.0F),
    @sprite.Color::srgb(0.0F, 0.5F, 0.5F),
    @sprite.Color::srgb(0.941F, 0.973F, 1.0F),
    @sprite.Color::srgb(1.0F, 0.863F, 0.769F),
    @sprite.Color::srgb(1.0F, 1.0F, 0.0F),
    @sprite.Color::srgb(1.0F, 0.078F, 0.576F),
    @sprite.Color::srgb(0.604F, 0.804F, 0.196F),
    @sprite.Color::srgb(0.98F, 0.502F, 0.447F),
    @sprite.Color::srgb(0.255F, 0.412F, 0.882F),
  ]
  for color in colors {
    let frame = world.spawn_empty()
    try! world.set_by_key(
      frame,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(main_grid),
    )
    try! world.set_by_key(
      frame,
      @ui.ecs_key_node,
      node_with_display(@ui.Node::default(), @ui.Display::Grid).with_padding(
        @ui.UiRect::all(@ui.Val::Px(3.0F)),
      ),
    )
    try! world.set_by_key(
      frame,
      @ui.ecs_key_background_color,
      @ui.BackgroundColor::new(@sprite.Color::black()),
    )

    let inner = world.spawn_empty()
    try! world.set_by_key(
      inner,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(frame),
    )
    try! world.set_by_key(inner, @ui.ecs_key_node, @ui.Node::default())
    try! world.set_by_key(
      inner,
      @ui.ecs_key_background_color,
      @ui.BackgroundColor::new(color),
    )
  }

  let sidebar = world.spawn_empty()
  try! world.set_by_key(
    sidebar,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(sidebar, @ui.ecs_key_node, @ui.Node::{
    ..node_with_display(@ui.Node::default(), @ui.Display::Grid)
    .with_align_items(@ui.AlignItems::Start)
    .with_padding(@ui.UiRect::all(@ui.Val::Px(10.0F)))
    .with_grid_template_rows([
      @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(1), [
        @ui.GridTrack::Auto,
      ]),
      @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(1), [
        @ui.GridTrack::Auto,
      ]),
      @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(1), [
        @ui.GridTrack::Fr(1.0F),
      ]),
    ])
    .with_row_gap(@ui.Val::Px(10.0F)),
    justify_items: @ui.JustifyItems::Center,
  })
  try! world.set_by_key(
    sidebar,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@sprite.Color::black()),
  )
  ignore(spawn_text(world, sidebar, "Sidebar", font, @sprite.Color::white()))
  ignore(
    spawn_text(
      world,
      sidebar,
      "A paragraph of text which wraps across the sidebar column.",
      font,
      @sprite.Color::white(),
    ),
  )

  let spacer = world.spawn_empty()
  try! world.set_by_key(
    spacer,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(sidebar),
  )
  try! world.set_by_key(spacer, @ui.ecs_key_node, @ui.Node::default())

  let footer = world.spawn_empty()
  try! world.set_by_key(
    footer,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(footer, @ui.ecs_key_node, @ui.Node::{
    ..@ui.Node::default(),
    grid_column: @ui.GridPlacement::span(2),
  })
  try! world.set_by_key(
    footer,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@sprite.Color::white()),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_startup_system(setup)
  .run()
}
