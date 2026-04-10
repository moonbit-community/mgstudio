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
test "ui: ContentSize drives auto measured size" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
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
  get_ui_context_resource(world).insert(ctx)
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot::default())
  try! world.set_by_key(
    root,
    ecs_key_node,
    Node::default()
    .with_width(Val::Percent(100.0F))
    .with_height(Val::Percent(100.0F))
    .with_align_items(AlignItems::FlexStart),
  )
  let child = world.spawn_empty()
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(child, ecs_key_node, Node::default())
  try! world.set_by_key(
    child,
    ecs_key_content_size,
    ContentSize::new(@math.Vec2::new(80.0F, 30.0F)),
  )
  ui_layout_system(world)
  let rect = try! world.get_by_key(child, ecs_key_ui_layout).unwrap().rect
  debug_inspect(
    rect.size().x == 80.0F && rect.size().y == 30.0F,
    content="true",
  )
}
