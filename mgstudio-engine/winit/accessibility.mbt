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
fn winit_accessibility_requested_enabled(world : @ecs.World) -> Bool {
  match @a11y.get_accessibility_requested_resource(world).get() {
    Some(requested) => requested.get()
    None => false
  }
}

///|
fn winit_manage_accessibility_updates_enabled(world : @ecs.World) -> Bool {
  match @a11y.get_manage_accessibility_updates_resource(world).get() {
    Some(manage_updates) => manage_updates.get()
    None => false
  }
}

///|
fn winit_should_update_accessibility_nodes(world : @ecs.World) -> Bool {
  winit_accessibility_requested_enabled(world) &&
  winit_manage_accessibility_updates_enabled(world)
}

///|
fn winit_primary_window(world : @ecs.World) -> (@core.Entity, @window.Window)? {
  let out : (@core.Entity, @window.Window)? = None
  let out_ref = Ref::new(out)
  world.for_each_component(@window.ecs_key_primary_window, fn(
    entity,
    _primary,
  ) {
    if out_ref.val is Some(_) {
      return
    }
    if (try! world.get_by_key(entity, @window.ecs_key_window)) is Some(window) {
      out_ref.val = Some((entity, window))
    }
  })
  out_ref.val
}

///|
fn winit_accessibility_focus_node_id(
  world : @ecs.World,
  primary_window_entity : @core.Entity,
  node_entities : Map[UInt64, Bool],
) -> @moon_accesskit.NodeId {
  let default_focus = @a11y.node_id_for_entity(primary_window_entity)
  match
    (try world.get_resource(@input_focus.InputFocus::resource()) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(input_focus) =>
      match input_focus.get() {
        Some(focused_entity) =>
          if node_entities.contains(focused_entity.to_bits()) {
            @a11y.node_id_for_entity(focused_entity)
          } else {
            default_focus
          }
        None => default_focus
      }
    None => default_focus
  }
}

///|
fn winit_build_accessibility_tree_update(
  world : @ecs.World,
) -> @moon_accesskit.TreeUpdate? {
  guard winit_primary_window(world)
    is Some((primary_window_entity, primary_window)) else {
    return None
  }

  let nodes_snapshot : Array[(@core.Entity, @a11y.AccessibilityNode)] = []
  world.for_each_component(@a11y.ecs_key_accessibility_node, fn(entity, node) {
    nodes_snapshot.push((entity, node))
  })
  if nodes_snapshot.length() == 0 {
    return None
  }

  let node_entities : Map[UInt64, Bool] = {}
  for pair in nodes_snapshot {
    let entity = pair.0
    node_entities.set(entity.to_bits(), true)
  }

  let window_children : Array[@moon_accesskit.NodeId] = []
  let node_updates : Array[(@moon_accesskit.NodeId, @moon_accesskit.Node)] = []
  for pair in nodes_snapshot {
    let entity = pair.0
    let accessibility_node = pair.1
    let node = accessibility_node.node()
    let child_ids : Array[@moon_accesskit.NodeId] = []
    if (try! world.get_by_key(entity, @hierarchy.ecs_key_children))
      is Some(children) {
      for child in children.entities() {
        if node_entities.contains(child.to_bits()) {
          child_ids.push(@a11y.node_id_for_entity(child))
        }
      }
    }
    node.set_children(child_ids)
    let has_accessibility_parent = match
      (try! world.get_by_key(entity, @hierarchy.ecs_key_parent)) {
      Some(parent) => node_entities.contains(parent.entity().to_bits())
      None => false
    }
    if !has_accessibility_parent {
      window_children.push(@a11y.node_id_for_entity(entity))
    }
    node_updates.push((@a11y.node_id_for_entity(entity), node))
  }

  let window_node = @moon_accesskit.Node::new(@moon_accesskit.Role::Window)
  if primary_window.title != "" {
    window_node.set_label(primary_window.title)
  }
  window_node.set_children(window_children)
  let window_node_id = @a11y.node_id_for_entity(primary_window_entity)
  let focus_node_id = winit_accessibility_focus_node_id(
    world, primary_window_entity, node_entities,
  )
  let update = @moon_accesskit.TreeUpdate::new(
    @moon_accesskit.TreeId::root(),
    focus_node_id,
  )
  update.set_tree(@moon_accesskit.Tree::new(window_node_id))
  update.push_node(window_node_id, window_node)
  for pair in node_updates {
    update.push_node(pair.0, pair.1)
  }
  Some(update)
}

///|
fn winit_bind_accessibility_requested_system(world : @ecs.World) -> Unit {
  guard @a11y.get_accessibility_requested_resource(world).get()
    is Some(requested) else {
    return
  }
  @windowing.bind_accessibility_requested(
    @a11y.AccessibilityRequested::handle(requested),
  )
}

///|
fn winit_poll_accessibility_actions_system(world : @ecs.World) -> Unit {
  let actions = @windowing.take_accessibility_actions()
  if actions.length() == 0 {
    return
  }
  let writer = world.message_writer(@a11y.ecs_msg_key_action_request)
  for action in actions {
    ignore(writer.write(@a11y.ActionRequest::new(action)))
  }
}

///|
fn winit_update_accessibility_nodes_system(world : @ecs.World) -> Unit {
  guard winit_should_update_accessibility_nodes(world) else { return }
  guard winit_build_accessibility_tree_update(world) is Some(update) else {
    return
  }
  @windowing.queue_accessibility_update(update)
}

///|
fn winit_commit_pending_accessibility_update_system(world : @ecs.World) -> Unit {
  guard winit_should_update_accessibility_nodes(world) else { return }
  @windowing.commit_pending_accessibility_update() |> ignore
}
