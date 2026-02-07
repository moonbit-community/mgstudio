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
test "ui: layout computes rect and camera-compensated transform" {
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)

  // Seed UiContext to avoid any host texture calls in tests.
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @math.Transform::identity(),
    1.0F,
    None,
    false,
  )
  HasRes_UiContext::get_ui_context_resource(world).insert(ctx, tick)
  let root = world.spawn_empty()
  Has_UiRoot::get_ui_root_store(world).insert(root, UiRoot::default(), tick)
  let node = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    node,
    @hierarchy.Parent::new(root),
    tick,
  )
  Has_Node::get_node_store(world).insert(
    node,
    Node::default()
    .with_position_type(PositionType::Absolute)
    .with_left(Val::Px(40.0F))
    .with_top(Val::Px(50.0F))
    .with_width(Val::Px(200.0F))
    .with_height(Val::Px(60.0F)),
    tick,
  )

  // Build Children from Parent before layout.
  @transform.update_children_system(world)
  ui_layout_system(world)
  let rect = Has_UiLayout::get_ui_layout_store(world).get(node).unwrap().rect
  let ok_rect = rect.min.x == 40.0F &&
    rect.min.y == 50.0F &&
    rect.max.x == 240.0F &&
    rect.max.y == 110.0F
  inspect(ok_rect, content="true")
  let t = @math.Has_Transform::get_transform_store(world).get(node).unwrap()
  // Expected center in viewport coords: (140, 80)
  // Viewport center origin (+Y up): (-260, 220)
  let ok_pos = t.translation.x == -260.0F && t.translation.y == 220.0F
  inspect(ok_pos, content="true")

  // Camera move + scale compensation.
  let ctx2 = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @math.Transform::from_xyz(100.0F, 50.0F, 0.0F),
    2.0F,
    None,
    false,
  )
  HasRes_UiContext::get_ui_context_resource(world).insert(ctx2, tick)
  ui_layout_system(world)
  let t2 = @math.Has_Transform::get_transform_store(world).get(node).unwrap()
  // (-260, 220) * 2 + (100, 50) = (-420, 490)
  let ok_pos2 = t2.translation.x == -420.0F && t2.translation.y == 490.0F
  inspect(ok_pos2, content="true")
  let ok_scale2 = t2.scale.x == 2.0F && t2.scale.y == 2.0F
  inspect(ok_scale2, content="true")
}

///|
test "ui: pointer conversion to viewport space" {
  let pos = @math.Vec2::new(20.0F, 40.0F)
  let origin = @math.Vec2::new(10.0F, 15.0F)
  let size = @math.Vec2::new(100.0F, 100.0F)
  let in_view = ui_pointer_pos_in_viewport(pos, origin, size)
  inspect(
    in_view.unwrap().x == 10.0F && in_view.unwrap().y == 25.0F,
    content="true",
  )
  let out_view = ui_pointer_pos_in_viewport(
    @math.Vec2::new(5.0F, 0.0F),
    origin,
    size,
  )
  inspect(out_view is None, content="true")
}

///|
test "ui: hidden overflow axis ignores stale scroll offset" {
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @math.Transform::identity(),
    1.0F,
    None,
    false,
  )
  HasRes_UiContext::get_ui_context_resource(world).insert(ctx, tick)
  let root = world.spawn_empty()
  Has_UiRoot::get_ui_root_store(world).insert(root, UiRoot::default(), tick)
  let panel = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    panel,
    @hierarchy.Parent::new(root),
    tick,
  )
  Has_Node::get_node_store(world).insert(
    panel,
    Node::default()
    .with_width(Val::Px(200.0F))
    .with_height(Val::Px(120.0F))
    .with_overflow(Overflow::new(OverflowAxis::Hidden, OverflowAxis::Scroll)),
    tick,
  )
  Has_ScrollPosition::get_scroll_position_store(world).insert(
    panel,
    ScrollPosition::new(180.0F, 24.0F),
    tick,
  )
  let child = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    child,
    @hierarchy.Parent::new(panel),
    tick,
  )
  Has_Node::get_node_store(world).insert(
    child,
    Node::default()
    .with_position_type(PositionType::Absolute)
    .with_left(Val::Px(0.0F))
    .with_top(Val::Px(0.0F))
    .with_width(Val::Px(100.0F))
    .with_height(Val::Px(20.0F)),
    tick,
  )
  @transform.update_children_system(world)
  ui_layout_system(world)
  let panel_rect = Has_UiLayout::get_ui_layout_store(world).get(panel).unwrap().rect
  let child_rect = Has_UiLayout::get_ui_layout_store(world).get(child).unwrap().rect
  inspect(child_rect.min.x == panel_rect.min.x, content="true")
  inspect(child_rect.min.y == panel_rect.min.y - 24.0F, content="true")
}

///|
test "ui: editable text transform stays in input content box and in front" {
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @math.Transform::identity(),
    1.0F,
    None,
    false,
  )
  HasRes_UiContext::get_ui_context_resource(world).insert(ctx, tick)
  let root = world.spawn_empty()
  Has_UiRoot::get_ui_root_store(world).insert(root, UiRoot::default(), tick)
  let editable = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    editable,
    @hierarchy.Parent::new(root),
    tick,
  )
  Has_Node::get_node_store(world).insert(
    editable,
    Node::default()
    .with_position_type(PositionType::Absolute)
    .with_left(Val::Px(120.0F))
    .with_top(Val::Px(360.0F))
    .with_width(Val::Px(420.0F))
    .with_height(Val::Px(48.0F))
    .with_padding(UiRect::all(Val::Px(8.0F))),
    tick,
  )
  let text_handle = @text.Text2dBundle::new(
    @text.Text2d::new("Editable status"),
    @text.TextFont::default().with_font_size(24.0F),
    @math.Transform::identity(),
  ).spawn()
  Has_UiText::get_ui_text_store(world).insert(
    editable,
    UiText::new(text_handle),
    tick,
  )
  @transform.update_children_system(world)
  ui_layout_system(world)
  let layout = Has_UiLayout::get_ui_layout_store(world).get(editable).unwrap().rect
  let content_rect = @math.Rect::new(
    @math.Vec2::new(layout.min.x + 8.0F, layout.min.y + 8.0F),
    @math.Vec2::new(layout.max.x - 8.0F, layout.max.y - 8.0F),
  )
  let center = content_rect.center()
  let expected_x = center.x - 400.0F
  let expected_y = 300.0F - center.y
  let t0 = @text.text_get_transform(text_handle).unwrap()
  inspect(t0.translation.x == expected_x, content="true")
  inspect(t0.translation.y == expected_y, content="true")
  let text_size = @text.text_get_layout_size(text_handle).unwrap()
  inspect(text_size.y <= 32.0F, content="true")
  ui_stack_system(world)
  let editable_transform = @math.Has_Transform::get_transform_store(world)
    .get(editable)
    .unwrap()
  let t1 = @text.text_get_transform(text_handle).unwrap()
  inspect(t1.translation.x == expected_x, content="true")
  inspect(t1.translation.y == expected_y, content="true")
  inspect(t1.translation.z > editable_transform.translation.z, content="true")
}

///|
test "ui: editable status text renders in front of editable background (z-order)" {
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @math.Transform::identity(),
    1.0F,
    None,
    false,
  )
  HasRes_UiContext::get_ui_context_resource(world).insert(ctx, tick)
  let root = world.spawn_empty()
  Has_UiRoot::get_ui_root_store(world).insert(root, UiRoot::default(), tick)
  let editable = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    editable,
    @hierarchy.Parent::new(root),
    tick,
  )
  Has_Node::get_node_store(world).insert(
    editable,
    Node::default()
    .with_position_type(PositionType::Absolute)
    .with_left(Val::Px(40.0F))
    .with_top(Val::Px(420.0F))
    .with_width(Val::Px(420.0F))
    .with_height(Val::Px(48.0F))
    .with_padding(UiRect::all(Val::Px(8.0F))),
    tick,
  )
  Has_BackgroundColor::get_background_color_store(world).insert(
    editable,
    BackgroundColor::new(@render2d.Color::new(0.12F, 0.12F, 0.16F, 1.0F)),
    tick,
  )
  let text_handle = @text.Text2dBundle::new(
    @text.Text2d::new("Editable status"),
    @text.TextFont::default().with_font_size(24.0F),
    @math.Transform::identity(),
  ).spawn()
  Has_UiText::get_ui_text_store(world).insert(
    editable,
    UiText::new(text_handle),
    tick,
  )
  @transform.update_children_system(world)
  ui_layout_system(world)
  ui_stack_system(world)
  let background_transform = @math.Has_Transform::get_transform_store(world)
    .get(editable)
    .unwrap()
  let text_transform = @text.text_get_transform(text_handle).unwrap()
  inspect(
    text_transform.translation.z > background_transform.translation.z,
    content="true",
  )
}

///|
test "ui: editable label node is laid out above input box node" {
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @math.Transform::identity(),
    1.0F,
    None,
    false,
  )
  HasRes_UiContext::get_ui_context_resource(world).insert(ctx, tick)
  let root = world.spawn_empty()
  Has_UiRoot::get_ui_root_store(world).insert(root, UiRoot::default(), tick)
  let group = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    group,
    @hierarchy.Parent::new(root),
    tick,
  )
  Has_Node::get_node_store(world).insert(
    group,
    Node::default()
    .with_position_type(PositionType::Absolute)
    .with_left(Val::Px(120.0F))
    .with_top(Val::Px(360.0F))
    .with_width(Val::Px(420.0F))
    .with_flex_direction(FlexDirection::Column)
    .with_row_gap(Val::Px(8.0F)),
    tick,
  )
  let label = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    label,
    @hierarchy.Parent::new(group),
    tick,
  )
  Has_Node::get_node_store(world).insert(
    label,
    Node::default().with_width(Val::Auto).with_height(Val::Auto),
    tick,
  )
  let editable = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    editable,
    @hierarchy.Parent::new(group),
    tick,
  )
  Has_Node::get_node_store(world).insert(
    editable,
    Node::default()
    .with_width(Val::Px(420.0F))
    .with_height(Val::Px(48.0F))
    .with_padding(UiRect::all(Val::Px(8.0F))),
    tick,
  )
  Has_ContentSize::get_content_size_store(world).insert(
    label,
    ContentSize::new(@math.Vec2::new(220.0F, 32.0F)),
    tick,
  )
  @transform.update_children_system(world)
  ui_layout_system(world)
  let label_rect = Has_UiLayout::get_ui_layout_store(world).get(label).unwrap().rect
  let editable_rect = Has_UiLayout::get_ui_layout_store(world)
    .get(editable)
    .unwrap().rect
  inspect(label_rect.max.y <= editable_rect.min.y, content="true")
  inspect(editable_rect.min.y - label_rect.max.y == 8.0F, content="true")
}

///|
test "ui: scroll panel text inherits clip rect from overflow parent" {
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @math.Transform::identity(),
    1.0F,
    None,
    false,
  )
  HasRes_UiContext::get_ui_context_resource(world).insert(ctx, tick)
  let root = world.spawn_empty()
  Has_UiRoot::get_ui_root_store(world).insert(root, UiRoot::default(), tick)
  let panel = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    panel,
    @hierarchy.Parent::new(root),
    tick,
  )
  Has_Node::get_node_store(world).insert(
    panel,
    Node::default()
    .with_position_type(PositionType::Absolute)
    .with_left(Val::Px(40.0F))
    .with_top(Val::Px(80.0F))
    .with_width(Val::Px(420.0F))
    .with_height(Val::Px(190.0F))
    .with_overflow(Overflow::new(OverflowAxis::Hidden, OverflowAxis::Scroll))
    .with_padding(UiRect::all(Val::Px(10.0F))),
    tick,
  )
  let panel_content = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    panel_content,
    @hierarchy.Parent::new(panel),
    tick,
  )
  Has_Node::get_node_store(world).insert(
    panel_content,
    Node::default()
    .with_width(Val::Px(760.0F))
    .with_height(Val::Px(420.0F))
    .with_padding(UiRect::all(Val::Px(12.0F))),
    tick,
  )
  let panel_text = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    panel_text,
    @hierarchy.Parent::new(panel_content),
    tick,
  )
  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(
        "Scrollable panel (clip + scissor test)\nUse wheel or screen reader scroll actions.\nLine 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8\nLine 9\nLine 10",
      ),
      @text.TextFont::default().with_font_size(18.0F),
      @math.Transform::identity(),
    )
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()
  Has_Node::get_node_store(world).insert(
    panel_text,
    Node::default().with_width(Val::Px(720.0F)).with_height(Val::Auto),
    tick,
  )
  Has_UiText::get_ui_text_store(world).insert(
    panel_text,
    UiText::new(handle),
    tick,
  )
  @transform.update_children_system(world)
  ui_layout_system(world)
  ui_clip_system(world)
  let panel_rect = Has_UiLayout::get_ui_layout_store(world).get(panel).unwrap().rect
  let clip_opt = @text.text_get_ui_scissor(handle)
  inspect(clip_opt is Some(_), content="true")
  let clip = clip_opt.unwrap()
  inspect(clip.min.x == panel_rect.min.x + 10.0F, content="true")
  inspect(clip.min.y == panel_rect.min.y + 10.0F, content="true")
  inspect(clip.max.x == panel_rect.max.x - 10.0F, content="true")
  inspect(clip.max.y == panel_rect.max.y - 10.0F, content="true")
}

///|
test "ui: panel text scissor stays above editable title block" {
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @math.Transform::identity(),
    1.0F,
    None,
    false,
  )
  HasRes_UiContext::get_ui_context_resource(world).insert(ctx, tick)
  let root = world.spawn_empty()
  Has_UiRoot::get_ui_root_store(world).insert(root, UiRoot::default(), tick)
  Has_Node::get_node_store(world).insert(
    root,
    Node::default()
    .with_width(Val::Px(800.0F))
    .with_height(Val::Px(600.0F))
    .with_flex_direction(FlexDirection::Column)
    .with_row_gap(Val::Px(18.0F))
    .with_padding(UiRect::all(Val::Px(24.0F))),
    tick,
  )
  let panel = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    panel,
    @hierarchy.Parent::new(root),
    tick,
  )
  Has_Node::get_node_store(world).insert(
    panel,
    Node::default()
    .with_width(Val::Px(420.0F))
    .with_height(Val::Px(190.0F))
    .with_overflow(Overflow::new(OverflowAxis::Hidden, OverflowAxis::Scroll))
    .with_padding(UiRect::all(Val::Px(10.0F))),
    tick,
  )
  let panel_content = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    panel_content,
    @hierarchy.Parent::new(panel),
    tick,
  )
  Has_Node::get_node_store(world).insert(
    panel_content,
    Node::default()
    .with_width(Val::Px(760.0F))
    .with_height(Val::Px(420.0F))
    .with_padding(UiRect::all(Val::Px(12.0F))),
    tick,
  )
  let panel_text = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    panel_text,
    @hierarchy.Parent::new(panel_content),
    tick,
  )
  let panel_handle = @text.Text2dBundle::new(
    @text.Text2d::new(
      "Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8\nLine 9\nLine 10",
    ),
    @text.TextFont::default().with_font_size(18.0F),
    @math.Transform::identity(),
  ).spawn()
  Has_Node::get_node_store(world).insert(
    panel_text,
    Node::default().with_width(Val::Px(720.0F)).with_height(Val::Auto),
    tick,
  )
  Has_UiText::get_ui_text_store(world).insert(
    panel_text,
    UiText::new(panel_handle),
    tick,
  )
  let editable_section = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    editable_section,
    @hierarchy.Parent::new(root),
    tick,
  )
  Has_Node::get_node_store(world).insert(
    editable_section,
    Node::default()
    .with_width(Val::Px(420.0F))
    .with_flex_direction(FlexDirection::Column)
    .with_row_gap(Val::Px(8.0F)),
    tick,
  )
  let editable_title = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    editable_title,
    @hierarchy.Parent::new(editable_section),
    tick,
  )
  Has_Node::get_node_store(world).insert(
    editable_title,
    Node::default().with_width(Val::Auto).with_height(Val::Px(32.0F)),
    tick,
  )
  let title_handle = @text.Text2dBundle::new(
    @text.Text2d::new("Editable status"),
    @text.TextFont::default().with_font_size(24.0F),
    @math.Transform::identity(),
  ).spawn()
  Has_UiText::get_ui_text_store(world).insert(
    editable_title,
    UiText::new(title_handle),
    tick,
  )
  @transform.update_children_system(world)
  ui_layout_system(world)
  ui_clip_system(world)
  let scissor = @text.text_get_ui_scissor(panel_handle).unwrap()
  let title_rect = Has_UiLayout::get_ui_layout_store(world)
    .get(editable_title)
    .unwrap().rect
  inspect(scissor.max.y <= title_rect.min.y, content="true")
}
