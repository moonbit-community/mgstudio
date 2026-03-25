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
  try! world
  .query_entities_filtered(
    (
      @ecs.With::new(@window.ecs_key_window),
      @ecs.With::new(@window.ecs_key_primary_window),
    ),
  )
  .view(fn(_query_entity, entity) {
    if result.val is None {
      result.val = Some(entity)
    }
  })
  result.val
}

///|
fn update_primary_cursor_options(
  world : @ecs.World,
  update : (@window.CursorOptions) -> Unit,
) -> Unit {
  guard primary_window_entity(world) is Some(entity) else { return }
  let options = match
    (try! world.get_by_key(entity, @window.ecs_key_cursor_options)) {
    Some(options) => options
    None => @window.CursorOptions::default()
  }
  update(options)
  if (try! world.get_by_key(entity, @window.ecs_key_cursor_options)) is Some(_) {
    try! (world.replace(entity, @window.ecs_key_cursor_options, options)
    |> ignore)
  } else {
    try! world.set_by_key(entity, @window.ecs_key_cursor_options, options)
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
