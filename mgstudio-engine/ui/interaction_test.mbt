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
test "ui: RelativeCursorPosition default reports cursor outside" {
  let relative_cursor_position = RelativeCursorPosition::default()
  inspect(relative_cursor_position.cursor_over(), content="false")
  inspect(relative_cursor_position.normalized is None, content="true")
}
