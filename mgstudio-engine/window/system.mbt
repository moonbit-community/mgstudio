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
pub fn close_when_requested(
  requested : @ecs.MessageReader[WindowCloseRequested],
  _closing : @ecs.Query[@core.Entity, @ecs.With[ClosingWindow]],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  let events = try requested.read() catch {
    _ => []
  } noraise {
    value => value
  }
  for event in events {
    if !world.is_alive(event.window) {
      continue
    }
    let is_already_closing = match
      window_closing_component(world, event.window) {
      Some(_) => true
      None => false
    }
    if !is_already_closing {
      window_set_closing_component(world, event.window)
    }
  }
}

///|
pub fn window_despawn_closing_windows_system(world : @ecs.World) -> Unit {
  let closing_entities : Array[@core.Entity] = []
  world
  .query_entities_filtered(@ecs.With::new(ecs_key_closing_window))
  .view(fn(entity) { closing_entities.push(entity) })
  for entity in closing_entities {
    if !world.is_alive(entity) {
      continue
    }
    window_emit_window_closing(world, WindowClosing::{ window: entity })
    try! world.despawn(entity)
  }
}

///|
pub fn exit_on_all_closed(
  app_exit : @ecs.MessageWriter[@app.AppExit],
  windows : @ecs.Query[@core.Entity, @ecs.With[Window]],
) -> Unit {
  if windows.count() == 0 {
    ignore(app_exit.write(@app.AppExit::Success))
  }
}

///|
pub fn exit_on_primary_closed(
  app_exit : @ecs.MessageWriter[@app.AppExit],
  windows : @ecs.Query[
    @core.Entity,
    (@ecs.With[Window], @ecs.With[PrimaryWindow]),
  ],
) -> Unit {
  if windows.count() == 0 {
    ignore(app_exit.write(@app.AppExit::Success))
  }
}
