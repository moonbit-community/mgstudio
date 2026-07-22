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
test "screenshot: RenderPlugin owns main-world screenshot systems" {
  let lifecycle_world_15_0 = @ecs.World::new()
  defer lifecycle_world_15_0.close()
  let app = @app.App::new(lifecycle_world_15_0).add_plugins(
    RenderPlugin::RenderPlugin(),
  )
  let update_dot = app.schedule_graph_dot(Update)
  debug_inspect(
    update_dot.contains("\"mgstudio_render::extract_screenshots\""),
    content="true",
  )
  debug_inspect(
    update_dot.contains(
      "\"mgstudio_render::screenshot_queue_capture_requests\"",
    ),
    content="true",
  )
  debug_inspect(
    update_dot.contains(
      "\"mgstudio_render::screenshot_collect_capture_requests\"",
    ),
    content="true",
  )
  debug_inspect(
    update_dot.contains("\"mgstudio_render::trigger_screenshots\""),
    content="true",
  )
  debug_inspect(
    update_dot.contains("\"mgstudio_render::screenshot_clear_system\""),
    content="false",
  )
  let first_dot = app.schedule_graph_dot(First)
  debug_inspect(
    first_dot.contains("\"mgstudio_render::screenshot_clear_system\""),
    content="true",
  )
}

///|
test "screenshot: ScreenshotPlugin owns screenshot systems" {
  let lifecycle_world_52_0 = @ecs.World::new()
  defer lifecycle_world_52_0.close()
  let app = @app.App::new(lifecycle_world_52_0).add_plugins(
    ScreenshotPlugin::ScreenshotPlugin(),
  )
  let update_dot = app.schedule_graph_dot(Update)
  debug_inspect(
    update_dot.contains("\"mgstudio_render::extract_screenshots\""),
    content="true",
  )
  debug_inspect(
    update_dot.contains(
      "\"mgstudio_render::screenshot_queue_capture_requests\"",
    ),
    content="true",
  )
  debug_inspect(
    update_dot.contains(
      "\"mgstudio_render::screenshot_collect_capture_requests\"",
    ),
    content="true",
  )
  debug_inspect(
    update_dot.contains("\"mgstudio_render::trigger_screenshots\""),
    content="true",
  )
  debug_inspect(
    update_dot.contains("\"mgstudio_render::screenshot_clear_system\""),
    content="false",
  )
  let first_dot = app.schedule_graph_dot(First)
  debug_inspect(
    first_dot.contains("\"mgstudio_render::screenshot_clear_system\""),
    content="true",
  )
}

///|
test "screenshot: ScreenshotCaptured is an entity trigger event" {
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
  world.trigger(ScreenshotCaptured::{
    entity: screenshot_entity,
    image: @asset.Image::new(2, 3, Bytes::from_array([])),
  })
  debug_inspect(observed, content="[\"0:2x3\"]")
}
