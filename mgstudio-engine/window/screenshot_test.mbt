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
test "window: duplicate screenshot targets are despawned during queueing" {
  let world = @ecs.World::new()
  let primary_window = world.spawn()
  try! (world.entity_mut(primary_window).insert_component(Window::default())
  |> ignore)
  try! (world.entity_mut(primary_window).insert_component(PrimaryWindow::{  })
  |> ignore)

  let first_request = world.spawn()
  try! (world
  .entity_mut(first_request)
  .insert_component(Screenshot::primary_window())
  |> ignore)

  let duplicate_request = world.spawn()
  try! (world
  .entity_mut(duplicate_request)
  .insert_component(Screenshot::window(primary_window))
  |> ignore)

  screenshot_queue_capture_requests(world)

  debug_inspect(world.is_alive(first_request), content="true")
  debug_inspect(world.is_alive(duplicate_request), content="false")
}

///|
test "window: non-primary window screenshot target still deduplicates" {
  let world = @ecs.World::new()
  let secondary_window = world.spawn()
  try! (world.entity_mut(secondary_window).insert_component(Window::default())
  |> ignore)

  let first_request = world.spawn()
  try! (world
  .entity_mut(first_request)
  .insert_component(Screenshot::window(secondary_window))
  |> ignore)

  let duplicate_request = world.spawn()
  try! (world
  .entity_mut(duplicate_request)
  .insert_component(Screenshot::window(secondary_window))
  |> ignore)

  screenshot_queue_capture_requests(world)

  debug_inspect(world.is_alive(first_request), content="true")
  debug_inspect(world.is_alive(duplicate_request), content="false")
}

///|
test "window: duplicate texture-view screenshot targets are despawned during queueing" {
  let world = @ecs.World::new()

  let first_request = world.spawn()
  try! (world
  .entity_mut(first_request)
  .insert_component(Screenshot::texture_view(42))
  |> ignore)

  let duplicate_request = world.spawn()
  try! (world
  .entity_mut(duplicate_request)
  .insert_component(Screenshot::texture_view(42))
  |> ignore)

  screenshot_queue_capture_requests(world)

  debug_inspect(world.is_alive(first_request), content="true")
  debug_inspect(world.is_alive(duplicate_request), content="false")
}
