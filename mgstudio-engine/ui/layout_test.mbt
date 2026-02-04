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
  inspect(in_view.unwrap().x == 10.0F && in_view.unwrap().y == 25.0F, content="true")
  let out_view = ui_pointer_pos_in_viewport(@math.Vec2::new(5.0F, 0.0F), origin, size)
  inspect(out_view is None, content="true")
}
