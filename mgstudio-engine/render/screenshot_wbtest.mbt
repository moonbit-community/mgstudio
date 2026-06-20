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
}

///|
test "screenshot: pending capture state self-initializes as world resource" {
  let world = @ecs.World::new()
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
