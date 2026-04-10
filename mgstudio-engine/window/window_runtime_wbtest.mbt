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
test "window runtime: create requests logical size from resolution scale factor" {
  let resolution = WindowResolution::default()
  resolution.set_physical_resolution(800, 600)
  resolution.set_scale_factor(2.0F)

  debug_inspect(window_requested_logical_width(resolution), content="400")
  debug_inspect(window_requested_logical_height(resolution), content="300")
}

///|
test "window runtime: create forces physical request only when override exists" {
  let resolution = WindowResolution::default()
  debug_inspect(
    window_uses_physical_request_on_create(resolution),
    content="false",
  )

  resolution.set_scale_factor_override(Some(1.0F))
  debug_inspect(
    window_uses_physical_request_on_create(resolution),
    content="true",
  )
  debug_inspect(window_requested_logical_width(resolution), content="1280")
  debug_inspect(window_requested_logical_height(resolution), content="720")
}

///|
fn window_runtime_wbtest_prepare_native_event_loop() -> Unit {
  // Whitebox tests are not guaranteed to run on the main thread.
  @windowing.set_event_loop_any_thread(true)
}

///|
test "window runtime: create pass is separated from prepare pass" {
  window_runtime_wbtest_prepare_native_event_loop()
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.entity_mut(entity).insert_component(Window::default()) |> ignore)

  window_backend_prepare_system(world)
  debug_inspect(window_host_entries(world).length(), content="0")

  window_backend_create_windows_system(world)
  debug_inspect(window_host_entries(world).length(), content="1")

  try! world.despawn(entity)
  debug_inspect(window_host_entries(world).length(), content="0")
}

///|
test "window runtime: minimize request is consumed during apply" {
  window_runtime_wbtest_prepare_native_event_loop()
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.entity_mut(entity).insert_component(Window::default()) |> ignore)

  window_backend_create_windows_system(world)
  ignore(
    window_update_component(world, entity, fn(current) {
      let next : Window = current
      next.set_minimized(true)
      next
    }),
  )
  window_backend_apply_changed_windows_system(world)

  let stored_window = match (try! world.entity(entity).get() : Window?) {
    Some(window) => window
    None => abort("missing window component")
  }
  debug_inspect(stored_window.maximize_request, content="None")
  debug_inspect(stored_window.minimize_request, content="None")

  try! world.despawn(entity)
}

///|
test "window runtime: unsupported transparent and canvas updates are reverted" {
  window_runtime_wbtest_prepare_native_event_loop()
  let world = @ecs.World::new()
  let entity = world.spawn()
  let initial_window = Window::default()
  initial_window.canvas = Some("#existing")
  try! (world.entity_mut(entity).insert_component(initial_window) |> ignore)

  window_backend_create_windows_system(world)
  ignore(
    window_update_component(world, entity, fn(current) {
      let next : Window = current
      next.transparent = true
      next.canvas = Some("#new")
      next
    }),
  )
  window_backend_apply_changed_windows_system(world)

  let stored_window = match (try! world.entity(entity).get() : Window?) {
    Some(window) => window
    None => abort("missing window component")
  }
  debug_inspect(stored_window.transparent, content="false")
  debug_inspect(stored_window.canvas, content="Some(\"#existing\")")

  try! world.despawn(entity)
}

///|
test "window runtime: unsupported create-only name taskbar and clip updates are reverted" {
  window_runtime_wbtest_prepare_native_event_loop()
  let world = @ecs.World::new()
  let entity = world.spawn()
  let initial_window = Window::default()
  initial_window.name = Some("main-window")
  initial_window.skip_taskbar = true
  initial_window.clip_children = false
  try! (world.entity_mut(entity).insert_component(initial_window) |> ignore)

  window_backend_create_windows_system(world)
  ignore(
    window_update_component(world, entity, fn(current) {
      let next : Window = current
      next.name = Some("changed-window")
      next.skip_taskbar = false
      next.clip_children = true
      next
    }),
  )
  window_backend_apply_changed_windows_system(world)

  let stored_window = match (try! world.entity(entity).get() : Window?) {
    Some(window) => window
    None => abort("missing window component")
  }
  debug_inspect(stored_window.name, content="Some(\"main-window\")")
  debug_inspect(stored_window.skip_taskbar, content="true")
  debug_inspect(stored_window.clip_children, content="false")

  try! world.despawn(entity)
}

///|
test "window runtime: iOS preference fields remain mutable at runtime" {
  window_runtime_wbtest_prepare_native_event_loop()
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.entity_mut(entity).insert_component(Window::default()) |> ignore)

  window_backend_create_windows_system(world)
  ignore(
    window_update_component(world, entity, fn(current) {
      let next : Window = current
      next.prefers_home_indicator_hidden = true
      next.prefers_status_bar_hidden = true
      next.preferred_screen_edges_deferring_system_gestures = ScreenEdge::All
      next
    }),
  )
  window_backend_apply_changed_windows_system(world)

  let stored_window = match (try! world.entity(entity).get() : Window?) {
    Some(window) => window
    None => abort("missing window component")
  }
  debug_inspect(stored_window.prefers_home_indicator_hidden, content="true")
  debug_inspect(stored_window.prefers_status_bar_hidden, content="true")
  debug_inspect(
    stored_window.preferred_screen_edges_deferring_system_gestures,
    content="All",
  )

  try! world.despawn(entity)
}
