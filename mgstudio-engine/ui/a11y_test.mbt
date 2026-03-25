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
test "ui: a11y derives button label from text children" {
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
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  let btn = world.spawn_empty()
  try! world.set_by_key(btn, ecs_key_button, Button::default())
  try! world.set_by_key(
    btn,
    ecs_key_ui_layout,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(10.0F, 10.0F),
        @math.Vec2::new(110.0F, 50.0F),
      ),
    ),
  )
  let child = world.spawn_empty()
  try! world.set_by_key(child, @text.ecs_key_text, @text.Text::new("OK"))
  world.set_by_key(child, @text.ecs_key_text_font, @text.TextFont::default())
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(btn),
  )
  try! world.set_by_key(
    btn,
    @hierarchy.ecs_key_children,
    @hierarchy.Children::new([child]),
  )
  ui_stack_system(world)
  let update = ui_build_a11y_tree_update(world)
  let target_id = @a11y.node_id_for_entity(btn)
  let mut found = false
  for nu in update.nodes() {
    if nu.id() == target_id {
      found = true
      let node = nu.node()
      assert_eq(node.role(), @moon_accesskit.Role::Button)
      assert_eq(node.label(), Some("OK"))
      assert_true(node.supports_action(@moon_accesskit.Action::Click))
    }
  }
  assert_true(found)
}

///|
test "ui: a11y label widget sets value from self text" {
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
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  let e = world.spawn_empty()
  try! world.set_by_key(e, ecs_key_label, Label::default())
  try! world.set_by_key(
    e,
    ecs_key_ui_layout,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(20.0F, 30.0F),
        @math.Vec2::new(220.0F, 60.0F),
      ),
    ),
  )
  try! world.set_by_key(e, @text.ecs_key_text, @text.Text::new("Hello"))
  try! world.set_by_key(e, @text.ecs_key_text_font, @text.TextFont::default())
  ui_stack_system(world)
  let update = ui_build_a11y_tree_update(world)
  let target_id = @a11y.node_id_for_entity(e)
  let mut found = false
  for nu in update.nodes() {
    if nu.id() == target_id {
      found = true
      let node = nu.node()
      assert_eq(node.role(), @moon_accesskit.Role::Label)
      assert_eq(node.value(), Some("Hello"))
    }
  }
  assert_true(found)
}

///|
test "ui: a11y sets hidden when view visibility is false" {
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
    None,
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
        @math.Vec2::new(10.0F, 10.0F),
        @math.Vec2::new(30.0F, 30.0F),
      ),
    ),
  )
  try! world.set_by_key(
    e,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  ui_stack_system(world)
  let update = ui_build_a11y_tree_update(world)
  let target_id = @a11y.node_id_for_entity(e)
  let mut found = false
  for nu in update.nodes() {
    if nu.id() == target_id {
      found = true
      assert_true(nu.node().is_hidden())
    }
  }
  assert_true(found)
}

///|
test "ui: a11y sets clips_children when calculated clip exists" {
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
    None,
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
        @math.Vec2::new(10.0F, 10.0F),
        @math.Vec2::new(100.0F, 100.0F),
      ),
    ),
  )
  try! world.set_by_key(
    e,
    ecs_key_calculated_clip,
    CalculatedClip::new(
      @math.Rect::new(
        @math.Vec2::new(10.0F, 10.0F),
        @math.Vec2::new(50.0F, 50.0F),
      ),
    ),
  )
  ui_stack_system(world)
  let update = ui_build_a11y_tree_update(world)
  let target_id = @a11y.node_id_for_entity(e)
  let mut found = false
  for nu in update.nodes() {
    if nu.id() == target_id {
      found = true
      assert_true(nu.node().clips_children())
    }
  }
  assert_true(found)
}

///|
test "ui: a11y label widget keeps empty value" {
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
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  let e = world.spawn_empty()
  try! world.set_by_key(e, ecs_key_label, Label::default())
  try! world.set_by_key(
    e,
    ecs_key_ui_layout,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(20.0F, 30.0F),
        @math.Vec2::new(220.0F, 60.0F),
      ),
    ),
  )
  ui_stack_system(world)
  let update = ui_build_a11y_tree_update(world)
  let target_id = @a11y.node_id_for_entity(e)
  let mut found = false
  for nu in update.nodes() {
    if nu.id() == target_id {
      found = true
      assert_eq(nu.node().role(), @moon_accesskit.Role::Label)
      assert_eq(nu.node().value(), Some(""))
    }
  }
  assert_true(found)
}

///|
test "ui: a11y focus follows A11yState instead of hover state" {
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
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  @a11y.get_a11y_state_resource(world).insert(@a11y.A11yState::default())
  let back = world.spawn_empty()
  try! world.set_by_key(back, ecs_key_button, Button::default())
  try! world.set_by_key(
    back,
    ecs_key_ui_layout,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(10.0F, 10.0F),
        @math.Vec2::new(120.0F, 60.0F),
      ),
    ),
  )
  try! world.set_by_key(back, ecs_key_interaction, Interaction::Hovered)
  let front = world.spawn_empty()
  try! world.set_by_key(front, ecs_key_button, Button::default())
  try! world.set_by_key(
    front,
    ecs_key_ui_layout,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(20.0F, 20.0F),
        @math.Vec2::new(130.0F, 70.0F),
      ),
    ),
  )
  try! world.set_by_key(front, ecs_key_interaction, Interaction::Pressed)
  try! world.set_by_key(
    back,
    @hierarchy.ecs_key_children,
    @hierarchy.Children::new([front]),
  )
  try! world.set_by_key(
    front,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(back),
  )
  let a11y_state_res = @a11y.get_a11y_state_resource(world)
  let a11y_state = Ref::new(a11y_state_res.get().unwrap())
  @a11y.A11yState::set_focused_node(a11y_state, @a11y.node_id_for_entity(back))
  a11y_state_res.insert(a11y_state.val)
  ui_stack_system(world)
  let update = ui_build_a11y_tree_update(world)
  assert_eq(update.focus(), @a11y.node_id_for_entity(back))
}

///|
test "ui: editable label node is exported as text input with SetValue" {
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
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx)
  @a11y.get_a11y_state_resource(world).insert(@a11y.A11yState::default())
  let editable = world.spawn_empty()
  try! world.set_by_key(editable, ecs_key_label, Label::default())
  try! world.set_by_key(
    editable,
    ecs_key_accessibility_label,
    AccessibilityLabel::new("Status input"),
  )
  try! world.set_by_key(
    editable,
    ecs_key_ui_layout,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(20.0F, 40.0F),
        @math.Vec2::new(260.0F, 90.0F),
      ),
    ),
  )
  try! world.set_by_key(
    editable,
    @text.ecs_key_text,
    @text.Text::new("Editable status"),
  )
  world.set_by_key(editable, @text.ecs_key_text_font, @text.TextFont::default())
  ui_stack_system(world)
  let update = ui_build_a11y_tree_update(world)
  let node_id = @a11y.node_id_for_entity(editable)
  let mut found = false
  for nu in update.nodes() {
    if nu.id() == node_id {
      found = true
      let node = nu.node()
      assert_eq(node.role(), @moon_accesskit.Role::TextInput)
      assert_eq(node.label(), Some("Status input"))
      assert_eq(node.value(), Some("Editable status"))
      assert_true(node.supports_action(@moon_accesskit.Action::SetValue))
      assert_true(node.supports_action(@moon_accesskit.Action::Focus))
    }
  }
  assert_true(found)
}
