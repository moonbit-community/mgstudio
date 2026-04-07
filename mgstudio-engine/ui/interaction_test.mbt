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
test "ui: interaction updates component state" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    Some(@math.Vec2::new(60.0F, 60.0F)),
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  let e = world.spawn_empty()
  try! world.set_by_key(e, ecs_key_button, Button::default())
  try! world.set_by_key(
    e,
    ecs_key_ui_layout,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(40.0F, 50.0F),
        @math.Vec2::new(240.0F, 110.0F),
      ),
    ),
  )
  ui_stack_system(world)
  ui_interaction_system(world)
  let s0 = try! world.get_by_key(e, ecs_key_interaction).unwrap()
  let cursor0 = try! world
    .get_by_key(e, ecs_key_relative_cursor_position)
    .unwrap()
  inspect(s0 == Interaction::Hovered, content="true")
  inspect(cursor0.cursor_over(), content="true")

  // Pressed.
  let ctx2 = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    Some(@math.Vec2::new(60.0F, 60.0F)),
    true,
  )
  get_ui_context_resource(world).insert(ctx2)
  ui_stack_system(world)
  ui_interaction_system(world)
  let s1 = try! world.get_by_key(e, ecs_key_interaction).unwrap()
  let cursor1 = try! world
    .get_by_key(e, ecs_key_relative_cursor_position)
    .unwrap()
  inspect(s1 == Interaction::Pressed, content="true")
  inspect(cursor1.cursor_over(), content="true")

  // Outside.
  let ctx3 = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    Some(@math.Vec2::new(1.0F, 1.0F)),
    false,
  )
  get_ui_context_resource(world).insert(ctx3)
  ui_stack_system(world)
  ui_interaction_system(world)
  let s2 = try! world.get_by_key(e, ecs_key_interaction).unwrap()
  let cursor2 = try! world
    .get_by_key(e, ecs_key_relative_cursor_position)
    .unwrap()
  inspect(s2 == Interaction::None, content="true")
  inspect(cursor2.cursor_over(), content="false")
  inspect(cursor2.normalized is None, content="true")
}

///|
test "ui: pointer viewport conversion keeps top-left y direction" {
  let pointer = @math.Vec2::new(250.0F, 460.0F)
  let viewport_origin = @math.Vec2::new(200.0F, 100.0F)
  let viewport_size = @math.Vec2::new(400.0F, 500.0F)
  let converted = ui_pointer_pos_in_viewport(
    pointer, viewport_origin, viewport_size,
  )
  let point = converted.unwrap()
  inspect(point.x == 50.0F, content="true")
  inspect(point.y == 360.0F, content="true")
}

///|
test "ui: RelativeCursorPosition default reports cursor outside" {
  let relative_cursor_position = RelativeCursorPosition::default()
  inspect(relative_cursor_position.cursor_over(), content="false")
  inspect(relative_cursor_position.normalized is None, content="true")
}

///|
test "ui: interaction hit test respects node transform rotation" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    Some(@math.Vec2::new(140.0F, 170.0F)),
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  let e = world.spawn_empty()
  try! world.set_by_key(e, ecs_key_button, Button::default())
  let rect = @math.Rect::new(
    @math.Vec2::new(40.0F, 50.0F),
    @math.Vec2::new(240.0F, 110.0F),
  )
  try! world.set_by_key(e, ecs_key_ui_layout, UiLayout::new(rect))
  try! world.set_by_key(
    e,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-260.0F, 220.0F),
      1.5707964F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  ui_stack_system(world)
  ui_interaction_system(world)
  let interaction = try! world.get_by_key(e, ecs_key_interaction).unwrap()
  let cursor = try! world
    .get_by_key(e, ecs_key_relative_cursor_position)
    .unwrap()
  inspect(interaction == Interaction::Hovered, content="true")
  inspect(cursor.cursor_over(), content="true")
}

///|
test "ui: interaction keeps top and bottom rows distinct" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  let ctx_top = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    Some(@math.Vec2::new(400.0F, 120.0F)),
    false,
  )
  get_ui_context_resource(world).insert(ctx_top)
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot::default())
  try! world.set_by_key(
    root,
    ecs_key_node,
    Node::default()
    .with_width(Val::Percent(100.0F))
    .with_height(Val::Percent(100.0F))
    .with_display(Display::Grid)
    .with_grid_template_columns([
      RepeatedGridTrack::new(GridTrackRepetition::Count(1), [
        GridTrack::Fr(1.0F),
      ]),
    ])
    .with_grid_template_rows([
      RepeatedGridTrack::new(GridTrackRepetition::Count(2), [
        GridTrack::Fr(1.0F),
      ]),
    ]),
  )
  let top = world.spawn_empty()
  try! world.set_by_key(
    top,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(top, ecs_key_button, Button::default())
  try! world.set_by_key(
    top,
    ecs_key_node,
    Node::default()
    .with_width(Val::Percent(100.0F))
    .with_height(Val::Percent(100.0F)),
  )
  let bottom = world.spawn_empty()
  try! world.set_by_key(
    bottom,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(bottom, ecs_key_button, Button::default())
  try! world.set_by_key(
    bottom,
    ecs_key_node,
    Node::default()
    .with_width(Val::Percent(100.0F))
    .with_height(Val::Percent(100.0F)),
  )
  ui_layout_system(world)
  ui_stack_system(world)
  ui_interaction_system(world)
  let top_interaction = try! world.get_by_key(top, ecs_key_interaction).unwrap()
  let bottom_interaction = try! world
    .get_by_key(bottom, ecs_key_interaction)
    .unwrap()
  inspect(top_interaction == Interaction::Hovered, content="true")
  inspect(bottom_interaction == Interaction::None, content="true")

  let ctx_bottom = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(800.0F, 600.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    Some(@math.Vec2::new(400.0F, 480.0F)),
    false,
  )
  get_ui_context_resource(world).insert(ctx_bottom)
  ui_layout_system(world)
  ui_stack_system(world)
  ui_interaction_system(world)
  let top_interaction2 = try! world
    .get_by_key(top, ecs_key_interaction)
    .unwrap()
  let bottom_interaction2 = try! world
    .get_by_key(bottom, ecs_key_interaction)
    .unwrap()
  inspect(top_interaction2 == Interaction::None, content="true")
  inspect(bottom_interaction2 == Interaction::Hovered, content="true")
}
