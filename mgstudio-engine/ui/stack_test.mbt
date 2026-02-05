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
test "ui: ui_stack_system orders nodes back-to-front (stable for siblings)" {
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  fn layout_dummy() -> UiLayout {
    UiLayout::new(
      @math.Rect::new(@math.Vec2::new(0.0F, 0.0F), @math.Vec2::new(1.0F, 1.0F)),
    )
  }

  let global_root = world.spawn_empty()
  Has_UiLayout::get_ui_layout_store(world).insert(
    global_root,
    layout_dummy(),
    tick,
  )
  Has_GlobalZIndex::get_global_z_index_store(world).insert(
    global_root,
    GlobalZIndex::new(-1),
    tick,
  )
  let root = world.spawn_empty()
  Has_UiLayout::get_ui_layout_store(world).insert(root, layout_dummy(), tick)
  let child_b = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    child_b,
    @hierarchy.Parent::new(root),
    tick,
  )
  Has_UiLayout::get_ui_layout_store(world).insert(child_b, layout_dummy(), tick)
  Has_ZIndex::get_z_index_store(world).insert(child_b, ZIndex::new(0), tick)
  let child_c = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    child_c,
    @hierarchy.Parent::new(root),
    tick,
  )
  Has_UiLayout::get_ui_layout_store(world).insert(child_c, layout_dummy(), tick)
  // Same z as child_b: should preserve insertion order (b before c).
  Has_ZIndex::get_z_index_store(world).insert(child_c, ZIndex::new(0), tick)
  let child_a = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    child_a,
    @hierarchy.Parent::new(root),
    tick,
  )
  Has_UiLayout::get_ui_layout_store(world).insert(child_a, layout_dummy(), tick)
  Has_ZIndex::get_z_index_store(world).insert(child_a, ZIndex::new(1), tick)
  let child_a0 = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    child_a0,
    @hierarchy.Parent::new(child_a),
    tick,
  )
  Has_UiLayout::get_ui_layout_store(world).insert(
    child_a0,
    layout_dummy(),
    tick,
  )

  // Build Children from Parent.
  @transform.update_children_system(world)
  ui_stack_system(world)
  let stack = HasRes_UiStack::get_ui_stack_resource(world)
    .get()
    .unwrap()
    .uinodes()
  fn eq(a : @core.Entity, b : @core.Entity) -> Bool {
    a.id == b.id && a.generation == b.generation
  }

  let expected : Array[@core.Entity] = [
    global_root, root, child_b, child_c, child_a, child_a0,
  ]
  let mut ok = stack.length() == expected.length()
  if ok {
    for i in 0..<expected.length() {
      if !eq(stack[i], expected[i]) {
        ok = false
        break
      }
    }
  }
  inspect(ok, content="true")
}
