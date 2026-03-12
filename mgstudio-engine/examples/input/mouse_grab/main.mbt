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
/// Port of `bevy/examples/input/mouse_grab.rs`.

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Update, @app.system(@app.system_param2(grab_mouse)))
  .run()
}

///|
fn primary_window_entity(world : @ecs.World) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref::new(None)
  world
  .query_entities_filtered(
    (
      @ecs.With::new(@window.ecs_key_window),
      @ecs.With::new(@window.ecs_key_primary_window),
    ),
  )
  .view(fn(entity) { if result.val is None { result.val = Some(entity) } })
  result.val
}

///|
fn update_primary_cursor_options(
  world : @ecs.World,
  update : (@window.CursorOptions) -> Unit,
) -> Unit {
  guard primary_window_entity(world) is Some(entity) else { return }
  let tick = world.read_change_tick()
  let store = world.component(@window.ecs_key_cursor_options)
  let options = match store.get(entity) {
    Some(options) => options
    None => @window.CursorOptions::default()
  }
  update(options)
  if store.get(entity) is Some(_) {
    store.set(entity, options, tick) |> ignore
  } else {
    store.insert(entity, options, tick)
  }
}

///|
fn grab_mouse(
  mouse : @input.ButtonInput[@window.MouseButton],
  key : @input.ButtonInput[@window.KeyCode],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  if mouse.just_pressed(Left) {
    update_primary_cursor_options(world, fn(cursor_options) {
      cursor_options.visible = false
      cursor_options.grab_mode = GrabLocked
    })
  }
  if key.just_pressed(Escape) {
    update_primary_cursor_options(world, fn(cursor_options) {
      cursor_options.visible = true
      cursor_options.grab_mode = GrabNone
    })
  }
}
