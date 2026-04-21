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
pub struct TabIndex {
  value : Int
}

///|
pub struct TabNavigationPlugin {}

///|
pub fn TabNavigationPlugin::default() -> TabNavigationPlugin {
  TabNavigationPlugin::{  }
}

///|
pub impl @app.Plugin for TabNavigationPlugin with name(_self) {
  "mgstudio.input_focus.TabNavigationPlugin"
}

///|
pub impl @app.Plugin for TabNavigationPlugin with build(_self, app) {
  tab_navigation_plugin(app)
}

///|
pub fn TabIndex::new(value : Int) -> TabIndex {
  TabIndex::{ value, }
}

///|
pub fn TabIndex::value(self : TabIndex) -> Int {
  self.value
}

///|
let tab_index_component_key : @ecs.ComponentKey[TabIndex] = @ecs.register_component(
  debug_name="mgstudio_input_focus::tab_navigation::TabIndex",
)

///|
pub impl @ecs.Component for TabIndex with component() {
  tab_index_component_key
}

///|
pub struct TabGroup {
  modal : Bool
  order : Int
}

///|
pub fn TabGroup::new(order : Int) -> TabGroup {
  TabGroup::{ modal: false, order }
}

///|
pub fn TabGroup::modal() -> TabGroup {
  TabGroup::{ modal: true, order: 0 }
}

///|
pub fn TabGroup::is_modal(self : TabGroup) -> Bool {
  self.modal
}

///|
pub fn TabGroup::order(self : TabGroup) -> Int {
  self.order
}

///|
let tab_group_component_key : @ecs.ComponentKey[TabGroup] = @ecs.register_component(
  debug_name="mgstudio_input_focus::tab_navigation::TabGroup",
)

///|
pub impl @ecs.Component for TabGroup with component() {
  tab_group_component_key
}

///|
priv struct TabCandidate {
  entity : @core.Entity
  entity_path : Array[Int]
  group_modal : Bool
  group_order : Int
  group_path : Array[Int]
  tab_index : Int
}

///|
fn compare_int(a : Int, b : Int) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn compare_path(a : Array[Int], b : Array[Int]) -> Int {
  let shared = if a.length() < b.length() { a.length() } else { b.length() }
  for i in 0..<shared {
    let order = compare_int(a[i], b[i])
    if order != 0 {
      return order
    }
  }
  compare_int(a.length(), b.length())
}

///|
fn compare_tab_candidate(a : TabCandidate, b : TabCandidate) -> Int {
  let group_order = compare_int(a.group_order, b.group_order)
  if group_order != 0 {
    return group_order
  }
  let group_path = compare_path(a.group_path, b.group_path)
  if group_path != 0 {
    return group_path
  }
  let tab_index = compare_int(a.tab_index, b.tab_index)
  if tab_index != 0 {
    return tab_index
  }
  compare_path(a.entity_path, b.entity_path)
}

///|
fn insert_sorted_candidate(
  candidates : Array[TabCandidate],
  candidate : TabCandidate,
) -> Unit {
  let mut insert_at = candidates.length()
  for i in 0..<candidates.length() {
    if compare_tab_candidate(candidate, candidates[i]) < 0 {
      insert_at = i
      break
    }
  }
  candidates.push(candidate)
  let mut current = candidates.length() - 1
  while current > insert_at {
    let previous = candidates[current - 1]
    candidates[current - 1] = candidates[current]
    candidates[current] = previous
    current = current - 1
  }
}

///|
fn tab_navigation_children(
  world : @ecs.World,
  entity : @core.Entity,
) -> @hierarchy.Children? {
  try world.entity(entity).get() catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn tab_navigation_child_index(
  world : @ecs.World,
  parent : @core.Entity,
  child : @core.Entity,
) -> Int {
  match tab_navigation_children(world, parent) {
    Some(children) => {
      let entities = children.entities()
      for i in 0..<entities.length() {
        if entities[i] == child {
          return i
        }
      }
      0
    }
    None => 0
  }
}

///|
fn tab_navigation_entity_path(
  world : @ecs.World,
  entity : @core.Entity,
) -> Array[Int] {
  let path : Array[Int] = []
  let lineage : Array[(@core.Entity, @core.Entity)] = []
  let mut current = entity
  while input_focus_parent_entity(world, current) is Some(parent) {
    lineage.push((parent, current))
    current = parent
  }
  let mut current = lineage.length()
  while current > 0 {
    let (parent, child) = lineage[current - 1]
    path.push(tab_navigation_child_index(world, parent, child))
    current = current - 1
  }
  path
}

///|
fn tab_navigation_group(
  world : @ecs.World,
  entity : @core.Entity,
) -> (@core.Entity, TabGroup)? {
  let current_group : TabGroup? = try world.entity(entity).get() catch {
    _ => None
  } noraise {
    value => value
  }
  if current_group is Some(group) {
    return Some((entity, group))
  }
  match input_focus_parent_entity(world, entity) {
    Some(parent) => tab_navigation_group(world, parent)
    None => None
  }
}

///|
fn tab_navigation_collect_candidates(world : @ecs.World) -> Array[TabCandidate] {
  let candidates : Array[TabCandidate] = []
  let query : @ecs.Query[(@core.Entity, @ecs.Comp[TabIndex]), @ecs.All] = @ecs.query(
    world,
  )
  try! query.view(fn(_query_entity, data) {
    let (entity, tab_index) = data
    let entity_path = tab_navigation_entity_path(world, entity)
    let candidate = match tab_navigation_group(world, entity) {
      Some((group_entity, group)) =>
        TabCandidate::{
          entity,
          entity_path,
          group_modal: group.is_modal(),
          group_order: group.order(),
          group_path: tab_navigation_entity_path(world, group_entity),
          tab_index: tab_index.value().value(),
        }
      None =>
        TabCandidate::{
          entity,
          entity_path,
          group_modal: false,
          group_order: 0,
          group_path: [],
          tab_index: tab_index.value().value(),
        }
    }
    insert_sorted_candidate(candidates, candidate)
  })
  let mut has_modal = false
  for candidate in candidates {
    if candidate.group_modal {
      has_modal = true
      break
    }
  }
  if !has_modal {
    return candidates
  }
  let modal_only : Array[TabCandidate] = []
  for candidate in candidates {
    if candidate.group_modal {
      modal_only.push(candidate)
    }
  }
  modal_only
}

///|
fn input_focus_visible_resource_ref_mut(
  world : @ecs.World,
) -> @ecs.ResourceMut[InputFocusVisible]? {
  try world.get_resource_mut(InputFocusVisible::resource()) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
pub fn advance_tab_focus(world : @ecs.World, reverse : Bool) -> Unit {
  let candidates = tab_navigation_collect_candidates(world)
  if candidates.is_empty() {
    return
  }
  guard input_focus_world_resource_ref_mut(world, InputFocus::resource())
    is Some(focus) else {
    return
  }
  let current = focus.peek().get()
  let mut current_index = -1
  for i in 0..<candidates.length() {
    if current == Some(candidates[i].entity) {
      current_index = i
      break
    }
  }
  let next_index = if current_index < 0 {
    if reverse {
      candidates.length() - 1
    } else {
      0
    }
  } else if reverse {
    if current_index == 0 {
      candidates.length() - 1
    } else {
      current_index - 1
    }
  } else if current_index + 1 >= candidates.length() {
    0
  } else {
    current_index + 1
  }
  focus.modify(fn(value) { value.set(candidates[next_index].entity) })
  if input_focus_visible_resource_ref_mut(world) is Some(visible) {
    visible.modify(fn(value) { value.set_visible(true) })
  }
}

///|
fn tab_navigation_input(keyboard : @input.ButtonInput[@window.KeyCode]) -> Unit {
  if !keyboard.just_pressed(@window.KeyCode::Tab) {
    return
  }
  let reverse = keyboard.pressed(@window.KeyCode::ShiftLeft) ||
    keyboard.pressed(@window.KeyCode::ShiftRight)
  let world = current_input_focus_world_abort_missing()
  advance_tab_focus(world, reverse)
}

///|
pub fn tab_navigation_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app.add_systems(
    @app.Update,
    @app.system(@app.system_param(tab_navigation_input)),
  )
}
