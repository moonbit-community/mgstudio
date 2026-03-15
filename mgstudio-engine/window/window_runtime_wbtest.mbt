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

  inspect(window_requested_logical_width(resolution), content="400")
  inspect(window_requested_logical_height(resolution), content="300")
}

///|
test "window runtime: create forces physical request only when override exists" {
  let resolution = WindowResolution::default()
  inspect(window_uses_physical_request_on_create(resolution), content="false")

  resolution.set_scale_factor_override(Some(1.0F))
  inspect(window_uses_physical_request_on_create(resolution), content="true")
  inspect(window_requested_logical_width(resolution), content="1280")
  inspect(window_requested_logical_height(resolution), content="720")
}

///|
test "window runtime: create pass is separated from prepare pass" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! world.set_component(entity, Window::default())

  window_backend_prepare_system(world)
  inspect(window_host_entries(world).length(), content="0")

  window_backend_create_windows_system(world)
  inspect(window_host_entries(world).length(), content="1")

  try! world.despawn(entity)
  inspect(window_host_entries(world).length(), content="0")
}
