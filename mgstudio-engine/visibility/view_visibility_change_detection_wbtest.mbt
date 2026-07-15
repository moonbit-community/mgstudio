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
test "visibility: view visibility only changes on semantic transitions" {
  let world = @ecs.World::new()
  defer world.close()
  let stable_visible = world.spawn()
  let becomes_visible = world.spawn()
  let becomes_hidden = world.spawn()
  let stable_hidden = world.spawn()
  for
    pair in [
      (stable_visible, true),
      (becomes_visible, false),
      (becomes_hidden, true),
      (stable_hidden, false),
    ] {
    let (entity, visible) = pair
    try! world.set_by_key(
      entity,
      ecs_key_view_visibility,
      ViewVisibility::new(visible),
    )
  }
  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore
  let tick_context = @core.SystemTickContext::new()
  tick_context.set(@core.SystemTicks::new(1, 2))
  world.set_tick_context(tick_context)

  reset_view_visibility_system(world)
  for entity in [stable_visible, becomes_visible] {
    let view_visibility = (try! world.get_mut(
      entity,
      key=ecs_key_view_visibility,
    )).unwrap()
    SetViewVisibility::set_visible(view_visibility)
  }
  mark_newly_hidden_entities_invisible_system(world)

  let changed = world
    .changed_components(ecs_key_view_visibility, @core.SystemTicks::new(1, 2))
    .read()
  debug_inspect(changed.contains(stable_visible), content="false")
  debug_inspect(changed.contains(becomes_visible), content="true")
  debug_inspect(changed.contains(becomes_hidden), content="true")
  debug_inspect(changed.contains(stable_hidden), content="false")
  for
    pair in [
      (stable_visible, true),
      (becomes_visible, true),
      (becomes_hidden, false),
      (stable_hidden, false),
    ] {
    let (entity, expected) = pair
    let current = (try! world.get_by_key(entity, ecs_key_view_visibility)).unwrap()
    debug_inspect(current.get() == expected, content="true")
  }
}
