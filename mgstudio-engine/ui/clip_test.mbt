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
test "ui: clip respects overflow_clip_margin visual_box and margin" {
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)

  // Seed UiContext (camera_entity must be present for ui_clip_system).
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
  let container = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    container,
    @hierarchy.Parent::new(root),
    tick,
  )
  let container_node = Node::default()
    .with_width(Val::Px(100.0F))
    .with_height(Val::Px(100.0F))
    .with_overflow(Overflow::new(OverflowAxis::Hidden, OverflowAxis::Hidden))
    .with_border(
      UiRect::new(Val::Px(5.0F), Val::Px(5.0F), Val::Px(5.0F), Val::Px(5.0F)),
    )
    .with_padding(
      UiRect::new(
        Val::Px(10.0F),
        Val::Px(10.0F),
        Val::Px(10.0F),
        Val::Px(10.0F),
      ),
    )
    .with_overflow_clip_margin(
      OverflowClipMargin::content_box().with_margin(2.0F),
    )
  Has_Node::get_node_store(world).insert(container, container_node, tick)
  let child = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    child,
    @hierarchy.Parent::new(container),
    tick,
  )
  Has_Node::get_node_store(world).insert(child, Node::default(), tick)

  // Build Children from Parent before clip.
  @transform.update_children_system(world)

  // Seed UiLayout so the clip system doesn't depend on layout implementation.
  Has_UiLayout::get_ui_layout_store(world).insert(
    container,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(10.0F, 20.0F),
        @math.Vec2::new(110.0F, 120.0F),
      ),
    ),
    tick,
  )
  Has_UiLayout::get_ui_layout_store(world).insert(
    child,
    UiLayout::new(
      @math.Rect::new(@math.Vec2::new(0.0F, 0.0F), @math.Vec2::new(1.0F, 1.0F)),
    ),
    tick,
  )
  ui_clip_system(world)
  let scissor_store = @render2d.Has_ScissorRect::get_scissor_rect_store(world)
  let scissor = scissor_store.get(child).unwrap().rect
  // BorderBox: (10,20)-(110,120)
  // ContentBox inset: border(5)+padding(10)=15 => (25,35)-(95,105)
  // Margin inflate 2 => (23,33)-(97,107)
  let ok = scissor.min.x == 23.0F &&
    scissor.min.y == 33.0F &&
    scissor.max.x == 97.0F &&
    scissor.max.y == 107.0F
  inspect(ok, content="true")
}

///|
test "ui: overflow Visible disables clipping per-axis" {
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
  let container = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    container,
    @hierarchy.Parent::new(root),
    tick,
  )
  Has_Node::get_node_store(world).insert(
    container,
    Node::default().with_overflow(
      Overflow::new(OverflowAxis::Visible, OverflowAxis::Hidden),
    ),
    tick,
  )
  let child = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    child,
    @hierarchy.Parent::new(container),
    tick,
  )
  Has_Node::get_node_store(world).insert(child, Node::default(), tick)
  @transform.update_children_system(world)
  Has_UiLayout::get_ui_layout_store(world).insert(
    container,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(10.0F, 20.0F),
        @math.Vec2::new(110.0F, 120.0F),
      ),
    ),
    tick,
  )
  Has_UiLayout::get_ui_layout_store(world).insert(
    child,
    UiLayout::new(
      @math.Rect::new(@math.Vec2::new(0.0F, 0.0F), @math.Vec2::new(1.0F, 1.0F)),
    ),
    tick,
  )
  ui_clip_system(world)
  let scissor_store = @render2d.Has_ScissorRect::get_scissor_rect_store(world)
  let scissor = scissor_store.get(child).unwrap().rect
  // X should not be clipped by container; Y should be.
  let ok_x = scissor.min.x == 0.0F && scissor.max.x == 800.0F
  let ok_y = scissor.min.y == 20.0F && scissor.max.y == 120.0F
  inspect(ok_x && ok_y, content="true")
}
