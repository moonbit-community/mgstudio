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
test "ui: grid template rows/columns affect child layout (basic px tracks)" {
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)

  // Seed UiContext to avoid any host texture calls in tests.
  let ctx = UiContext::new(
    @asset.Handle::new(1),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(200.0F, 100.0F),
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
    .with_display(Display::Grid)
    .with_grid_template_columns([
      RepeatedGridTrack::new(GridTrackRepetition::Count(1), [
        GridTrack::Px(100.0F),
        GridTrack::Px(100.0F),
      ]),
    ])
    .with_grid_template_rows([
      RepeatedGridTrack::new(GridTrackRepetition::Count(1), [
        GridTrack::Px(50.0F),
        GridTrack::Px(50.0F),
      ]),
    ]),
    tick,
  )
  let a = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    a,
    @hierarchy.Parent::new(root),
    tick,
  )
  Has_Node::get_node_store(world).insert(a, Node::default(), tick)
  let b = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    b,
    @hierarchy.Parent::new(root),
    tick,
  )
  Has_Node::get_node_store(world).insert(b, Node::default(), tick)

  // Build Children from Parent before layout.
  @transform.update_children_system(world)
  ui_layout_system(world)
  let layout_store = Has_UiLayout::get_ui_layout_store(world)
  let ra = layout_store.get(a).unwrap().rect
  let rb = layout_store.get(b).unwrap().rect
  inspect(ra.min.x == 0.0F, content="true")
  inspect(ra.min.y == 0.0F, content="true")
  inspect(ra.max.x == 100.0F, content="true")
  inspect(ra.max.y == 50.0F, content="true")
  inspect(rb.min.x == 100.0F, content="true")
  inspect(rb.min.y == 0.0F, content="true")
  inspect(rb.max.x == 200.0F, content="true")
  inspect(rb.max.y == 50.0F, content="true")
}
