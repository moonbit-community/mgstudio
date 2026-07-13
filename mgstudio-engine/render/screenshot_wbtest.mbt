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
test "screenshot: duplicate screenshot targets are despawned during extraction" {
  let world = @ecs.World::new()
  defer world.close()
  let primary_window = world.spawn()
  try! (world
  .entity_mut(primary_window)
  .insert_component(@window.Window::Window())
  |> ignore)
  try! (world
  .entity_mut(primary_window)
  .insert_component(@window.PrimaryWindow::{  })
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

  extract_screenshots(world)

  debug_inspect(world.is_alive(first_request), content="true")
  debug_inspect(world.is_alive(duplicate_request), content="false")
  debug_inspect(
    try! world.entity(first_request).contains(key=ecs_key_capturing),
    content="true",
  )
  let targets = world
    .resource(render_screenshot_targets_resource_key)
    .get()
    .unwrap()
  debug_inspect(targets.targets.length(), content="1")
}

///|
test "screenshot: non-primary window screenshot target still deduplicates" {
  let world = @ecs.World::new()
  defer world.close()
  let secondary_window = world.spawn()
  try! (world
  .entity_mut(secondary_window)
  .insert_component(@window.Window::Window())
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

  extract_screenshots(world)

  debug_inspect(world.is_alive(first_request), content="true")
  debug_inspect(world.is_alive(duplicate_request), content="false")
}

///|
test "screenshot: duplicate texture-view targets are despawned during extraction" {
  let world = @ecs.World::new()
  defer world.close()

  let first_request = world.spawn()
  try! (world
  .entity_mut(first_request)
  .insert_component(Screenshot::texture_view(ManualTextureViewHandle::new(42)))
  |> ignore)

  let duplicate_request = world.spawn()
  try! (world
  .entity_mut(duplicate_request)
  .insert_component(Screenshot::texture_view(ManualTextureViewHandle::new(42)))
  |> ignore)

  extract_screenshots(world)

  debug_inspect(world.is_alive(first_request), content="true")
  debug_inspect(world.is_alive(duplicate_request), content="false")
}

///|
test "screenshot: RenderPlugin initializes pending capture state resource" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    RenderPlugin::RenderPlugin(),
  )
  debug_inspect(
    app
    .world()
    .resource(pending_screenshot_entity_captures_resource_key)
    .is_present(),
    content="true",
  )
  debug_inspect(
    app.world().resource(captured_screenshots_resource_key).is_present(),
    content="true",
  )
  debug_inspect(
    app.world().resource(render_screenshot_targets_resource_key).is_present(),
    content="true",
  )
  let render_app = app.get_sub_app(@app.RenderApp).unwrap()
  debug_inspect(
    render_app
    .world()
    .resource(render_screenshot_targets_resource_key)
    .is_present(),
    content="true",
  )
  let targets = render_app
    .world()
    .resource(render_screenshot_targets_resource_key)
    .get()
    .unwrap()
  debug_inspect(targets.targets.length(), content="0")
  debug_inspect(
    render_app
    .world()
    .resource(render_screenshots_prepared_resource_key)
    .is_present(),
    content="true",
  )
  let prepared = render_app
    .world()
    .resource(render_screenshots_prepared_resource_key)
    .get()
    .unwrap()
  debug_inspect(prepared.prepared.length(), content="0")
}

///|
test "screenshot: ScreenshotPlugin tolerates missing RenderApp" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    ScreenshotPlugin::ScreenshotPlugin(),
  )
  debug_inspect(
    app.world().resource(captured_screenshots_resource_key).is_present(),
    content="true",
  )
  debug_inspect(app.get_sub_app(@app.RenderApp) is None, content="true")
}

///|
test "screenshot: pending capture state self-initializes as world resource" {
  let world = @ecs.World::new()
  defer world.close()
  debug_inspect(
    world.resource(pending_screenshot_entity_captures_resource_key).is_present(),
    content="false",
  )
  screenshot_collect_capture_requests(world)
  debug_inspect(
    world.resource(pending_screenshot_entity_captures_resource_key).is_present(),
    content="true",
  )
}

///|
test "screenshot: trigger_screenshots drains captured resource and triggers entity event" {
  let world = @ecs.World::new()
  defer world.close()
  let screenshot_entity = world.spawn()
  let observed : Array[String] = []
  ignore(
    world.add_entity_observer(screenshot_entity, fn(
      event : @ecs.On[ScreenshotCaptured],
    ) {
      let capture = event.event()
      observed.push(
        "\{capture.entity.id.to_string()}:\{capture.image.width.to_string()}x\{capture.image.height.to_string()}",
      )
    }),
  )
  world.insert_resource(captured_screenshots_resource_key, CapturedScreenshots::{
    captures: [
      CapturedScreenshot::{
        entity: screenshot_entity,
        image: @asset.Image::new(4, 5, Bytes::from_array([])),
      },
    ],
  })
  trigger_screenshots(world)
  debug_inspect(observed, content="[\"0:4x5\"]")
  debug_inspect(
    try! world.entity(screenshot_entity).contains(key=ecs_key_captured),
    content="true",
  )
  let captured = world
    .resource(captured_screenshots_resource_key)
    .get()
    .unwrap()
  debug_inspect(captured.captures.length(), content="0")
}
