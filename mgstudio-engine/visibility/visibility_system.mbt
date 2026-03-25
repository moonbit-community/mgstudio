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
/// Visibility propagation systems (Bevy-aligned).
///
/// We follow Bevy's semantics from `bevy_camera::visibility`:
/// - Visibility::Hidden   => inherited=false
/// - Visibility::Visible  => inherited=true (even if parent is hidden)
/// - Visibility::Inherited => inherited=parent_inherited (or true if parent is missing the required components)
///
/// Current stage-1 behavior: ViewVisibility is set equal to InheritedVisibility
/// (no frustum culling yet).

///|
pub fn visibility_propagate_system(world : @ecs.World) -> Unit {

  // Identify roots: entities that either have no parent, or whose parent lacks
  // the required visibility components (Bevy fallback).
  let roots : Array[@core.Entity] = []
  let visibility_query : @ecs.Query[@ecs.Comp[Visibility], @ecs.All] = @ecs.query(
    world,
  )
  try! visibility_query.view(fn(entity, _visibility) {
    match (try! world.get_by_key(entity, @hierarchy.ecs_key_parent)) {
      None => roots.push(entity)
      Some(parent) => {
        let p = parent.entity()
        if !(try! world.contains_by_key(p, ecs_key_visibility)) ||
          !(try! world.contains_by_key(p, ecs_key_inherited_visibility)) {
          roots.push(entity)
        }
      }
    }
  })

  // DFS traversal from roots, propagating inherited visibility.
  let stack : Array[(@core.Entity, Bool)] = []
  for root in roots {
    stack.push((root, true))
  }
  while stack.length() > 0 {
    let (entity, parent_visible) = stack.pop().unwrap()
    guard (try! world.get_by_key(entity, ecs_key_visibility))
      is Some(visibility) else {
      continue
    }
    let is_visible = match visibility {
      Visibility::Hidden => false
      Visibility::Visible => true
      Visibility::Inherited => parent_visible
    }

    // Update InheritedVisibility (insert if missing).
    let needs_inherited_update = match
      (try! world.get_by_key(entity, ecs_key_inherited_visibility)) {
      Some(v) => v.is_visible() != is_visible
      None => true
    }
    if needs_inherited_update {
      let v = InheritedVisibility::new(is_visible)
      if (try! world.contains_by_key(entity, ecs_key_inherited_visibility)) {
        try! (world.replace(entity, ecs_key_inherited_visibility, v) |> ignore)
      } else {
        try! world.set_by_key(entity, ecs_key_inherited_visibility, v)
      }
    }

    // Stage-1: ViewVisibility == InheritedVisibility (no culling yet).
    let needs_view_update = match
      (try! world.get_by_key(entity, ecs_key_view_visibility)) {
      Some(v) => v.is_visible() != is_visible
      None => true
    }
    if needs_view_update {
      let v = ViewVisibility::new(is_visible)
      if (try! world.contains_by_key(entity, ecs_key_view_visibility)) {
        try! (world.replace(entity, ecs_key_view_visibility, v) |> ignore)
      } else {
        try! world.set_by_key(entity, ecs_key_view_visibility, v)
      }
    }

    // Recurse to children that participate in visibility (same as Bevy's query
    // constraints: With<Visibility>, With<InheritedVisibility>).
    if (try! world.get_by_key(entity, @hierarchy.ecs_key_children))
      is Some(children) {
      for child in children.entities() {
        if (try! world.contains_by_key(child, ecs_key_visibility)) {
          stack.push((child, is_visible))
        }
      }
    }
  }
}

///|
pub fn visibility_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  // Hierarchy hooks keep `Children` synchronized with `Parent` before schedule execution.
  app.add_pre_update_system(visibility_propagate_system)
}
