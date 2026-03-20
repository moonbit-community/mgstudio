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
test "ui: measure uses intrinsic aspect ratio when only width is specified" {
  let world = @ecs.World::new()
  let tick = world.increment_change_tick()
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(300.0F, 200.0F),
    Some(@core.Entity::new(0, 0)),
    @transform.Transform::identity(),
    1.0F,
    None,
    false,
  )
  get_ui_context_resource(world).insert(ctx, tick)
  let root = world.spawn_empty()
  get_ui_root_store(world).insert(root, UiRoot::default(), tick)
  get_node_store(world).insert(
    root,
    Node::default()
    .with_width(Val::Percent(100.0F))
    .with_height(Val::Percent(100.0F))
    .with_align_items(AlignItems::FlexStart),
    tick,
  )
  let child = world.spawn_empty()
  @hierarchy.get_parent_store(world).insert(
    child,
    @hierarchy.Parent::new(root),
    tick,
  )
  get_node_store(world).insert(
    child,
    Node::default().with_width(Val::Px(200.0F)),
    tick,
  )
  // Intrinsic content size: 100x50 -> aspect ratio 2.0.
  get_content_size_store(world).insert(
    child,
    ContentSize::new(@math.Vec2::new(100.0F, 50.0F)),
    tick,
  )
  ui_layout_system(world)
  let rect = get_ui_layout_store(world).get(child).unwrap().rect
  inspect(rect.size().x == 200.0F && rect.size().y == 100.0F, content="true")
}
