// Copyright 2025 International Digital Economy Academy
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
fn seed_text_assets(world : @ecs.World) -> Unit {
  let image_assets_key : @ecs.ResourceKey[@asset.Assets[@asset.Image]] = @asset.assets_resource_key()
  let atlas_assets_key : @ecs.ResourceKey[
    @asset.Assets[@asset.TextureAtlasLayout],
  ] = @asset.assets_resource_key()
  world.insert_resource(
    @asset.asset_server_resource_key,
    @asset.AssetServer::new(),
  )
  world.insert_resource(image_assets_key, @asset.Assets::new())
  world.insert_resource(atlas_assets_key, @asset.Assets::new())
}

///|
test "ui: layout computes rect and camera-compensated transform" {
  let world = @ecs.World::new()
  defer world.close()
  let tick = world.increment_change_tick()
  ignore(tick)

  // Seed UiContext to avoid any host texture calls in tests.
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot())
  let node = world.spawn_empty()
  try! world.set_by_key(
    node,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    node,
    ecs_key_node,
    Node::Node()
    .with_position_type(Absolute)
    .with_left(Px(40.0F))
    .with_top(Px(50.0F))
    .with_width(Px(200.0F))
    .with_height(Px(60.0F)),
  )

  // Build Children from Parent before layout.
  ui_layout_system(world)
  let rect = try! world.get_by_key(node, ecs_key_ui_layout).unwrap().rect
  let ok_rect = rect.min.x == 40.0F &&
    rect.min.y == 50.0F &&
    rect.max.x == 240.0F &&
    rect.max.y == 110.0F
  debug_inspect(ok_rect, content="true")
  let t = try! world.get_by_key(node, @transform.ecs_key_transform).unwrap()
  // Expected center in viewport coords: (140, 80)
  // Viewport center origin (+Y up): (-260, 220)
  let ok_pos = t.translation.x == -260.0F && t.translation.y == 220.0F
  debug_inspect(ok_pos, content="true")

  // Camera move + scale compensation.
  let ctx2 = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::from_xyz(100.0F, 50.0F, 0.0F),
    2.0F,
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx2)
  ui_layout_system(world)
  let t2 = try! world.get_by_key(node, @transform.ecs_key_transform).unwrap()
  // (-260, 220) * 2 + (100, 50) = (-420, 490)
  let ok_pos2 = t2.translation.x == -420.0F && t2.translation.y == 490.0F
  debug_inspect(ok_pos2, content="true")
  let ok_scale2 = t2.scale.x == 2.0F && t2.scale.y == 2.0F
  debug_inspect(ok_scale2, content="true")
}

///|
test "ui: layout stores Bevy-style resolved node geometry" {
  let world = @ecs.World::new()
  defer world.close()
  let tick = world.increment_change_tick()
  ignore(tick)
  get_ui_context_resource(world).insert(
    UiContext::new(
      @asset.Handle::new(1),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(800.0F, 600.0F),
      Some(@core.Entity::new(0, 0)),
      @transform.Transform::identity(),
      1.0F,
      None,
      false,
    ),
  )
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot())
  let node = world.spawn_empty()
  try! world.set_by_key(
    node,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    node,
    ecs_key_node,
    Node::Node()
    .with_position_type(Absolute)
    .with_left(Px(40.0F))
    .with_top(Px(50.0F))
    .with_width(Px(200.0F))
    .with_height(Px(60.0F))
    .with_border(UiRect::px(2.0F, 4.0F, 6.0F, 8.0F))
    .with_padding(UiRect::px(10.0F, 12.0F, 14.0F, 16.0F))
    .with_border_radius(
      BorderRadius::new(Px(12.0F), Percent(50.0F), Px(200.0F), Auto),
    ),
  )
  try! world.set_by_key(
    node,
    ecs_key_outline,
    Outline::new(Px(3.0F), Px(5.0F), @color.Color::white()),
  )
  ui_layout_system(world)
  let layout = try! world.get_by_key(node, ecs_key_ui_layout).unwrap()
  debug_inspect(layout.border.left == 2.0F, content="true")
  debug_inspect(layout.border.right == 4.0F, content="true")
  debug_inspect(layout.border.top == 6.0F, content="true")
  debug_inspect(layout.border.bottom == 8.0F, content="true")
  debug_inspect(layout.padding.left == 10.0F, content="true")
  debug_inspect(layout.padding.right == 12.0F, content="true")
  debug_inspect(layout.padding.top == 14.0F, content="true")
  debug_inspect(layout.padding.bottom == 16.0F, content="true")
  debug_inspect(layout.border_radius.top_left == 12.0F, content="true")
  debug_inspect(layout.border_radius.top_right == 30.0F, content="true")
  debug_inspect(layout.border_radius.bottom_right == 30.0F, content="true")
  debug_inspect(layout.border_radius.bottom_left == 0.0F, content="true")
  debug_inspect(layout.outline_width() == 3.0F, content="true")
  debug_inspect(layout.outline_offset() == 5.0F, content="true")
  debug_inspect(layout.outlined_node_size().x == 216.0F, content="true")
  debug_inspect(layout.outlined_node_size().y == 76.0F, content="true")
  let content_inset = layout.content_inset()
  debug_inspect(content_inset.left == 12.0F, content="true")
  debug_inspect(content_inset.top == 20.0F, content="true")
  debug_inspect(content_inset.right == 16.0F, content="true")
  debug_inspect(content_inset.bottom == 24.0F, content="true")
  let padding_box = layout.padding_box()
  debug_inspect(padding_box.min.x == -98.0F, content="true")
  debug_inspect(padding_box.min.y == -24.0F, content="true")
  debug_inspect(padding_box.max.x == 96.0F, content="true")
  debug_inspect(padding_box.max.y == 22.0F, content="true")
  let content_box = layout.content_box()
  debug_inspect(content_box.min.x == -88.0F, content="true")
  debug_inspect(content_box.min.y == -10.0F, content="true")
  debug_inspect(content_box.max.x == 84.0F, content="true")
  debug_inspect(content_box.max.y == 6.0F, content="true")
  let outline_radius = layout.outline_radius()
  debug_inspect(outline_radius.top_left == 20.0F, content="true")
  debug_inspect(outline_radius.top_right == 38.0F, content="true")
  debug_inspect(outline_radius.bottom_right == 38.0F, content="true")
  debug_inspect(outline_radius.bottom_left == 0.0F, content="true")
}

///|
test "ui: pointer conversion to viewport space" {
  let pos = @math.Vec2::new(20.0F, 40.0F)
  let origin = @math.Vec2::new(10.0F, 15.0F)
  let size = @math.Vec2::new(100.0F, 100.0F)
  let in_view = ui_pointer_pos_in_viewport(pos, origin, size)
  debug_inspect(
    in_view.unwrap().x == 10.0F && in_view.unwrap().y == 25.0F,
    content="true",
  )
  let out_view = ui_pointer_pos_in_viewport(
    @math.Vec2::new(5.0F, 0.0F),
    origin,
    size,
  )
  debug_inspect(out_view is None, content="true")
}

///|
test "ui: hidden overflow axis ignores stale scroll offset" {
  let world = @ecs.World::new()
  defer world.close()
  let tick = world.increment_change_tick()
  ignore(tick)
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot())
  let panel = world.spawn_empty()
  try! world.set_by_key(
    panel,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    panel,
    ecs_key_node,
    Node::Node()
    .with_width(Px(200.0F))
    .with_height(Px(120.0F))
    .with_overflow(Overflow::new(Hidden, Scroll)),
  )
  try! world.set_by_key(
    panel,
    ecs_key_scroll_position,
    ScrollPosition::new(180.0F, 24.0F),
  )
  let child = world.spawn_empty()
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(panel),
  )
  try! world.set_by_key(
    child,
    ecs_key_node,
    Node::Node()
    .with_position_type(Absolute)
    .with_left(Px(0.0F))
    .with_top(Px(0.0F))
    .with_width(Px(100.0F))
    .with_height(Px(20.0F)),
  )
  ui_layout_system(world)
  let panel_rect = try! world.get_by_key(panel, ecs_key_ui_layout).unwrap().rect
  let child_rect = try! world.get_by_key(child, ecs_key_ui_layout).unwrap().rect
  debug_inspect(child_rect.min.x == panel_rect.min.x, content="true")
  debug_inspect(child_rect.min.y == panel_rect.min.y - 24.0F, content="true")
}

///|
test "ui: ghost node children layout as direct descendants" {
  let world = @ecs.World::new()
  defer world.close()
  let tick = world.increment_change_tick()
  ignore(tick)
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot())
  let container = world.spawn_empty()
  try! world.set_by_key(
    container,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    container,
    ecs_key_node,
    Node::Node()
    .with_width(Px(300.0F))
    .with_height(Px(80.0F))
    .with_flex_direction(Row),
  )
  let first = world.spawn_empty()
  try! world.set_by_key(
    first,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(container),
  )
  try! world.set_by_key(
    first,
    ecs_key_node,
    Node::Node().with_width(Px(100.0F)).with_height(Px(80.0F)),
  )
  let ghost = world.spawn_empty()
  try! world.set_by_key(
    ghost,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(container),
  )
  try! world.set_by_key(ghost, ecs_key_ghost_node, GhostNode())
  let second = world.spawn_empty()
  try! world.set_by_key(
    second,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(ghost),
  )
  try! world.set_by_key(
    second,
    ecs_key_node,
    Node::Node().with_width(Px(100.0F)).with_height(Px(80.0F)),
  )

  ui_layout_system(world)

  debug_inspect(
    try! (world.get_by_key(ghost, ecs_key_ui_layout) is None),
    content="true",
  )
  let first_rect = try! world.get_by_key(first, ecs_key_ui_layout).unwrap().rect
  let second_rect = try! world.get_by_key(second, ecs_key_ui_layout).unwrap().rect
  debug_inspect(second_rect.min.x == first_rect.max.x, content="true")
  debug_inspect(second_rect.min.y == first_rect.min.y, content="true")
  ui_stack_system(world)
  let stack = get_ui_stack_resource(world).get().unwrap().uinodes()
  debug_inspect(stack.length() == 4, content="true")
}

///|
test "ui: effective children flatten ghost nodes and skip non-ui children" {
  let world = @ecs.World::new()
  defer world.close()
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot())
  let container = world.spawn_empty()
  let direct_node = world.spawn_empty()
  let ghost = world.spawn_empty()
  let ghost_node = world.spawn_empty()
  let non_ui = world.spawn_empty()
  let stray_node = world.spawn_empty()
  try! world.set_by_key(
    container,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    container,
    ecs_key_node,
    Node::Node()
    .with_width(Px(300.0F))
    .with_height(Px(80.0F))
    .with_flex_direction(Row),
  )
  try! world.set_by_key(
    direct_node,
    ecs_key_node,
    Node::Node().with_width(Px(100.0F)).with_height(Px(80.0F)),
  )
  try! world.set_by_key(ghost, ecs_key_ghost_node, GhostNode())
  try! world.set_by_key(
    ghost_node,
    ecs_key_node,
    Node::Node().with_width(Px(100.0F)).with_height(Px(80.0F)),
  )
  try! world.set_by_key(
    stray_node,
    ecs_key_node,
    Node::Node().with_width(Px(100.0F)).with_height(Px(80.0F)),
  )
  try! world.set_by_key(
    root,
    @hierarchy.ecs_key_children,
    @hierarchy.Children::new([container]),
  )
  try! world.set_by_key(
    container,
    @hierarchy.ecs_key_children,
    @hierarchy.Children::new([direct_node, ghost, non_ui]),
  )
  try! world.set_by_key(
    direct_node,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(container),
  )
  try! world.set_by_key(
    ghost,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(container),
  )
  try! world.set_by_key(
    non_ui,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(container),
  )
  try! world.set_by_key(
    ghost,
    @hierarchy.ecs_key_children,
    @hierarchy.Children::new([ghost_node]),
  )
  try! world.set_by_key(
    ghost_node,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(ghost),
  )
  try! world.set_by_key(
    non_ui,
    @hierarchy.ecs_key_children,
    @hierarchy.Children::new([stray_node]),
  )
  try! world.set_by_key(
    stray_node,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(non_ui),
  )

  ui_layout_system(world)
  let direct_rect = try! world
    .get_by_key(direct_node, ecs_key_ui_layout)
    .unwrap().rect
  let ghost_rect = try! world.get_by_key(ghost_node, ecs_key_ui_layout).unwrap().rect
  debug_inspect(ghost_rect.min.x == direct_rect.max.x, content="true")
  debug_inspect(
    try! (world.get_by_key(non_ui, ecs_key_ui_layout) is None),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(stray_node, ecs_key_ui_layout) is None),
    content="true",
  )
}

///|
test "ui: flex row cross-axis stretch fills child height" {
  let world = @ecs.World::new()
  defer world.close()
  let tick = world.increment_change_tick()
  ignore(tick)
  get_ui_context_resource(world).insert(
    UiContext::new(
      @asset.Handle::new(1),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(800.0F, 600.0F),
      Some(@core.Entity::new(0, 0)),
      @transform.Transform::identity(),
      1.0F,
      None,
      false,
    ),
  )
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot())
  let container = world.spawn_empty()
  try! world.set_by_key(
    container,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    container,
    ecs_key_node,
    Node::Node()
    .with_width(Px(12.0F))
    .with_height(Px(200.0F))
    .with_flex_direction(Row)
    .with_align_items(Stretch),
  )
  let child = world.spawn_empty()
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(container),
  )
  try! world.set_by_key(child, ecs_key_node, Node::Node().with_width(Px(6.0F)))
  ui_layout_system(world)
  let child_size = try! world
    .get_by_key(child, ecs_key_ui_layout)
    .unwrap()
    .size()
  debug_inspect(child_size.x == 6.0F, content="true")
  debug_inspect(child_size.y == 200.0F, content="true")
}

///|
test "ui: vertical slider shaped nested flex keeps track visible" {
  let world = @ecs.World::new()
  defer world.close()
  let tick = world.increment_change_tick()
  ignore(tick)
  get_ui_context_resource(world).insert(
    UiContext::new(
      @asset.Handle::new(1),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(800.0F, 600.0F),
      Some(@core.Entity::new(0, 0)),
      @transform.Transform::identity(),
      1.0F,
      None,
      false,
    ),
  )
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot())
  try! world.set_by_key(
    root,
    ecs_key_node,
    Node::Node()
    .with_width(Percent(100.0F))
    .with_height(Percent(100.0F))
    .with_flex_direction(Row)
    .with_align_items(Center)
    .with_justify_content(Center),
  )
  let column = world.spawn_empty()
  try! world.set_by_key(
    column,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    column,
    ecs_key_node,
    Node::Node()
    .with_flex_direction(Column)
    .with_align_items(Center)
    .with_row_gap(Px(10.0F)),
  )
  let title = world.spawn_empty()
  try! world.set_by_key(
    title,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(column),
  )
  try! world.set_by_key(
    title,
    ecs_key_node,
    Node::Node().with_width(Px(100.0F)).with_height(Px(20.0F)),
  )
  let label = world.spawn_empty()
  try! world.set_by_key(
    label,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(column),
  )
  try! world.set_by_key(
    label,
    ecs_key_node,
    Node::Node().with_width(Px(30.0F)).with_height(Px(24.0F)),
  )
  let slider = world.spawn_empty()
  try! world.set_by_key(
    slider,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(column),
  )
  try! world.set_by_key(
    slider,
    ecs_key_node,
    Node::Node()
    .with_flex_direction(Row)
    .with_justify_content(Center)
    .with_align_items(Stretch)
    .with_width(Px(12.0F))
    .with_height(Px(200.0F)),
  )
  let track = world.spawn_empty()
  try! world.set_by_key(
    track,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(slider),
  )
  try! world.set_by_key(track, ecs_key_node, Node::Node().with_width(Px(6.0F)))
  let thumb_container = world.spawn_empty()
  try! world.set_by_key(
    thumb_container,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(slider),
  )
  try! world.set_by_key(
    thumb_container,
    ecs_key_node,
    Node::Node()
    .with_position_type(Absolute)
    .with_top(Px(12.0F))
    .with_bottom(Px(0.0F))
    .with_left(Px(0.0F))
    .with_right(Px(0.0F)),
  )
  let thumb = world.spawn_empty()
  try! world.set_by_key(
    thumb,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(thumb_container),
  )
  try! world.set_by_key(
    thumb,
    ecs_key_node,
    Node::Node()
    .with_width(Px(12.0F))
    .with_height(Px(12.0F))
    .with_position_type(Absolute)
    .with_bottom(Percent(50.0F)),
  )
  ui_layout_system(world)
  let track_size = try! world
    .get_by_key(track, ecs_key_ui_layout)
    .unwrap()
    .size()
  let thumb_size = try! world
    .get_by_key(thumb, ecs_key_ui_layout)
    .unwrap()
    .size()
  debug_inspect(track_size.x == 6.0F, content="true")
  debug_inspect(track_size.y == 200.0F, content="true")
  debug_inspect(thumb_size.x == 12.0F, content="true")
  debug_inspect(thumb_size.y == 12.0F, content="true")
}

///|
test "ui: editable text transform stays in input content box and in front" {
  let world = @ecs.World::new()
  defer world.close()
  let tick = world.increment_change_tick()
  ignore(tick)
  seed_text_assets(world)
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot())
  let editable = world.spawn_empty()
  try! world.set_by_key(
    editable,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    editable,
    ecs_key_node,
    Node::Node()
    .with_position_type(Absolute)
    .with_left(Px(120.0F))
    .with_top(Px(360.0F))
    .with_width(Px(420.0F))
    .with_height(Px(48.0F))
    .with_padding(UiRect::all(Px(8.0F))),
  )
  try! world.set_by_key(
    editable,
    @text.ecs_key_text,
    @text.Text::new("Editable status"),
  )
  world.set_by_key(
    editable,
    @text.ecs_key_text_font,
    @text.TextFont::TextFont().with_font_size(24.0F),
  )
  @text.ui_text_sync_ecs_system(world)
  ui_layout_system(world)
  let layout = try! world.get_by_key(editable, ecs_key_ui_layout).unwrap().rect
  let content_rect = @math.Rect::new(
    @math.Vec2::new(layout.min.x + 8.0F, layout.min.y + 8.0F),
    @math.Vec2::new(layout.max.x - 8.0F, layout.max.y - 8.0F),
  )
  let center = content_rect.center()
  let expected_x = center.x - 400.0F
  let expected_y = 300.0F - center.y
  let text_handle = @text.ui_text_ecs_handle(world, editable).unwrap()
  let t0 = @text.text_get_transform(text_handle).unwrap()
  debug_inspect(t0.translation.x == expected_x, content="true")
  debug_inspect(t0.translation.y == expected_y, content="true")
  let text_size = @text.text_get_layout_size(text_handle).unwrap()
  debug_inspect(text_size.y <= 32.0F, content="true")
  ui_stack_system(world)
  let editable_transform = try! world
    .get_by_key(editable, @transform.ecs_key_transform)
    .unwrap()
  let t1 = @text.text_get_transform(text_handle).unwrap()
  debug_inspect(t1.translation.x == expected_x, content="true")
  debug_inspect(t1.translation.y == expected_y, content="true")
  debug_inspect(
    t1.translation.z > editable_transform.translation.z,
    content="true",
  )
}

///|
test "ui: editable status text renders in front of editable background (z-order)" {
  let world = @ecs.World::new()
  defer world.close()
  let tick = world.increment_change_tick()
  ignore(tick)
  seed_text_assets(world)
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot())
  let editable = world.spawn_empty()
  try! world.set_by_key(
    editable,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    editable,
    ecs_key_node,
    Node::Node()
    .with_position_type(Absolute)
    .with_left(Px(40.0F))
    .with_top(Px(420.0F))
    .with_width(Px(420.0F))
    .with_height(Px(48.0F))
    .with_padding(UiRect::all(Px(8.0F))),
  )
  try! world.set_by_key(
    editable,
    ecs_key_background_color,
    BackgroundColor::new(@color.Color::new(0.12F, 0.12F, 0.16F, 1.0F)),
  )
  try! world.set_by_key(
    editable,
    @text.ecs_key_text,
    @text.Text::new("Editable status"),
  )
  world.set_by_key(
    editable,
    @text.ecs_key_text_font,
    @text.TextFont::TextFont().with_font_size(24.0F),
  )
  @text.ui_text_sync_ecs_system(world)
  ui_layout_system(world)
  ui_stack_system(world)
  let background_transform = try! world
    .get_by_key(editable, @transform.ecs_key_transform)
    .unwrap()
  let text_handle = @text.ui_text_ecs_handle(world, editable).unwrap()
  let text_transform = @text.text_get_transform(text_handle).unwrap()
  debug_inspect(
    text_transform.translation.z > background_transform.translation.z,
    content="true",
  )
}

///|
test "ui: editable label node is laid out above input box node" {
  let world = @ecs.World::new()
  defer world.close()
  let tick = world.increment_change_tick()
  ignore(tick)
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot())
  let group = world.spawn_empty()
  try! world.set_by_key(
    group,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    group,
    ecs_key_node,
    Node::Node()
    .with_position_type(Absolute)
    .with_left(Px(120.0F))
    .with_top(Px(360.0F))
    .with_width(Px(420.0F))
    .with_flex_direction(Column)
    .with_row_gap(Px(8.0F)),
  )
  let label = world.spawn_empty()
  try! world.set_by_key(
    label,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(group),
  )
  try! world.set_by_key(
    label,
    ecs_key_node,
    Node::Node().with_width(Auto).with_height(Auto),
  )
  let editable = world.spawn_empty()
  try! world.set_by_key(
    editable,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(group),
  )
  try! world.set_by_key(
    editable,
    ecs_key_node,
    Node::Node()
    .with_width(Px(420.0F))
    .with_height(Px(48.0F))
    .with_padding(UiRect::all(Px(8.0F))),
  )
  try! world.set_by_key(
    label,
    ecs_key_content_size,
    ContentSize::new(@math.Vec2::new(220.0F, 32.0F)),
  )
  ui_layout_system(world)
  let label_rect = try! world.get_by_key(label, ecs_key_ui_layout).unwrap().rect
  let editable_rect = try! world
    .get_by_key(editable, ecs_key_ui_layout)
    .unwrap().rect
  debug_inspect(label_rect.max.y <= editable_rect.min.y, content="true")
  debug_inspect(editable_rect.min.y - label_rect.max.y == 8.0F, content="true")
}

///|
test "ui: scroll panel text inherits clip rect from overflow parent" {
  let world = @ecs.World::new()
  defer world.close()
  let tick = world.increment_change_tick()
  ignore(tick)
  seed_text_assets(world)
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot())
  let panel = world.spawn_empty()
  try! world.set_by_key(
    panel,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    panel,
    ecs_key_node,
    Node::Node()
    .with_position_type(Absolute)
    .with_left(Px(40.0F))
    .with_top(Px(80.0F))
    .with_width(Px(420.0F))
    .with_height(Px(190.0F))
    .with_overflow(Overflow::new(Hidden, Scroll))
    .with_padding(UiRect::all(Px(10.0F))),
  )
  let panel_content = world.spawn_empty()
  try! world.set_by_key(
    panel_content,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(panel),
  )
  try! world.set_by_key(
    panel_content,
    ecs_key_node,
    Node::Node()
    .with_width(Px(760.0F))
    .with_height(Px(420.0F))
    .with_padding(UiRect::all(Px(12.0F))),
  )
  let panel_text = world.spawn_empty()
  try! world.set_by_key(
    panel_text,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(panel_content),
  )
  try! world.set_by_key(
    panel_text,
    ecs_key_node,
    Node::Node().with_width(Px(720.0F)).with_height(Auto),
  )
  world.set_by_key(
    panel_text,
    @text.ecs_key_text,
    @text.Text::new(
      "Scrollable panel (clip + scissor test)\nUse wheel or screen reader scroll actions.\nLine 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8\nLine 9\nLine 10",
    ),
  )
  world.set_by_key(
    panel_text,
    @text.ecs_key_text_font,
    @text.TextFont::TextFont().with_font_size(18.0F),
  )
  @text.ui_text_sync_ecs_system(world)
  ui_layout_system(world)
  ui_clip_system(world)
  let panel_rect = try! world.get_by_key(panel, ecs_key_ui_layout).unwrap().rect
  let handle = @text.ui_text_ecs_handle(world, panel_text).unwrap()
  let clip_opt = @text.text_get_ui_scissor(handle)
  debug_inspect(clip_opt is Some(_), content="true")
  let clip = clip_opt.unwrap()
  debug_inspect(clip.min.x == panel_rect.min.x + 10.0F, content="true")
  debug_inspect(clip.min.y == panel_rect.min.y + 10.0F, content="true")
  debug_inspect(clip.max.x == panel_rect.max.x - 10.0F, content="true")
  debug_inspect(clip.max.y == panel_rect.max.y - 10.0F, content="true")
}

///|
test "ui: panel text scissor stays above editable title block" {
  let world = @ecs.World::new()
  defer world.close()
  let tick = world.increment_change_tick()
  ignore(tick)
  seed_text_assets(world)
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot())
  try! world.set_by_key(
    root,
    ecs_key_node,
    Node::Node()
    .with_width(Px(800.0F))
    .with_height(Px(600.0F))
    .with_flex_direction(Column)
    .with_row_gap(Px(18.0F))
    .with_padding(UiRect::all(Px(24.0F))),
  )
  let panel = world.spawn_empty()
  try! world.set_by_key(
    panel,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    panel,
    ecs_key_node,
    Node::Node()
    .with_width(Px(420.0F))
    .with_height(Px(190.0F))
    .with_overflow(Overflow::new(Hidden, Scroll))
    .with_padding(UiRect::all(Px(10.0F))),
  )
  let panel_content = world.spawn_empty()
  try! world.set_by_key(
    panel_content,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(panel),
  )
  try! world.set_by_key(
    panel_content,
    ecs_key_node,
    Node::Node()
    .with_width(Px(760.0F))
    .with_height(Px(420.0F))
    .with_padding(UiRect::all(Px(12.0F))),
  )
  let panel_text = world.spawn_empty()
  try! world.set_by_key(
    panel_text,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(panel_content),
  )
  try! world.set_by_key(
    panel_text,
    ecs_key_node,
    Node::Node().with_width(Px(720.0F)).with_height(Auto),
  )
  world.set_by_key(
    panel_text,
    @text.ecs_key_text,
    @text.Text::new(
      "Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8\nLine 9\nLine 10",
    ),
  )
  world.set_by_key(
    panel_text,
    @text.ecs_key_text_font,
    @text.TextFont::TextFont().with_font_size(18.0F),
  )
  let editable_section = world.spawn_empty()
  try! world.set_by_key(
    editable_section,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    editable_section,
    ecs_key_node,
    Node::Node()
    .with_width(Px(420.0F))
    .with_flex_direction(Column)
    .with_row_gap(Px(8.0F)),
  )
  let editable_title = world.spawn_empty()
  try! world.set_by_key(
    editable_title,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(editable_section),
  )
  try! world.set_by_key(
    editable_title,
    ecs_key_node,
    Node::Node().with_width(Auto).with_height(Px(32.0F)),
  )
  try! world.set_by_key(
    editable_title,
    @text.ecs_key_text,
    @text.Text::new("Editable status"),
  )
  world.set_by_key(
    editable_title,
    @text.ecs_key_text_font,
    @text.TextFont::TextFont().with_font_size(24.0F),
  )
  @text.ui_text_sync_ecs_system(world)
  ui_layout_system(world)
  ui_clip_system(world)
  let panel_handle = @text.ui_text_ecs_handle(world, panel_text).unwrap()
  let scissor = @text.text_get_ui_scissor(panel_handle).unwrap()
  let title_rect = try! world
    .get_by_key(editable_title, ecs_key_ui_layout)
    .unwrap().rect
  debug_inspect(scissor.max.y <= title_rect.min.y, content="true")
}
