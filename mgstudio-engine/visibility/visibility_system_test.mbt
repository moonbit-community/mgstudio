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
test "visibility: inherited child is hidden when parent is hidden" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  let parent = world.spawn_empty()
  get_visibility_store(world).insert(
    parent,
    @visibility.Visibility::Hidden,
    tick,
  )
  get_inherited_visibility_store(world).insert(
    parent,
    @visibility.InheritedVisibility::new(true),
    tick,
  )
  get_view_visibility_store(world).insert(
    parent,
    @visibility.ViewVisibility::new(true),
    tick,
  )
  let child = world.spawn_empty()
  @hierarchy.get_parent_store(world).insert(
    child,
    @hierarchy.Parent::new(parent),
    tick,
  )
  get_visibility_store(world).insert(
    child,
    @visibility.Visibility::Inherited,
    tick,
  )
  get_inherited_visibility_store(world).insert(
    child,
    @visibility.InheritedVisibility::new(true),
    tick,
  )
  get_view_visibility_store(world).insert(
    child,
    @visibility.ViewVisibility::new(true),
    tick,
  )
  @visibility.visibility_propagate_system(world)
  let iv = get_inherited_visibility_store(world).get(child)
  inspect(iv.unwrap().is_visible(), content="false")
}

///|
test "visibility: Visible overrides hidden parent (bevy semantics)" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  let parent = world.spawn_empty()
  get_visibility_store(world).insert(
    parent,
    @visibility.Visibility::Hidden,
    tick,
  )
  get_inherited_visibility_store(world).insert(
    parent,
    @visibility.InheritedVisibility::new(true),
    tick,
  )
  get_view_visibility_store(world).insert(
    parent,
    @visibility.ViewVisibility::new(true),
    tick,
  )
  let child = world.spawn_empty()
  @hierarchy.get_parent_store(world).insert(
    child,
    @hierarchy.Parent::new(parent),
    tick,
  )
  get_visibility_store(world).insert(
    child,
    @visibility.Visibility::Visible,
    tick,
  )
  get_inherited_visibility_store(world).insert(
    child,
    @visibility.InheritedVisibility::new(false),
    tick,
  )
  get_view_visibility_store(world).insert(
    child,
    @visibility.ViewVisibility::new(false),
    tick,
  )
  @visibility.visibility_propagate_system(world)
  let iv = get_inherited_visibility_store(world).get(child)
  inspect(iv.unwrap().is_visible(), content="true")
}

///|
test "visibility: Inherited falls back to visible when parent lacks components" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  let parent = world.spawn_empty()
  // Parent intentionally has no Visibility/InheritedVisibility/ViewVisibility.

  let child = world.spawn_empty()
  @hierarchy.get_parent_store(world).insert(
    child,
    @hierarchy.Parent::new(parent),
    tick,
  )
  get_visibility_store(world).insert(
    child,
    @visibility.Visibility::Inherited,
    tick,
  )
  get_inherited_visibility_store(world).insert(
    child,
    @visibility.InheritedVisibility::new(false),
    tick,
  )
  get_view_visibility_store(world).insert(
    child,
    @visibility.ViewVisibility::new(false),
    tick,
  )
  @visibility.visibility_propagate_system(world)
  let iv = get_inherited_visibility_store(world).get(child)
  inspect(iv.unwrap().is_visible(), content="true")
}

///|
test "visibility: VisibilityRange constructors" {
  let always = @visibility.VisibilityRange::always_visible()
  inspect(always.start_margin_min, content="0")
  inspect(always.end_margin_max, content="1000000")
  inspect(always.use_aabb, content="false")

  let invisible = @visibility.VisibilityRange::invisible()
  inspect(invisible.start_margin_max, content="0")
  inspect(invisible.end_margin_min, content="0")
  inspect(invisible.use_aabb, content="false")
}
