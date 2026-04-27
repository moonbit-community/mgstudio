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
  ignore(tick)
  let parent = world.spawn_empty()
  try! world.set_by_key(
    parent,
    ecs_key_visibility,
    @visibility.Visibility::Hidden,
  )
  try! world.set_by_key(
    parent,
    ecs_key_inherited_visibility,
    @visibility.InheritedVisibility::new(true),
  )
  try! world.set_by_key(
    parent,
    ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  let child = world.spawn_empty()
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(
    child,
    ecs_key_visibility,
    @visibility.Visibility::Inherited,
  )
  try! world.set_by_key(
    child,
    ecs_key_inherited_visibility,
    @visibility.InheritedVisibility::new(true),
  )
  try! world.set_by_key(
    child,
    ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  @visibility.visibility_propagate_system(world)
  let iv = try! world.get_by_key(child, ecs_key_inherited_visibility)
  debug_inspect(iv.unwrap().is_visible(), content="false")
}

///|
test "visibility: Visible overrides hidden parent (bevy semantics)" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  let parent = world.spawn_empty()
  try! world.set_by_key(
    parent,
    ecs_key_visibility,
    @visibility.Visibility::Hidden,
  )
  try! world.set_by_key(
    parent,
    ecs_key_inherited_visibility,
    @visibility.InheritedVisibility::new(true),
  )
  try! world.set_by_key(
    parent,
    ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  let child = world.spawn_empty()
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(
    child,
    ecs_key_visibility,
    @visibility.Visibility::Visible,
  )
  try! world.set_by_key(
    child,
    ecs_key_inherited_visibility,
    @visibility.InheritedVisibility::new(false),
  )
  try! world.set_by_key(
    child,
    ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  @visibility.visibility_propagate_system(world)
  let iv = try! world.get_by_key(child, ecs_key_inherited_visibility)
  debug_inspect(iv.unwrap().is_visible(), content="true")
}

///|
test "visibility: Inherited falls back to visible when parent lacks components" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  let parent = world.spawn_empty()
  // Parent intentionally has no Visibility/InheritedVisibility/ViewVisibility.

  let child = world.spawn_empty()
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(
    child,
    ecs_key_visibility,
    @visibility.Visibility::Inherited,
  )
  try! world.set_by_key(
    child,
    ecs_key_inherited_visibility,
    @visibility.InheritedVisibility::new(false),
  )
  try! world.set_by_key(
    child,
    ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  @visibility.visibility_propagate_system(world)
  let iv = try! world.get_by_key(child, ecs_key_inherited_visibility)
  debug_inspect(iv.unwrap().is_visible(), content="true")
}

///|
test "visibility: VisibilityRange constructors" {
  let always = @visibility.VisibilityRange::always_visible()
  debug_inspect(always.start_margin_min, content="0")
  debug_inspect(always.end_margin_max, content="1000000")
  debug_inspect(always.use_aabb, content="false")

  let invisible = @visibility.VisibilityRange::invisible()
  debug_inspect(invisible.start_margin_max, content="0")
  debug_inspect(invisible.end_margin_min, content="0")
  debug_inspect(invisible.use_aabb, content="false")
}

///|
test "visibility: toggle_inherited_visible matches bevy semantics" {
  debug_inspect(
    @visibility.Visibility::Inherited.toggle_inherited_visible(),
    content="Visible",
  )
  debug_inspect(
    @visibility.Visibility::Visible.toggle_inherited_visible(),
    content="Inherited",
  )
  debug_inspect(
    @visibility.Visibility::Hidden.toggle_inherited_visible(),
    content="Hidden",
  )
}

///|
test "visibility: toggle_inherited_hidden matches bevy semantics" {
  debug_inspect(
    @visibility.Visibility::Inherited.toggle_inherited_hidden(),
    content="Hidden",
  )
  debug_inspect(
    @visibility.Visibility::Hidden.toggle_inherited_hidden(),
    content="Inherited",
  )
  debug_inspect(
    @visibility.Visibility::Visible.toggle_inherited_hidden(),
    content="Visible",
  )
}

///|
test "visibility: toggle_visible_hidden matches bevy semantics" {
  debug_inspect(
    @visibility.Visibility::Visible.toggle_visible_hidden(),
    content="Hidden",
  )
  debug_inspect(
    @visibility.Visibility::Hidden.toggle_visible_hidden(),
    content="Visible",
  )
  debug_inspect(
    @visibility.Visibility::Inherited.toggle_visible_hidden(),
    content="Inherited",
  )
}

///|
test "visibility: inherited visibility visible-hidden helpers match bevy semantics" {
  debug_inspect(
    @visibility.InheritedVisibility::visible().get(),
    content="true",
  )
  debug_inspect(
    @visibility.InheritedVisibility::hidden().get(),
    content="false",
  )
}

///|
test "visibility: view visibility hidden/get helpers match bevy semantics" {
  debug_inspect(@visibility.ViewVisibility::new(true).get(), content="true")
  debug_inspect(@visibility.ViewVisibility::hidden().get(), content="false")
}

///|
test "visibility: view visibility tracks current and previous frame bits" {
  let view_visibility = @visibility.ViewVisibility::new(true)
  debug_inspect(view_visibility.get(), content="true")
  debug_inspect(view_visibility.was_visible_now_hidden(), content="false")
  view_visibility.update()
  debug_inspect(view_visibility.get(), content="false")
  debug_inspect(view_visibility.was_visible_now_hidden(), content="true")
  view_visibility.set_visible()
  debug_inspect(view_visibility.get(), content="true")
  debug_inspect(view_visibility.was_visible_now_hidden(), content="false")
}

///|
test "visibility: no-cpu-culling marker has stable default and ecs key" {
  let world = @ecs.World::new()
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_no_cpu_culling,
    @visibility.NoCpuCulling::default(),
  )
  debug_inspect(
    (try! world.get_by_key(entity, @visibility.ecs_key_no_cpu_culling))
    is Some(_),
    content="true",
  )
}
