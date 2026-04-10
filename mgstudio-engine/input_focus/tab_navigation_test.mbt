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
fn tab_focus_resource(world : @ecs.World) -> InputFocus {
  match (try! world.get_resource(InputFocus::resource())) {
    Some(focus) => focus
    None => abort("missing InputFocus resource")
  }
}

///|
fn tab_focus_entity(world : @ecs.World) -> @core.Entity? {
  tab_focus_resource(world).get()
}

///|
fn make_focus_app() -> @app.App[@ecs.World] {
  input_dispatch_plugin(@app.App::new(@ecs.World::new()))
}

///|
fn[T : @ecs.Component] insert_component(
  world : @ecs.World,
  entity : @core.Entity,
  value : T,
) -> Unit raise {
  world.entity_mut(entity).insert_component(value) |> ignore
}

///|
test "tab_navigation follows child order when TabIndex values are equal" {
  let app = make_focus_app()
  let world = app.world()
  let group = world.spawn()
  let first = world.spawn()
  let second = world.spawn()

  insert_component(world, group, TabGroup::new(0))
  insert_component(world, group, @hierarchy.Children::new([first, second]))
  insert_component(world, first, @hierarchy.Parent::new(group))
  insert_component(world, second, @hierarchy.Parent::new(group))
  insert_component(world, first, TabIndex::new(0))
  insert_component(world, second, TabIndex::new(0))

  advance_tab_focus(world, false)
  debug_inspect(tab_focus_entity(world) == Some(first), content="true")

  advance_tab_focus(world, false)
  debug_inspect(tab_focus_entity(world) == Some(second), content="true")

  advance_tab_focus(world, false)
  debug_inspect(tab_focus_entity(world) == Some(first), content="true")
}

///|
test "tab_navigation orders groups first, then TabIndex, and supports reverse traversal" {
  let app = make_focus_app()
  let world = app.world()
  let early_group = world.spawn()
  let late_group = world.spawn()
  let early = world.spawn()
  let late_first = world.spawn()
  let late_second = world.spawn()

  insert_component(world, early_group, TabGroup::new(0))
  insert_component(world, late_group, TabGroup::new(1))
  insert_component(world, early_group, @hierarchy.Children::new([early]))
  insert_component(
    world,
    late_group,
    @hierarchy.Children::new([late_first, late_second]),
  )
  insert_component(world, early, @hierarchy.Parent::new(early_group))
  insert_component(world, late_first, @hierarchy.Parent::new(late_group))
  insert_component(world, late_second, @hierarchy.Parent::new(late_group))
  insert_component(world, early, TabIndex::new(0))
  insert_component(world, late_first, TabIndex::new(1))
  insert_component(world, late_second, TabIndex::new(3))

  advance_tab_focus(world, false)
  debug_inspect(tab_focus_entity(world) == Some(early), content="true")

  advance_tab_focus(world, false)
  debug_inspect(tab_focus_entity(world) == Some(late_first), content="true")

  advance_tab_focus(world, false)
  debug_inspect(tab_focus_entity(world) == Some(late_second), content="true")

  advance_tab_focus(world, true)
  debug_inspect(tab_focus_entity(world) == Some(late_first), content="true")
}

///|
test "tab_navigation restricts traversal to modal groups when present" {
  let app = make_focus_app()
  let world = app.world()
  let normal_group = world.spawn()
  let modal_group = world.spawn()
  let normal_button = world.spawn()
  let modal_button = world.spawn()

  insert_component(world, normal_group, TabGroup::new(0))
  insert_component(world, modal_group, TabGroup::modal())
  insert_component(
    world,
    normal_group,
    @hierarchy.Children::new([normal_button]),
  )
  insert_component(world, modal_group, @hierarchy.Children::new([modal_button]))
  insert_component(world, normal_button, @hierarchy.Parent::new(normal_group))
  insert_component(world, modal_button, @hierarchy.Parent::new(modal_group))
  insert_component(world, normal_button, TabIndex::new(0))
  insert_component(world, modal_button, TabIndex::new(0))

  advance_tab_focus(world, false)
  debug_inspect(tab_focus_entity(world) == Some(modal_button), content="true")
}
