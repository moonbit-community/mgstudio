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
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  let parent = world.spawn_empty()
  @visibility.Has_Visibility::get_visibility_store(world).insert(
    parent,
    @visibility.Visibility::Hidden,
    tick,
  )
  @visibility.Has_InheritedVisibility::get_inherited_visibility_store(world).insert(
    parent,
    @visibility.InheritedVisibility::new(true),
    tick,
  )
  @visibility.Has_ViewVisibility::get_view_visibility_store(world).insert(
    parent,
    @visibility.ViewVisibility::new(true),
    tick,
  )
  let child = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    child,
    @hierarchy.Parent::new(parent),
    tick,
  )
  @visibility.Has_Visibility::get_visibility_store(world).insert(
    child,
    @visibility.Visibility::Inherited,
    tick,
  )
  @visibility.Has_InheritedVisibility::get_inherited_visibility_store(world).insert(
    child,
    @visibility.InheritedVisibility::new(true),
    tick,
  )
  @visibility.Has_ViewVisibility::get_view_visibility_store(world).insert(
    child,
    @visibility.ViewVisibility::new(true),
    tick,
  )
  @transform.update_children_system(world)
  @visibility.visibility_propagate_system(world)
  let iv = @visibility.Has_InheritedVisibility::get_inherited_visibility_store(
    world,
  ).get(child)
  inspect(iv.unwrap().is_visible(), content="false")
}

///|
test "visibility: Visible overrides hidden parent (bevy semantics)" {
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  let parent = world.spawn_empty()
  @visibility.Has_Visibility::get_visibility_store(world).insert(
    parent,
    @visibility.Visibility::Hidden,
    tick,
  )
  @visibility.Has_InheritedVisibility::get_inherited_visibility_store(world).insert(
    parent,
    @visibility.InheritedVisibility::new(true),
    tick,
  )
  @visibility.Has_ViewVisibility::get_view_visibility_store(world).insert(
    parent,
    @visibility.ViewVisibility::new(true),
    tick,
  )
  let child = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    child,
    @hierarchy.Parent::new(parent),
    tick,
  )
  @visibility.Has_Visibility::get_visibility_store(world).insert(
    child,
    @visibility.Visibility::Visible,
    tick,
  )
  @visibility.Has_InheritedVisibility::get_inherited_visibility_store(world).insert(
    child,
    @visibility.InheritedVisibility::new(false),
    tick,
  )
  @visibility.Has_ViewVisibility::get_view_visibility_store(world).insert(
    child,
    @visibility.ViewVisibility::new(false),
    tick,
  )
  @transform.update_children_system(world)
  @visibility.visibility_propagate_system(world)
  let iv = @visibility.Has_InheritedVisibility::get_inherited_visibility_store(
    world,
  ).get(child)
  inspect(iv.unwrap().is_visible(), content="true")
}

///|
test "visibility: Inherited falls back to visible when parent lacks components" {
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  let parent = world.spawn_empty()
  // Parent intentionally has no Visibility/InheritedVisibility/ViewVisibility.

  let child = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    child,
    @hierarchy.Parent::new(parent),
    tick,
  )
  @visibility.Has_Visibility::get_visibility_store(world).insert(
    child,
    @visibility.Visibility::Inherited,
    tick,
  )
  @visibility.Has_InheritedVisibility::get_inherited_visibility_store(world).insert(
    child,
    @visibility.InheritedVisibility::new(false),
    tick,
  )
  @visibility.Has_ViewVisibility::get_view_visibility_store(world).insert(
    child,
    @visibility.ViewVisibility::new(false),
    tick,
  )
  @transform.update_children_system(world)
  @visibility.visibility_propagate_system(world)
  let iv = @visibility.Has_InheritedVisibility::get_inherited_visibility_store(
    world,
  ).get(child)
  inspect(iv.unwrap().is_visible(), content="true")
}
