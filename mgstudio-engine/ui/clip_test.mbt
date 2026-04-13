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
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)

  // Seed UiContext (camera_entity must be present for ui_clip_system).
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
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot::default())
  let container = world.spawn_empty()
  try! world.set_by_key(
    container,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
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
  try! world.set_by_key(container, ecs_key_node, container_node)
  let child = world.spawn_empty()
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(container),
  )
  try! world.set_by_key(child, ecs_key_node, Node::default())

  // Build Children from Parent before clip.

  // Seed UiLayout so the clip system doesn't depend on layout implementation.
  try! world.set_by_key(
    container,
    ecs_key_ui_layout,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(10.0F, 20.0F),
        @math.Vec2::new(110.0F, 120.0F),
      ),
    ),
  )
  try! world.set_by_key(
    child,
    ecs_key_ui_layout,
    UiLayout::new(
      @math.Rect::new(@math.Vec2::new(0.0F, 0.0F), @math.Vec2::new(1.0F, 1.0F)),
    ),
  )
  ui_clip_system(world)
  let scissor = try! world
    .get_by_key(child, @sprite.ecs_key_scissor_rect)
    .unwrap().rect
  // BorderBox: (10,20)-(110,120)
  // ContentBox inset: border(5)+padding(10)=15 => (25,35)-(95,105)
  // Margin inflate 2 => (23,33)-(97,107)
  let ok = scissor.min.x == 23.0F &&
    scissor.min.y == 33.0F &&
    scissor.max.x == 97.0F &&
    scissor.max.y == 107.0F
  debug_inspect(ok, content="true")
}

///|
test "ui: overflow Visible disables clipping per-axis" {
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
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot::default())
  let container = world.spawn_empty()
  try! world.set_by_key(
    container,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    container,
    ecs_key_node,
    Node::default().with_overflow(
      Overflow::new(OverflowAxis::Visible, OverflowAxis::Hidden),
    ),
  )
  let child = world.spawn_empty()
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(container),
  )
  try! world.set_by_key(child, ecs_key_node, Node::default())
  try! world.set_by_key(
    container,
    ecs_key_ui_layout,
    UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(10.0F, 20.0F),
        @math.Vec2::new(110.0F, 120.0F),
      ),
    ),
  )
  try! world.set_by_key(
    child,
    ecs_key_ui_layout,
    UiLayout::new(
      @math.Rect::new(@math.Vec2::new(0.0F, 0.0F), @math.Vec2::new(1.0F, 1.0F)),
    ),
  )
  ui_clip_system(world)
  let scissor = try! world
    .get_by_key(child, @sprite.ecs_key_scissor_rect)
    .unwrap().rect
  // X should not be clipped by container; Y should be.
  let ok_x = scissor.min.x == 0.0F && scissor.max.x == 800.0F
  let ok_y = scissor.min.y == 20.0F && scissor.max.y == 120.0F
  debug_inspect(ok_x && ok_y, content="true")
}
