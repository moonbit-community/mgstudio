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
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::VisibilitySystems::VisibilityPropagate`.
pub let visibility_set_calculate_bounds : @app.SystemSet = @app.system_set(
  "mgstudio.visibility.calculate_bounds",
)

///|
pub let visibility_set_visibility_propagate : @app.SystemSet = @app.system_set(
  "mgstudio.visibility.visibility_propagate",
)

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::VisibilitySystems::CheckVisibility`.
pub let visibility_set_check_visibility : @app.SystemSet = @app.system_set(
  "mgstudio.visibility.check_visibility",
)

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::VisibilitySystems::MarkNewlyHiddenEntitiesInvisible`.
pub let visibility_set_mark_newly_hidden_entities_invisible : @app.SystemSet = @app.system_set(
  "mgstudio.visibility.mark_newly_hidden_entities_invisible",
)

///|
priv struct VisibilityPropagationState {}

///|
let ecs_key_visibility_propagation_state : @ecs.ResourceKey[
  VisibilityPropagationState,
] = @ecs.register_resource(
  debug_name="mgstudio_visibility::VisibilityPropagationState",
)

///|
fn visibility_propagate_full_scan(world : @ecs.World) -> Unit {
  let roots : Array[@core.Entity] = []
  let parent_children : Map[UInt64, Array[@core.Entity]] = {}
  world.for_each_component(@hierarchy.ecs_key_parent, fn(entity, parent) {
    let parent_key = parent.entity().to_bits()
    match parent_children.get(parent_key) {
      Some(children) => children.push(entity)
      None => parent_children.set(parent_key, [entity])
    }
  })
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
    if (try! world.get_by_key(entity, @hierarchy.ecs_key_children))
      is Some(children) {
      for child in children.entities() {
        if (try! world.contains_by_key(child, ecs_key_visibility)) {
          stack.push((child, is_visible))
        }
      }
    }
    match parent_children.get(entity.to_bits()) {
      Some(children) =>
        for child in children {
          if (try! world.contains_by_key(child, ecs_key_visibility)) {
            stack.push((child, is_visible))
          }
        }
      None => ()
    }
  }
}

///|
pub fn visibility_propagate_system(world : @ecs.World) -> Unit {
  if (try! world.get_resource(ecs_key_visibility_propagation_state)) is None {
    visibility_propagate_full_scan(world)
    world.insert_resource(ecs_key_visibility_propagation_state, VisibilityPropagationState::{

    })
    return
  }
  let sequence = world.get_sequence_context().sequence()
  let start_entities : Array[(@core.Entity, Bool)] = []
  let start_seen = @utils.IntBitSet::new()

  fn add_start_entity(
    world : @ecs.World,
    start_entities : Array[(@core.Entity, Bool)],
    start_seen : @utils.IntBitSet,
    entity : @core.Entity,
  ) -> Unit {
    if start_seen.contains(entity.id) {
      return
    }
    start_seen.insert(entity.id)
    let parent_visible = match
      (world.get_by_key(entity, @hierarchy.ecs_key_parent) catch { _ => None }) {
      Some(parent) => {
        let p = parent.entity()
        match
          (
            world.get_by_key(p, ecs_key_visibility) catch {
              _ => None
            },
            world.get_by_key(p, ecs_key_inherited_visibility) catch {
              _ => None
            },
          ) {
          (Some(_), Some(inherited)) => inherited.is_visible()
          _ => true
        }
      }
      None => true
    }
    start_entities.push((entity, parent_visible))
  }

  for entity in world.changed_components(ecs_key_visibility, sequence).read() {
    add_start_entity(world, start_entities, start_seen, entity)
  }
  for
    entity in world
    .changed_components(@hierarchy.ecs_key_parent, sequence)
    .read() {
    add_start_entity(world, start_entities, start_seen, entity)
  }
  if start_entities.length() == 0 {
    return
  }

  let stack : Array[(@core.Entity, Bool)] = []
  for start in start_entities {
    stack.push(start)
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
    let inherited_visible_before = match
      (try! world.get_by_key(entity, ecs_key_inherited_visibility)) {
      Some(v) => v.is_visible()
      None => !is_visible
    }
    let inherited_changed = inherited_visible_before != is_visible
    if inherited_changed ||
      !(try! world.contains_by_key(entity, ecs_key_inherited_visibility)) {
      let inherited = InheritedVisibility::new(is_visible)
      if (try! world.contains_by_key(entity, ecs_key_inherited_visibility)) {
        try! (world.replace(entity, ecs_key_inherited_visibility, inherited)
        |> ignore)
      } else {
        try! world.set_by_key(entity, ecs_key_inherited_visibility, inherited)
      }
    }
    if !(try! world.contains_by_key(entity, ecs_key_view_visibility)) ||
      (try! world.get_by_key(entity, ecs_key_view_visibility))
      .map(fn(v) { v.is_visible() })
      .unwrap_or(!is_visible) !=
      is_visible {
      let view = ViewVisibility::new(is_visible)
      if (try! world.contains_by_key(entity, ecs_key_view_visibility)) {
        try! (world.replace(entity, ecs_key_view_visibility, view) |> ignore)
      } else {
        try! world.set_by_key(entity, ecs_key_view_visibility, view)
      }
    }
    if !inherited_changed {
      continue
    }
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
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::check_visibility`.
pub fn check_visibility_system(world : @ecs.World) -> Unit {
  let query : @ecs.Query[
    (@ecs.Mut[ViewVisibility], @ecs.Comp[InheritedVisibility]),
    @ecs.All,
  ] = @ecs.query(world)
  try! query.view(fn(_entity, data) {
    let (view_visibility, inherited_visibility) = data
    if inherited_visibility.value().get() {
      view_visibility.modify(fn(value) { value.set_visible() })
    }
  })
}

///|
fn register_visibility_required_components(
  world : @ecs.World,
) -> Unit raise @ecs.RequiredComponentsError {
  world.register_required_components_with(
    ecs_key_visibility,
    ecs_key_inherited_visibility,
    fn() { InheritedVisibility::new(true) },
  )
  world.register_required_components_with(
    ecs_key_visibility,
    ecs_key_view_visibility,
    fn() { ViewVisibility::new(true) },
  )
}

///|
pub fn visibility_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  // Hierarchy hooks keep `Children` synchronized with `Parent` before schedule execution.
  try! register_visibility_required_components(app.world())
  app
  .configure_set(@app.PostUpdate, visibility_set_visibility_propagate, after=[
    @transform.transform_set_propagate,
  ])
  .add_post_update_system_config(
    @app.system(visibility_propagate_system)
    .named("mgstudio.visibility.visibility_propagate_system")
    .in_set(visibility_set_visibility_propagate),
  )
}
