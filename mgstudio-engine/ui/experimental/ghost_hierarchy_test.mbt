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
fn entity_eq(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn entity_in_list(
  target : @core.Entity,
  entities : Array[@core.Entity],
) -> Bool {
  for entity in entities {
    if entity_eq(entity, target) {
      return true
    }
  }
  false
}

///|
test "ui.experimental: UiChildren iter flattens ghost hierarchy and skips non-ui children" {
  let world = @ecs.World::new()
  let root = world.spawn()
  let ghost_a = world.spawn()
  let ghost_b = world.spawn()
  let leaf_a = world.spawn()
  let leaf_b = world.spawn()
  let direct_leaf = world.spawn()
  let non_ui = world.spawn()

  try! world.set_by_key(root, @ui.ecs_key_node, @ui.Node::default())

  try! world.set_by_key(
    ghost_a,
    @ui.ecs_key_ghost_node,
    @ui.GhostNode::default(),
  )
  try! world.set_by_key(
    ghost_a,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )

  try! world.set_by_key(
    ghost_b,
    @ui.ecs_key_ghost_node,
    @ui.GhostNode::default(),
  )
  try! world.set_by_key(
    ghost_b,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )

  try! world.set_by_key(leaf_a, @ui.ecs_key_node, @ui.Node::default())
  try! world.set_by_key(
    leaf_a,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(ghost_a),
  )

  try! world.set_by_key(leaf_b, @ui.ecs_key_node, @ui.Node::default())
  try! world.set_by_key(
    leaf_b,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(ghost_b),
  )

  try! world.set_by_key(direct_leaf, @ui.ecs_key_node, @ui.Node::default())
  try! world.set_by_key(
    direct_leaf,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )

  try! world.set_by_key(
    non_ui,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(ghost_a),
  )

  let children = UiChildren::new(world)
  let result = children.iter_ui_children(root)
  debug_inspect(result.length(), content="3")
  debug_inspect(entity_eq(result[0], leaf_a), content="true")
  debug_inspect(entity_eq(result[1], leaf_b), content="true")
  debug_inspect(entity_eq(result[2], direct_leaf), content="true")
  debug_inspect(children.get_parent(leaf_a) == Some(root), content="true")
  debug_inspect(children.is_ui_node(leaf_a), content="true")
  debug_inspect(children.is_ui_node(non_ui), content="false")
}

///|
test "ui.experimental: UiRootNodes iter includes root nodes and root ghost descendants" {
  let world = @ecs.World::new()
  let root_node = world.spawn()
  let root_ghost = world.spawn()
  let root_ghost_leaf = world.spawn()
  let compat_root = world.spawn()

  try! world.set_by_key(root_node, @ui.ecs_key_node, @ui.Node::default())
  try! world.set_by_key(
    root_ghost,
    @ui.ecs_key_ghost_node,
    @ui.GhostNode::default(),
  )
  try! world.set_by_key(root_ghost_leaf, @ui.ecs_key_node, @ui.Node::default())
  try! world.set_by_key(
    root_ghost_leaf,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root_ghost),
  )
  try! world.set_by_key(compat_root, @ui.ecs_key_ui_root, @ui.UiRoot::default())

  let roots = UiRootNodes::new(world).iter()
  debug_inspect(roots.length(), content="3")
  debug_inspect(entity_in_list(root_node, roots), content="true")
  debug_inspect(entity_in_list(root_ghost_leaf, roots), content="true")
  debug_inspect(entity_in_list(compat_root, roots), content="true")
}
