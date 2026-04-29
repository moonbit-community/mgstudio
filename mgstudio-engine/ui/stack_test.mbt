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
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  fn layout_dummy() -> UiLayout {
    UiLayout::new(
      @math.Rect::new(@math.Vec2::new(0.0F, 0.0F), @math.Vec2::new(1.0F, 1.0F)),
    )
  }

  let global_root = world.spawn_empty()
  try! world.set_by_key(global_root, ecs_key_ui_layout, layout_dummy())
  try! world.set_by_key(
    global_root,
    ecs_key_global_z_index,
    GlobalZIndex::new(-1),
  )
  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_layout, layout_dummy())
  let child_b = world.spawn_empty()
  try! world.set_by_key(
    child_b,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(child_b, ecs_key_ui_layout, layout_dummy())
  try! world.set_by_key(child_b, ecs_key_z_index, ZIndex::new(0))
  let child_c = world.spawn_empty()
  try! world.set_by_key(
    child_c,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(child_c, ecs_key_ui_layout, layout_dummy())
  // Same z as child_b: should preserve insertion order (b before c).
  try! world.set_by_key(child_c, ecs_key_z_index, ZIndex::new(0))
  let child_a = world.spawn_empty()
  try! world.set_by_key(
    child_a,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(child_a, ecs_key_ui_layout, layout_dummy())
  try! world.set_by_key(child_a, ecs_key_z_index, ZIndex::new(1))
  let child_a0 = world.spawn_empty()
  try! world.set_by_key(
    child_a0,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(child_a),
  )
  try! world.set_by_key(child_a0, ecs_key_ui_layout, layout_dummy())

  // Build Children from Parent.
  ui_stack_system(world)
  let stack_resource = get_ui_stack_resource(world).get().unwrap()
  let stack = stack_resource.uinodes()
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
  debug_inspect(ok, content="true")
  let partitions = stack_resource.partition()
  debug_inspect(partitions.length() == 2, content="true")
  debug_inspect(partitions[0].0 == 0 && partitions[0].1 == 1, content="true")
  debug_inspect(partitions[1].0 == 1 && partitions[1].1 == 6, content="true")
  for i in 0..<expected.length() {
    let layout = try! world.get_by_key(expected[i], ecs_key_ui_layout).unwrap()
    debug_inspect(layout.stack_index() == i, content="true")
  }
}
