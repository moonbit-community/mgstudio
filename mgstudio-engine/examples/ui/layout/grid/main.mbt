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
  { ..node, display, }
}

///|
fn node_with_aspect_ratio(node : @ui.Node, aspect_ratio : Float) -> @ui.Node {
  { ..node, aspect_ratio: Some(aspect_ratio) }
}

///|
fn spawn_text(
  world : @ecs.World,
  parent : @core.Entity,
  content : String,
  font : @asset.Handle[@asset.Font],
  color : @color.Color,
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
    @text.TextFont::TextFont()
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
  let tick = world.increment_change_tick()
  ignore(tick)
  let font = @asset.AssetServer::new().load_font("fonts/FiraSans-Bold.ttf")

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
    node_with_display(Node(), Grid)
    .with_width(Percent(100.0F))
    .with_height(Percent(100.0F))
    .with_grid_template_columns([
      @ui.RepeatedGridTrack::new(Count(1), [MinContent]),
      @ui.RepeatedGridTrack::new(Count(1), [Fr(1.0F)]),
    ])
    .with_grid_template_rows([
      @ui.RepeatedGridTrack::new(Count(1), [Auto]),
      @ui.RepeatedGridTrack::new(Count(1), [Fr(1.0F)]),
      @ui.RepeatedGridTrack::new(Count(1), [Px(20.0F)]),
    ]),
  )
  try! world.set_by_key(
    root,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@color.Color::white()),
  )

  let header = world.spawn_empty()
  try! world.set_by_key(
    header,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(header, @ui.ecs_key_node, {
    ..node_with_display(Node(), Grid).with_padding(@ui.UiRect::all(Px(6.0F))),
    grid_column: @ui.GridPlacement::span(2),
  })
  ignore(
    spawn_text(
      world,
      header,
      "Grid layout example",
      font,
      @color.Color::black(),
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
      node_with_display(Node(), Grid)
      .with_height(Percent(100.0F))
      .with_padding(@ui.UiRect::all(Px(24.0F)))
      .with_grid_template_columns([
        @ui.RepeatedGridTrack::new(Count(4), [Fr(1.0F)]),
      ])
      .with_grid_template_rows([
        @ui.RepeatedGridTrack::new(Count(4), [Fr(1.0F)]),
      ])
      .with_row_gap(Px(12.0F))
      .with_column_gap(Px(12.0F)),
      1.0F,
    ),
  )
  try! world.set_by_key(
    main_grid,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@color.Color::srgb(0.25F, 0.25F, 0.25F)),
  )

  let colors : Array[@color.Color] = [
    @color.Color::srgb(1.0F, 0.647F, 0.0F),
    @color.Color::srgb(1.0F, 0.894F, 0.769F),
    @color.Color::srgb(0.0F, 0.0F, 1.0F),
    @color.Color::srgb(0.863F, 0.078F, 0.235F),
    @color.Color::srgb(0.0F, 1.0F, 1.0F),
    @color.Color::srgb(1.0F, 0.271F, 0.0F),
    @color.Color::srgb(0.0F, 0.392F, 0.0F),
    @color.Color::srgb(1.0F, 0.0F, 1.0F),
    @color.Color::srgb(0.0F, 0.5F, 0.5F),
    @color.Color::srgb(0.941F, 0.973F, 1.0F),
    @color.Color::srgb(1.0F, 0.863F, 0.769F),
    @color.Color::srgb(1.0F, 1.0F, 0.0F),
    @color.Color::srgb(1.0F, 0.078F, 0.576F),
    @color.Color::srgb(0.604F, 0.804F, 0.196F),
    @color.Color::srgb(0.98F, 0.502F, 0.447F),
    @color.Color::srgb(0.255F, 0.412F, 0.882F),
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
      node_with_display(Node(), Grid).with_padding(@ui.UiRect::all(Px(3.0F))),
    )
    try! world.set_by_key(
      frame,
      @ui.ecs_key_background_color,
      @ui.BackgroundColor::new(@color.Color::black()),
    )

    let inner = world.spawn_empty()
    try! world.set_by_key(
      inner,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(frame),
    )
    try! world.set_by_key(inner, @ui.ecs_key_node, Node())
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
  try! world.set_by_key(sidebar, @ui.ecs_key_node, {
    ..node_with_display(Node(), Grid)
    .with_align_items(Start)
    .with_padding(@ui.UiRect::all(Px(10.0F)))
    .with_grid_template_rows([
      @ui.RepeatedGridTrack::new(Count(1), [Auto]),
      @ui.RepeatedGridTrack::new(Count(1), [Auto]),
      @ui.RepeatedGridTrack::new(Count(1), [Fr(1.0F)]),
    ])
    .with_row_gap(Px(10.0F)),
    justify_items: Center,
  })
  try! world.set_by_key(
    sidebar,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@color.Color::black()),
  )
  ignore(spawn_text(world, sidebar, "Sidebar", font, @color.Color::white()))
  ignore(
    spawn_text(
      world,
      sidebar,
      "A paragraph of text which wraps across the sidebar column.",
      font,
      @color.Color::white(),
    ),
  )

  let spacer = world.spawn_empty()
  try! world.set_by_key(
    spacer,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(sidebar),
  )
  try! world.set_by_key(spacer, @ui.ecs_key_node, Node())

  let footer = world.spawn_empty()
  try! world.set_by_key(
    footer,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(footer, @ui.ecs_key_node, {
    ..Node(),
    grid_column: @ui.GridPlacement::span(2),
  })
  try! world.set_by_key(
    footer,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@color.Color::white()),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_startup_system(setup)
  .run()
}
