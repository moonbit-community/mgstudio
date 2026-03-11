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
  try! world.set_component(primary_window, Window::default())
  try! world.set_component(primary_window, PrimaryWindow::{  })

  let first_request = world.spawn()
  try! world.set_component(first_request, Screenshot::primary_window())

  let duplicate_request = world.spawn()
  try! world.set_component(
    duplicate_request,
    Screenshot::window(primary_window),
  )

  screenshot_queue_capture_requests(world)

  inspect(world.is_alive(first_request), content="true")
  inspect(world.is_alive(duplicate_request), content="false")
}
