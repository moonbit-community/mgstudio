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
fn ui_a11y_test_setup_context(world : @ecs.World) -> Unit {
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
}

///|
fn ui_a11y_test_read_node(
  world : @ecs.World,
  entity : @core.Entity,
) -> @moon_accesskit.Node {
  let accessibility = match
    (try! world.get_by_key(entity, @a11y.ecs_key_accessibility_node)) {
    Some(value) => value
    None => abort("missing AccessibilityNode")
  }
  accessibility.node()
}

///|
test "ui: a11y button role/label/actions are synced into AccessibilityNode" {
  let world = @ecs.World::new()
  ui_a11y_test_setup_context(world)

  let button = world.spawn_empty()
  try! world.set_by_key(button, ecs_key_button, Button::default())
  try! world.set_by_key(
    button,
    ecs_key_ui_layout,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(10.0F, 10.0F),
        @math.Vec2::new(110.0F, 50.0F),
      ),
    ),
  )

  let label = world.spawn_empty()
  try! world.set_by_key(label, @text.ecs_key_text, @text.Text::new("OK"))
  try! world.set_by_key(
    label,
    @text.ecs_key_text_font,
    @text.TextFont::default(),
  )
  try! world.set_by_key(
    label,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(button),
  )
  try! world.set_by_key(
    button,
    @hierarchy.ecs_key_children,
    @hierarchy.Children::new([label]),
  )

  ui_stack_system(world)
  ui_a11y_update_system(world)
  let node = ui_a11y_test_read_node(world, button)
  assert_eq(node.role(), @moon_accesskit.Role::Button)
  debug_inspect(node.label() == Some("OK"), content="true")
  assert_true(node.supports_action(@moon_accesskit.Action::Click))
}

///|
test "ui: a11y label role/value are synced into AccessibilityNode" {
  let world = @ecs.World::new()
  ui_a11y_test_setup_context(world)

  let entity = world.spawn_empty()
  try! world.set_by_key(entity, ecs_key_label, Label::default())
  try! world.set_by_key(
    entity,
    ecs_key_ui_layout,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(20.0F, 30.0F),
        @math.Vec2::new(220.0F, 60.0F),
      ),
    ),
  )
  try! world.set_by_key(entity, @text.ecs_key_text, @text.Text::new("Hello"))
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_font,
    @text.TextFont::default(),
  )

  ui_stack_system(world)
  ui_a11y_update_system(world)
  let node = ui_a11y_test_read_node(world, entity)
  assert_eq(node.role(), @moon_accesskit.Role::Label)
  debug_inspect(node.value() == Some("Hello"), content="true")
}

///|
test "ui: a11y visibility and clip metadata are synced into AccessibilityNode" {
  let world = @ecs.World::new()
  ui_a11y_test_setup_context(world)

  let entity = world.spawn_empty()
  try! world.set_by_key(entity, ecs_key_button, Button::default())
  try! world.set_by_key(
    entity,
    ecs_key_ui_layout,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(10.0F, 10.0F),
        @math.Vec2::new(100.0F, 100.0F),
      ),
    ),
  )
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  try! world.set_by_key(
    entity,
    ecs_key_calculated_clip,
    CalculatedClip::new(
      @math.Rect::new(
        @math.Vec2::new(10.0F, 10.0F),
        @math.Vec2::new(50.0F, 50.0F),
      ),
    ),
  )

  ui_stack_system(world)
  ui_a11y_update_system(world)
  let node = ui_a11y_test_read_node(world, entity)
  assert_true(node.is_hidden())
  assert_true(node.clips_children())
}

///|
test "ui: interaction state observers update AccessibilityNode like Bevy" {
  let app = ui_plugin(@app.App::new(@ecs.World::new()))
  let world = app.world()

  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @a11y.ecs_key_accessibility_node,
    @a11y.AccessibilityNode::new(
      @moon_accesskit.Node::new(@moon_accesskit.Role::Button),
    ),
  )

  try! world.set_by_key(
    entity,
    ecs_key_interaction_disabled,
    InteractionDisabled::default(),
  )
  assert_true(ui_a11y_test_read_node(world, entity).is_disabled())

  ignore(try! world.remove_by_key(entity, ecs_key_interaction_disabled))
  assert_false(ui_a11y_test_read_node(world, entity).is_disabled())

  try! world.set_by_key(entity, ecs_key_checked, Checked::default())
  debug_inspect(
    ui_a11y_test_read_node(world, entity).toggled()
    is Some(@moon_accesskit.Toggled::True),
    content="true",
  )

  ignore(try! world.remove_by_key(entity, ecs_key_checked))
  debug_inspect(
    ui_a11y_test_read_node(world, entity).toggled()
    is Some(@moon_accesskit.Toggled::False),
    content="true",
  )
}

///|
test "ui: a11y focus in tree update follows InputFocus resource" {
  let world = @ecs.World::new()
  ui_a11y_test_setup_context(world)
  world.insert_resource(
    @input_focus.InputFocus::resource(),
    @input_focus.InputFocus::default(),
  )

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

  let focus_ref = try! world.get_resource_mut(
    @input_focus.InputFocus::resource(),
  )
  match focus_ref {
    Some(value) => {
      value.set_changed()
      value.peek().set(back)
    }
    None => abort("missing InputFocus resource")
  }

  ui_stack_system(world)
  let update = ui_build_a11y_tree_update(world)
  assert_eq(update.focus(), @a11y.node_id_for_entity(back))
}

///|
test "ui: editable label exports text input role and SetValue action" {
  let world = @ecs.World::new()
  ui_a11y_test_setup_context(world)

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
  try! world.set_by_key(
    editable,
    @text.ecs_key_text_font,
    @text.TextFont::default(),
  )

  ui_stack_system(world)
  ui_a11y_update_system(world)
  let node = ui_a11y_test_read_node(world, editable)
  assert_eq(node.role(), @moon_accesskit.Role::TextInput)
  debug_inspect(node.label() == Some("Status input"), content="true")
  debug_inspect(node.value() == Some("Editable status"), content="true")
  assert_true(node.supports_action(@moon_accesskit.Action::SetValue))
  assert_true(node.supports_action(@moon_accesskit.Action::Focus))
}
