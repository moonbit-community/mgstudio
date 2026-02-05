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
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(300.0F, 200.0F),
    Some(@core.Entity::new(0, 0)),
    @math.Transform::identity(),
    1.0F,
    None,
    false,
  )
  HasRes_UiContext::get_ui_context_resource(world).insert(ctx, tick)
  let root = world.spawn_empty()
  Has_UiRoot::get_ui_root_store(world).insert(root, UiRoot::default(), tick)
  Has_Node::get_node_store(world).insert(
    root,
    Node::default()
    .with_width(Val::Percent(100.0F))
    .with_height(Val::Percent(100.0F))
    .with_align_items(AlignItems::FlexStart),
    tick,
  )
  let child = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    child,
    @hierarchy.Parent::new(root),
    tick,
  )
  Has_Node::get_node_store(world).insert(child, Node::default(), tick)
  Has_ContentSize::get_content_size_store(world).insert(
    child,
    ContentSize::new(@math.Vec2::new(80.0F, 30.0F)),
    tick,
  )
  @transform.update_children_system(world)
  ui_layout_system(world)
  let rect = Has_UiLayout::get_ui_layout_store(world).get(child).unwrap().rect
  inspect(rect.size().x == 80.0F && rect.size().y == 30.0F, content="true")
}
