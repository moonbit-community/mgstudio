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
  let btn = world.spawn_empty()
  Has_Button::get_button_store(world).insert(btn, Button::default(), tick)
  Has_UiLayout::get_ui_layout_store(world).insert(
    btn,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(10.0F, 10.0F),
        @math.Vec2::new(110.0F, 50.0F),
      ),
    ),
    tick,
  )
  let child = world.spawn_empty()
  let handle = @text.Text2dBundle::new(
    @text.Text2d::new("OK"),
    @text.TextFont::default(),
    @math.Transform::identity(),
  ).spawn()
  Has_UiText::get_ui_text_store(world).insert(child, UiText::new(handle), tick)
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    child,
    @hierarchy.Parent::new(btn),
    tick,
  )
  @hierarchy.Has_Children::get_children_store(world).insert(
    btn,
    @hierarchy.Children::new([child]),
    tick,
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
  let e = world.spawn_empty()
  Has_Label::get_label_store(world).insert(e, Label::default(), tick)
  Has_UiLayout::get_ui_layout_store(world).insert(
    e,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(20.0F, 30.0F),
        @math.Vec2::new(220.0F, 60.0F),
      ),
    ),
    tick,
  )
  let handle = @text.Text2dBundle::new(
    @text.Text2d::new("Hello"),
    @text.TextFont::default(),
    @math.Transform::identity(),
  ).spawn()
  Has_UiText::get_ui_text_store(world).insert(e, UiText::new(handle), tick)
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
  let e = world.spawn_empty()
  Has_Button::get_button_store(world).insert(e, Button::default(), tick)
  Has_UiLayout::get_ui_layout_store(world).insert(
    e,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(10.0F, 10.0F),
        @math.Vec2::new(30.0F, 30.0F),
      ),
    ),
    tick,
  )
  @visibility.Has_ViewVisibility::get_view_visibility_store(world).insert(
    e,
    @visibility.ViewVisibility::new(false),
    tick,
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
  let e = world.spawn_empty()
  Has_Button::get_button_store(world).insert(e, Button::default(), tick)
  Has_UiLayout::get_ui_layout_store(world).insert(
    e,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(10.0F, 10.0F),
        @math.Vec2::new(100.0F, 100.0F),
      ),
    ),
    tick,
  )
  Has_CalculatedClip::get_calculated_clip_store(world).insert(
    e,
    CalculatedClip::new(
      @math.Rect::new(
        @math.Vec2::new(10.0F, 10.0F),
        @math.Vec2::new(50.0F, 50.0F),
      ),
    ),
    tick,
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
  let e = world.spawn_empty()
  Has_Label::get_label_store(world).insert(e, Label::default(), tick)
  Has_UiLayout::get_ui_layout_store(world).insert(
    e,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(20.0F, 30.0F),
        @math.Vec2::new(220.0F, 60.0F),
      ),
    ),
    tick,
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
  @a11y.HasRes_A11yState::get_a11y_state_resource(world).insert(
    @a11y.A11yState::default(),
    tick,
  )
  let back = world.spawn_empty()
  Has_Button::get_button_store(world).insert(back, Button::default(), tick)
  Has_UiLayout::get_ui_layout_store(world).insert(
    back,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(10.0F, 10.0F),
        @math.Vec2::new(120.0F, 60.0F),
      ),
    ),
    tick,
  )
  Has_Interaction::get_interaction_store(world).insert(
    back,
    Interaction::Hovered,
    tick,
  )
  let front = world.spawn_empty()
  Has_Button::get_button_store(world).insert(front, Button::default(), tick)
  Has_UiLayout::get_ui_layout_store(world).insert(
    front,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(20.0F, 20.0F),
        @math.Vec2::new(130.0F, 70.0F),
      ),
    ),
    tick,
  )
  Has_Interaction::get_interaction_store(world).insert(
    front,
    Interaction::Pressed,
    tick,
  )
  @hierarchy.Has_Children::get_children_store(world).insert(
    back,
    @hierarchy.Children::new([front]),
    tick,
  )
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    front,
    @hierarchy.Parent::new(back),
    tick,
  )
  let a11y_state = @a11y.HasRes_A11yState::get_a11y_state_resource(world)
    .get_ref_mut(tick)
    .unwrap()
  @a11y.A11yState::set_focused_node(a11y_state, @a11y.node_id_for_entity(back))
  ui_stack_system(world)
  let update = ui_build_a11y_tree_update(world)
  assert_eq(update.focus(), @a11y.node_id_for_entity(back))
}

///|
test "ui: editable label node is exported as text input with SetValue" {
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
  @a11y.HasRes_A11yState::get_a11y_state_resource(world).insert(
    @a11y.A11yState::default(),
    tick,
  )
  let editable = world.spawn_empty()
  Has_Label::get_label_store(world).insert(editable, Label::default(), tick)
  Has_AccessibilityLabel::get_accessibility_label_store(world).insert(
    editable,
    AccessibilityLabel::new("Status input"),
    tick,
  )
  Has_UiLayout::get_ui_layout_store(world).insert(
    editable,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(20.0F, 40.0F),
        @math.Vec2::new(260.0F, 90.0F),
      ),
    ),
    tick,
  )
  let handle = @text.Text2dBundle::new(
    @text.Text2d::new("Editable status"),
    @text.TextFont::default(),
    @math.Transform::identity(),
  ).spawn()
  Has_UiText::get_ui_text_store(world).insert(
    editable,
    UiText::new(handle),
    tick,
  )
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
